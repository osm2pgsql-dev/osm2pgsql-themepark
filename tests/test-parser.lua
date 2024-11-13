-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- tests/test-parser.lua
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

local parser = require 'themepark/parser'

-- ---------------------------------------------------------------------------

describe("test basic parser functions", function()

    local PARSE = function(input)
        return parser.parse(input)
    end

    local RUN = function(input)
        return parser.parse(input)({})
    end

    it("parses boolean values and operators", function()
        assert.is_true(RUN([[ true ]]))
        assert.is_false(RUN([[ false ]]))

        assert.is_true(RUN([[ not false ]]))
        assert.is_false(RUN([[ not true ]]))

        assert.is_true(RUN([[ true or false ]]))
        assert.is_true(RUN([[ false or true ]]))
        assert.is_true(RUN([[ true or true ]]))
        assert.is_false(RUN([[ false or false ]]))
        assert.is_true(RUN([[ true and true ]]))
        assert.is_false(RUN([[ true and false ]]))
        assert.is_false(RUN([[ false and true ]]))
        assert.is_false(RUN([[ false and false ]]))

        assert.is_true(RUN([[ true or not true ]]))
        assert.is_false(RUN([[ true and not true ]]))
    end)

    it("parses combinations of boolean operators", function()
        assert.is_true(RUN([[ true and true and true ]]))
        assert.is_true(RUN([[ false or true or true ]]))
        assert.is_true(RUN([[ (false and true) or true ]]))
        assert.is_false(RUN([[ false and (true or true) ]]))
        assert.is_true(RUN([[ false and true or true ]]))
    end)

    it("works with strings", function()
        assert.is_true(RUN([[ 'abc' = 'abc' ]]))
        assert.is_false(RUN([[ 'abc' = 'xyz' ]]))
        assert.is_false(RUN([[ 'abc' != 'abc' ]]))
        assert.is_true(RUN([[ 'abc' != 'xyz' ]]))
        assert.is_true(RUN([[ 'abc' ]]))
        assert.is_true(RUN([[ '' ]]))
        assert.is_false(RUN([[ not 'abc' ]]))
        assert.is_true(RUN([[ ('abc' = 'abc') ]]))
    end)

    it("can compare strings to arrays with 'in'", function()
        assert.is_true(RUN([[ 'abc' in ('abc') ]]))
        assert.is_true(RUN([[ 'abc' in ('xyz', 'abc', 'def') ]]))
        assert.is_true(RUN([[ 'abc' in ('xyz', 'abc', 'def', ) ]]))
        assert.is_false(RUN([[ 'abc' in ('xyz', 'def') ]]))
        assert.is_false(RUN([[ 'abc' in ('xyz', 'def', ) ]]))
        assert.is_false(RUN([[ 'abc' in () ]]))
        assert.is_true(RUN([[ 'abc' not in ('xyz') ]]))
        assert.is_false(RUN([[ 'abc' not in ('abc', 'def') ]]))
    end)

    it("errors out when something is wrong", function()
        assert.error(function() PARSE([[]]) end)
        assert.error(function() PARSE([[ foo ]]) end)
        assert.error(function() PARSE([[ not not ]]) end)
        assert.error(function() PARSE([[ 'foo' 'bar' ]]) end)
        assert.error(function() PARSE([[ and or ]]) end)
        assert.error(function() PARSE([[ not 'foo' or not ]]) end)
        assert.error(function() PARSE([[ 'foo' not ]]) end)
        assert.error(function() PARSE([[ 'foo' not in ]]) end)
        assert.error(function() PARSE([[ 'foo' not in 'bar' ]]) end)
        assert.error(function() PARSE([[ 'foo' not 'bar' ]]) end)
        assert.error(function() PARSE([[ 'foo' in 'bar' ]]) end)
        assert.error(function() PARSE([[ true and ]]) end)
        assert.error(function() PARSE([[ true or ]]) end)
        assert.error(function() PARSE([[ 'x' in ]]) end)
        assert.error(function() PARSE([[ 'x' = ]]) end)
        assert.error(function() PARSE([[ 'x' != ]]) end)
        assert.error(function() PARSE([[ ( ]]) end)
        assert.error(function() PARSE([[ ( true ]]) end)
        assert.error(function() PARSE([[ ( , ]]) end)
        assert.error(function() PARSE([[ 'x' in ( 'a',, ) ]]) end)
        assert.error(function() PARSE([[ 'x' in ( ,'a' ) ]]) end)
        assert.error(function() PARSE([[ 'x' in ( 'a' 'b' ) ]]) end)
    end)

end)

describe("test parser functions with tags", function()

    local test_tags = { amenity = 'restaurant', name = 'foo', wheelchair = 'yes' }

    local RUN = function(input)
        return parser.parse(input)(test_tags)
    end

    it("gets the tag value from the key", function()
        assert.is_true(RUN([[ "amenity" = 'restaurant' ]]))
        assert.is_true(RUN([[ "name" != 'bar' ]]))
        assert.is_true(RUN([[ "wheelchair" ]]))
        assert.is_false(RUN([[ "landuse" ]]))
    end)

end)

-- ---------------------------------------------------------------------------
