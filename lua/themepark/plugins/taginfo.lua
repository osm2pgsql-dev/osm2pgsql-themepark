-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/plugins/taginfo.lua
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

local plugin = {}

local utils = require 'themepark/utils'
local json = require 'json'

local function convert_on_to_types(on)
    if not on then
        return {'node', 'way', 'relation'}
    end

    local has = {
        node = false,
        way = false,
        relation = false
    }

    for i = 1, #on do
        local c = on:sub(i, i)
        if c == 'n' then
            has.node = true
        elseif c == 'w' then
            has.way = true
        elseif c == 'r' then
            has.relation = true
        elseif c == 'a' then
            has.way = true
            has.relation = true
        end
    end

    local out = {}

    for _, ot in ipairs({'node', 'way', 'relation'}) do
        if has[ot] then
            table.insert(out, ot)
        end
    end

    return out
end

function plugin:append_layer_config(layer, tags)
    if layer.tags then
        for _, entry in ipairs(layer.tags) do
            entry.object_types = convert_on_to_types(entry.on)
            entry.on = nil

            if entry.values then
                local values = entry.values
                entry.values = nil
                for _, value in ipairs(values) do
                    table.insert(tags, {
                        key = entry.key,
                        value = value,
                        object_types = entry.object_types
                    })
                end
            else
                table.insert(tags, entry)
            end
        end
    end
end

local comp_all = function(a, b)
    return json.encode(a) < json.encode(b)
end

local comp_key_value = function(a, b)
    if a.key == b.key then
        return (a.value or '') < (b.value or '')
    end
    return a.key < b.key
end

function plugin:write_config(filename, options)
    if not options then
        options = {}
    end

    local config = {
        data_format = 1,
        project = options.project
    }

    local tags = {}
    for _, layer in ipairs(plugin.themepark.layers) do
        self:append_layer_config(layer, tags)
    end

    table.sort(tags, comp_all)

    config.tags = {}
    local last
    for _, element in ipairs(tags) do
        local jelement = json.encode(element)
        if jelement ~= last then
            table.insert(config.tags, element)
            last = jelement
        end
    end

    table.sort(config.tags, comp_key_value)

    utils.write_to_file(filename .. '.json', json.encode(config))
end

return plugin

-- ---------------------------------------------------------------------------
