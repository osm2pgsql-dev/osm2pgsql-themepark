-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- tests/test-lexer.lua
--
-- ---------------------------------------------------------------------------
--
-- Copyright 2024 Jochen Topf <jochen@topf.org>
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

require 'busted.runner'()

local lexer = require 'themepark/lexer'

describe("test lexer", function()

    local function LEX(input)
        return lexer.run(input)
    end

    local function SYM(stype, sidx, eidx, value)
        return lexer.symbol(stype, sidx, eidx, value)
    end

    it("recognizes operator tokens", function()
        assert.is_same({ SYM('=',   1, 2) }, LEX([[=]]))
        assert.is_same({ SYM('!=',  1, 3) }, LEX([[!=]]))
        assert.is_same({ SYM('and', 1, 4) }, LEX([[and]]))
        assert.is_same({ SYM('or',  1, 3) }, LEX([[or]]))
        assert.is_same({ SYM('not', 1, 4) }, LEX([[not]]))
        assert.is_same({ SYM('in',  1, 3) }, LEX([[in]]))
    end)

    it("recognizes boolean tokens", function()
        assert.is_same({ SYM('true',  1, 5) }, LEX([[true]]))
        assert.is_same({ SYM('false', 1, 6) }, LEX([[false]]))
    end)

    it("recognizes string tokens", function()
        assert.is_same({ SYM('key', 1, 10, 'amenity') }, LEX([["amenity"]]))
        assert.is_same({ SYM('str', 1,  7, 'test') }, LEX([['test']]))
    end)

    it("recognizes arrays", function()
        assert.is_same({ SYM('(', 2, 3),
                         SYM('str', 3, 6, 'a'),
                         SYM(',', 6, 7),
                         SYM('true', 8, 12),
                         SYM(',', 12, 13),
                         SYM('key', 13, 16, 'c'),
                         SYM(')', 19, 20) }, LEX([[ ('a', true,"c"   )  ]]))
    end)

    it("works for empty inputs", function()
        assert.is_same({}, LEX([[]]))
        assert.is_same({}, LEX([[ ]]))
        assert.is_same({}, LEX([[    ]]))
    end)

    it("recognizes multiple tokens and ignores whitespace", function()
        assert.is_same({ SYM('str', 1,  7, 'test'), }, LEX([['test' ]]))
        assert.is_same({ SYM('str', 2,  8, 'test'), }, LEX([[ 'test']]))
        assert.is_same({ SYM('=',   2,  3),
                         SYM('!=', 3, 5) }, LEX([[ =!= ]]))
        assert.is_same({ SYM('(',   1,  2),
                         SYM('str', 3,  9, 'test'),
                         SYM(')',  10, 11) }, LEX([[( 'test' )]]))
    end)

    it("fails on unrecognized inputs", function()
        assert.has_error(function() LEX([[X]]) end)
        assert.has_error(function() LEX([[= Y]]) end)
    end)

end)

-- ---------------------------------------------------------------------------
