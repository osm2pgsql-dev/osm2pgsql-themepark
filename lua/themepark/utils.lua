-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/utils.lua
--
-- ---------------------------------------------------------------------------
--
-- Copyright 2023 Jochen Topf <jochen@topf.org>
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

local utils = {}

function utils.write_to_file(filename, content)
    local file, msg = io.open(filename, 'w')
    if not file then
        error("Could open '" .. filename .. "': " .. msg, 2)
    end
    file:write(content)
    file:close()
end

function utils.build_select_query(columns, from, conditions, order_by, order_dir)
    local sql = 'SELECT ' .. table.concat(columns, ',')
                .. ' FROM "' .. from .. '"'

    if conditions and #conditions > 0 then
        sql = sql .. ' WHERE ' .. table.concat(conditions, ' AND ')
    end

    if order_by then
        sql = sql .. ' ORDER BY "' .. order_by .. '"'
        if order_dir then
            sql = sql .. ' ' .. order_dir
        end
    end

    return sql
end

function utils.find_name_in_array(array, name)
    for _, element in ipairs(array) do
        if element.name == name then
            return element
        end
    end
    return nil
end

return utils

-- ---------------------------------------------------------------------------
