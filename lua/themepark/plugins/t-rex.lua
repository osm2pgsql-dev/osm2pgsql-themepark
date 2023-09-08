-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/plugins/t-rex.lua
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

local plugin = {}

local utils = require 'themepark/utils'
local toml = require 'toml'

local min_max_zoom_columns = function(columns)
    local column_names = {}
    local minzoom
    local maxzoom

    for _, column in ipairs(columns) do
        if column.tiles == 'minzoom' then
            minzoom = column.column
        elseif column.tiles == 'maxzoom' then
            maxzoom = column.column
        elseif column.tiles ~= false then
            table.insert(column_names, '"' .. column.column .. '"')
        end
    end

    return minzoom, maxzoom, column_names
end

local function assemble_conditions(geom_column, minzoom, maxzoom, with_bbox, zoom)
    local conditions = {}

    if with_bbox then
        conditions = { '"' .. geom_column .. '" && !bbox!' }
    end

    if zoom then
        table.insert(conditions, 'ST_Contains(!bbox!, ST_TileEnvelope(' .. zoom .. ', x, y))')
    end

    if minzoom then
        table.insert(conditions, '!zoom! >= "' .. minzoom .. '"')
    end
    if maxzoom then
        table.insert(conditions, '!zoom! <= "' .. maxzoom .. '"')
    end

    return conditions
end

local function build_layer_config(info)
    local data = {
        name = info.name,
        datasource = 'db',
        geometry_field = info.geom_column,
        geometry_type = string.upper(info.geom_type),
        srid = plugin.themepark.options.srid,
        simplify = true,
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
        if plugin.themepark.layer_groups[info.name] then
            local conditions = assemble_conditions(info.geom_column, minzoom, maxzoom, true)--, tiles.xycondition)
            local sql = utils.build_select_query(columns, info.name, conditions, tiles.order_by, tiles.order_dir)

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
            local conditions = assemble_conditions(info.geom_column, minzoom, maxzoom)
            local sql = utils.build_select_query(columns, info.name, conditions, tiles.order_by, tiles.order_dir)
            data.table_name = '(' .. sql .. ') AS "' .. info.name .. '"'
        end

        if plugin.themepark.layer_groups[info.name] then
            for _, group_table in ipairs(plugin.themepark.layer_groups[info.name]) do
                local sublayer = utils.find_name_in_array(plugin.themepark.layers, group_table.name)
                minzoom, maxzoom, columns = min_max_zoom_columns(sublayer.columns)
                local zoom_for_condition
                if sublayer.tiles.xycondition then
                    zoom_for_condition = sublayer.tiles.minzoom
                end
                local conditions = assemble_conditions(info.geom_column, minzoom, maxzoom, true, zoom_for_condition)
                local sql = utils.build_select_query(columns, group_table.name,
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
        if not data.datasource then
            data.datasource = 'db'
        end
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

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function plugin:write_config(filename, options)
    if not options then
        options = {}
    end

    local config = {
        service = { mvt = { viewer = true } },
        webserver = { bind = '127.0.0.1', port = 6767 },
        datasource = {
            [0] = {
                name = 'db',
                dbconn = '{{env.DBCONN}}'
            }
        },
        grid = { predefined = 'web_mercator' },
        tileset = {
            [0] = {
                name = options.tileset or 'osm',
                attribution = options.attribution or plugin.themepark.options.attribution,
                layer = build_tileset_config(options.extra_layers or {})
            }
        }
    }

    if plugin.themepark.options.extent then
        config.tileset[0].extent = plugin.themepark.options.extent
    end

    utils.write_to_file(filename, toml.encode(config) .. "\n")
end

return plugin

-- ---------------------------------------------------------------------------
