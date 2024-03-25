-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/plugins/bbox.lua
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

local plugin = {}

local min_max_zoom_columns = function(columns)
    local column_names = {}
    local minzoom
    local maxzoom

    for _, column in ipairs(columns) do
        if column.tiles == 'minzoom' then
            minzoom = column.column
        elseif column.tiles == 'maxzoom' then
            maxzoom = column.column
        elseif column.tiles ~= false and column.column ~= 'all_tags' then
            table.insert(column_names, '"' .. column.column .. '"')
        end
    end

    return minzoom, maxzoom, column_names
end

local function assemble_conditions(minzoom, maxzoom, xycondition)
    local conditions = {}

    if minzoom then
        table.insert(conditions, '!zoom! >= "' .. minzoom .. '"')
    end
    if maxzoom then
        table.insert(conditions, '!zoom! <= "' .. maxzoom .. '"')
    end

    if xycondition then
        table.insert(conditions, '!x! = x AND !y! = y')
    end

    return conditions
end

local function build_layer_config(info)
    local schema_prefix = ""
    if plugin.themepark.options.schema then
        schema_prefix = plugin.themepark.options.schema .. "."
    end
    local data = {
        name = info.name,
        geometry_field = info.geom_column,
        geometry_type = string.upper(info.geom_type),
        srid = plugin.themepark.options.srid,
        -- simplify = true,
        buffer_size = 10,
    }

    local tiles = info.tiles or {}
    if tiles.group then
        return
    end

    if tiles.simplify ~= nil then
        data.simplify = tiles.simplify
    end

    if tiles.make_valid ~= nil then
        data.make_valid = tiles.make_valid
    end

    if tiles.buffer_size ~= nil then
        data.buffer_size = tiles.buffer_size
    end

    if not plugin.themepark.layer_groups[info.name] then
        if tiles.minzoom then
            data.minzoom = tiles.minzoom
        end
        if tiles.maxzoom then
            data.maxzoom = tiles.maxzoom
        end
    end

    if tiles.sql then
        data.query = {{
            sql = info.sql
        }}
    else
        local minzoom, maxzoom, columns = min_max_zoom_columns(info.columns)
        local from = schema_prefix .. info.name
        if plugin.themepark.layer_groups[info.name] then
            local conditions = assemble_conditions(minzoom, maxzoom, tiles.xycondition)
            local sql = utils.build_select_query(columns, from, conditions, tiles.order_by, tiles.order_dir)

            data.query = {{
                sql = sql,
            }}
            if tiles.minzoom then
                data.query[1].minzoom = tiles.minzoom
            end
            if tiles.maxzoom then
                data.query[1].maxzoom = tiles.maxzoom
            end
        else
            local conditions = assemble_conditions(minzoom, maxzoom, tiles.xycondition)
            local sql = utils.build_select_query(columns, from, conditions, tiles.order_by, tiles.order_dir)
            data.query = {{
                sql = sql,
            }}
        end

        if plugin.themepark.layer_groups[info.name] then
            for _, group_table in ipairs(plugin.themepark.layer_groups[info.name]) do
                local sublayer = utils.find_name_in_array(plugin.themepark.layers, group_table.name)
                minzoom, maxzoom, columns = min_max_zoom_columns(sublayer.columns)

                local conditions = assemble_conditions(minzoom, maxzoom, sublayer.tiles.xycondition)
                local from = schema_prefix .. group_table.name
                local sql = utils.build_select_query(columns, from,
                                                     conditions, sublayer.tiles.order_by,
                                                     sublayer.tiles.order_dir)
                table.insert(data.query, {
                    sql = sql,
                    minzoom = group_table.minzoom,
                    maxzoom = group_table.maxzoom,
                })
            end
        end
    end

    return data
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
local function build_tileset_config(extra_layers)
    local layers = {}

    for _, layer in ipairs(plugin.themepark.layers) do
        if layer.tiles ~= false then
            local layer_config = build_layer_config(layer)
            if layer_config then
                table.insert(layers, layer_config)
            end
        end
    end
    for _, data in ipairs(extra_layers) do
        if not data.geometry_field then
            data.geometry_field = 'geom'
        end
        if not data.srid then
            data.srid = plugin.themepark.options.srid
        end
        table.insert(layers, data)
    end
    return layers
end

function ordered_keys(o)
    local keys1 = {}
    local keys2 = {}
    for k, v in pairs(o) do
        if type(v) == 'table' then
            table.insert(keys2, k)
        else
            table.insert(keys1, k)
        end
    end
    table.sort(keys1)
    table.sort(keys2)
    for _,v in ipairs(keys2) do 
        table.insert(keys1, v)
    end
    return keys1
end

function dump_toml(o, indent_size, parents)
    indent_size = indent_size or 2
    parents = parents or {}
    if type(o) == 'table' then
        local s = ''
        local indent = string.rep(" ", #parents * indent_size)
        -- sort keys for stable output order
        for _, k in ipairs(ordered_keys(o)) do
            local v = o[k]
            if type(v) == 'table' then
                local array_val = v[1] ~= nil
                if array_val then
                    table.insert(parents, k)
                    s = s .. dump_toml(v, indent_size, parents)
                    table.remove(parents)
                elseif type(k) == 'number' then
                    local tag = table.concat(parents, ".")
                    s = s .. '\n\n' .. indent .. '[[' .. tag ..']]' .. dump_toml(v, indent_size, parents)
                else
                    table.insert(parents, k)
                    indent = string.rep(" ", #parents * indent_size)
                    local tag = table.concat(parents, ".")
                    s = s .. '\n\n' .. indent .. '[' .. tag ..']' .. dump_toml(v, indent_size, parents)
                    table.remove(parents)
                end
            else
                if type(v) == 'string' then
                    if string.find(v, '"') then
                        v = '"""'..v..'"""'
                    else
                        v = '"'..v..'"'
                    end
                end
                s = s .. '\n' .. indent .. k ..' = ' .. dump_toml(v, indent_size, parents)
            end
        end
        return s
    else
        return tostring(o)
    end
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function plugin:write_config(filename, options)
    if not options then
        options = {}
    end

    local config = {
        webserver = { server_addr = '0.0.0.0:8080' },
        datasource = {
            {
                name = 'db',
                postgis = {
                    url = "postgres:///db"
                }
            }
        },
        tileset = {
            {
                name = options.tileset or 'osm',
                tms = 'WebMercatorQuad',
                postgis = {
                    datasource = 'db',
                    attribution = options.attribution or plugin.themepark.options.attribution,
                    layer = build_tileset_config(options.extra_layers or {})
                }
            }
        }
    }

    if plugin.themepark.options.extent then
        config.tileset[1].postgis.extent = plugin.themepark.options.extent
    end

    utils.write_to_file(filename, dump_toml(config, 0) .. "\n")
end

return plugin

-- ---------------------------------------------------------------------------
