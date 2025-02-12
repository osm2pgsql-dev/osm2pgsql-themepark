-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- tests/test-utils.lua
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

require 'busted.runner'()

local utils = require 'themepark/utils'

describe('test build_select_query', function()

    it('creates simple selects', function()
        assert.is_equal([[SELECT first,second FROM "sometable"]],
                        utils.build_select_query({'first', 'second'}, 'sometable'))
    end)

    it('handles tables which schemas', function()
        assert.is_equal([[SELECT first,second FROM "inschema"."sometable"]],
                        utils.build_select_query({'first', 'second'}, 'inschema.sometable'))
    end)

    it('handles WHERE condition', function()
        assert.is_equal([[SELECT * FROM "sometable" WHERE a=b]],
                        utils.build_select_query({'*'}, 'sometable', {'a=b'}))

        assert.is_equal([[SELECT * FROM "sometable" WHERE a=b AND c=1]],
                        utils.build_select_query({'*'}, 'sometable', {'a=b', 'c=1'}))

        assert.is_equal([[SELECT * FROM "sometable"]],
                        utils.build_select_query({'*'}, 'sometable', {}))
    end)

    it('handles ORDER BY sorting', function()
        assert.is_equal([[SELECT a,b FROM "sometable" ORDER BY "b"]],
                        utils.build_select_query({'a', 'b'}, 'sometable', {}, 'b'))

        assert.is_equal([[SELECT a,b FROM "sometable" ORDER BY "b" DESC]],
                        utils.build_select_query({'a', 'b'}, 'sometable', {}, 'b', 'DESC'))
    end)

end)

describe('test find_name_in_array', function()

    local a = {
        { name = 'some' },
        { name = 'named' },
        { name = 'things' },
    }

    it('finds name in array', function()
        assert.is_same({ name = 'named' }, utils.find_name_in_array(a, 'named'))
    end)

    it('does not find name not in array', function()
        assert.is_nil(utils.find_name_in_array(a, 'unnamed'))
    end)

end)

-- ---------------------------------------------------------------------------
