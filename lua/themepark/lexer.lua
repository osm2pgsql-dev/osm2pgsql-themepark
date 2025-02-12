-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/lexer.lua
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

local Symbol = {

    new = function(self, stype, sidx, eidx, value)
        local new_object = { type = stype, value = value, start_index = sidx, end_index = eidx }
        setmetatable(new_object, self)
        self.__index = self
        return new_object
    end,

    __tostring = function(self)
        local out = self.type
        if self.value then
            out = out .. '[' .. tostring(self.value) .. ']'
        end
        return out .. '(' .. self.start_index .. '-' .. self.end_index .. ')'
    end,

    __eq = function(self, other)
        return self.type == other.type and
               self.start_index == other.start_index and
               self.end_index == other.end_index and
               self.value == other.value
    end,

}

local gen_matcher = function(pattern, extra_length, stype)
    return function(self, input)
        local m, rest = input:match(pattern)
        if m then
            local next_index = self.index + #m + (extra_length or 0)
            local symbol
            if stype then
                symbol = Symbol:new(stype, self.index + 1, next_index + 1, m)
            else
                symbol = Symbol:new(m, self.index + 1, next_index + 1)
            end
            self.index = next_index
            return symbol, rest
        end
    end
end

local Lexer = {
    matchers = {},

    Symbol = Symbol,

    new = function(self)
        local new_object = { index = 0 }
        setmetatable(new_object, self)
        self.__index = self
        return new_object
    end,

    add_matcher = function(self, pattern, extra_length, stype)
        self.matchers[#self.matchers + 1] = gen_matcher(pattern, extra_length, stype)
    end,

    remove_whitespace = function(self, input)
        local output = input:gsub('^ +', '')
        self.index = self.index + (#input - #output)
        return output
    end,

    next = function(self, input)
        for _, mfunc in ipairs(self.matchers) do
            local token, rest = mfunc(self, input)
            if token then
                return token, rest
            end
        end
    end,

    run = function(self, input)
        local original_input = input
        local tokens = {}

        while #input > 0 do
            input = self:remove_whitespace(input)
            if #input == 0 then
                break
            end

            local token, rest = self:next(input)
            if token then
                tokens[#tokens + 1] = token
                input = rest
            else
                error("error parsing OSM filter expression:\n"
                      .. original_input
                      .. "\n"
                      .. string.rep(' ', self.index)
                      .. '^', 0)
            end
        end

        return tokens
    end,

}

Lexer:add_matcher( [[^"([^"]*)"(.*)$]], 2, 'key')
Lexer:add_matcher( [[^'([^']*)'(.*)$]], 2, 'str')
Lexer:add_matcher( [[^(!?=)(.*)$]]   )
Lexer:add_matcher( [[^(and)(.*)$]]   )
Lexer:add_matcher( [[^(or)(.*)$]]    )
Lexer:add_matcher( [[^(not)(.*)$]]   )
Lexer:add_matcher( [[^(in)(.*)$]]    )
Lexer:add_matcher( [[^([()])(.*)$]]  )
Lexer:add_matcher( [[^(,)(.*)$]]     )
Lexer:add_matcher( [[^(true)(.*)$]]  )
Lexer:add_matcher( [[^(false)(.*)$]] )

-- ---------------------------------------------------------------------------

return {
    run = function(input)
        return Lexer:new():run(input)
    end,

    symbol = function(stype, sidx, eidx, value)
        return Symbol:new(stype, sidx, eidx, value)
    end,
}

-- ---------------------------------------------------------------------------
