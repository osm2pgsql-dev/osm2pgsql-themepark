-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/parser.lua
--
-- ---------------------------------------------------------------------------
--
-- Copyright 2025 Jochen Topf <jochen@topf.org>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- ---------------------------------------------------------------------------

local lexer = require 'themepark/lexer'

local Parser = {

    tokens = {},

    new = function(self)
        local new_object = {}
        setmetatable(new_object, self)
        self.__index = self
        return new_object
    end,

    peek = function(self)
        return self.tokens[1]
    end,

    get_next = function(self)
        return table.remove(self.tokens, 1)
    end,

    match_next = function(self, stype)
        local next_token = self:peek()

        if next_token and next_token.type == stype then
            self:get_next()
            return true
        end

        return false
    end,

    failed = function(self, message)
        local token = self:peek()

        if token then
            error(message .. " at\n" .. self.expression .. "\n"
                          .. string.rep(' ', token.start_index - 1)
                          .. '^', 0)
        else
            error(message .. " at end of expression", 0)
        end
    end,

    parse_primary = function(self)
        if self:match_next('true') then
            return function(tags) return true end
        end

        if self:match_next('false') then
            return function(tags) return false end
        end

        local token = self:peek()
        if self:match_next('str') then
            return function(tags) return token.value end
        end

        if self:match_next('key') then
            return function(tags) return tags[token.value] end
        end

        self:failed('invalid expression')
    end,

    parse_array = function(self)
        if not self:match_next('(') then
            self:failed('expected opening paren')
        end

        local array = {}
        for token in function() return self:peek() end do
            if token.type == ')' then
                self:get_next()
                return array
            end
            array[#array + 1] = self:parse_primary()

            local sep = self:peek()
            if not sep then
                break
            elseif sep.type == ',' then
                self:get_next()
            elseif sep.type ~= ')' then
                break
            end
        end

        self:failed('expected comma or closing paren')
    end,

    parse_condition = function(self)
        local expr = self:parse_primary()

        if self:match_next('=') then
            local next_expr = self:parse_primary()
            return function(tags) return expr(tags) == next_expr(tags) end
        end

        if self:match_next('!=') then
            local next_expr = self:parse_primary()
            return function(tags)
                local value = expr(tags)
                return value ~= nil and value ~= next_expr(tags)
            end
        end

        if self:match_next('in') then
            local next_expressions = self:parse_array()
            return function(tags)
                local value_left = expr(tags)
                for _, e in ipairs(next_expressions) do
                    if value_left == e(tags) then
                        return true
                    end
                end
                return false
            end
        end

        if self:match_next('not') then
            if self:match_next('in') then
                local next_expressions = self:parse_array()
                return function(tags)
                    local value_left = expr(tags)
                    for _, e in ipairs(next_expressions) do
                        if value_left == e(tags) then
                            return false
                        end
                    end
                    return true
                end
            else
                self:failed('expected "in" after "not"')
            end
        end

        return function(tags) return not(not(expr(tags))) end
    end,

    parse_factor = function(self)
        if self:match_next('not') then
            local next_expr = self:parse_factor()
            return function(tags) return not next_expr(tags) end
        end

        if self:match_next('(') then
            local next_expr = self:parse_expression()
            if not self:match_next(')') then
                self:failed('expected closing paren')
            end
            return function(tags) return next_expr(tags) end
        end

        local next_expr = self:parse_condition()

        return function(tags) return next_expr(tags) end
    end,

    parse_term = function(self)
        local expr = self:parse_factor()

        while self:match_next('and') do
            local this_expr = expr
            local next_expr = self:parse_factor()
            expr = function(tags) return this_expr(tags) and next_expr(tags) end
        end

        return expr
    end,

    parse_expression = function(self)
        local expr = self:parse_term()

        while self:match_next('or') do
            local this_expr = expr
            local next_expr = self:parse_term()
            expr = function(tags) return this_expr(tags) or next_expr(tags) end
        end

        return expr
    end,

    parse = function(self, expression)
        self.expression = expression
        self.tokens = lexer.run(expression)
        local expr = self:parse_expression()

        if self:peek() then
            self:failed('invalid expression')
        end

        return expr
    end,

}

return {
    parse = function(input)
        return Parser:new():parse(input)
    end
}

-- ---------------------------------------------------------------------------
