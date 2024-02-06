-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- lib/themepark/plugins/tilekiln.lua
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
local lyaml = require 'lyaml'

function plugin:build_sublayer_config(main_layer, sub_layer)
    local config = {
        minzoom = sub_layer.tiles.minzoom or 0,
        maxzoom = sub_layer.tiles.maxzoom or 14,
        extent = sub_layer.tiles.extent or 4096,
        buffer = sub_layer.tiles.buffer_size or 10,
    }

    local mvt = 'ST_AsMVTGeom("' .. sub_layer.geom_column .. '", {{unbuffered_bbox}}, {{extent}}, {{buffer}}) AS way'

    local column_names = { mvt }
    local minzoom
    for _, column in ipairs(sub_layer.columns) do
        if column.tiles == 'minzoom' then
            minzoom = column.tiles
        elseif column.tiles ~= false and column.column ~= sub_layer.geom_column then
            table.insert(column_names, '"' .. column.column .. '"')
        end
    end

    local conditions = { '"' .. sub_layer.geom_column .. '" && {{bbox}}' }
    if minzoom then
        table.insert(conditions, '{{zoom}} >= "' .. minzoom .. '"')
    end

    if sub_layer.tiles.xycondition then
        table.insert(conditions, '{{x}} = x')
        table.insert(conditions, '{{y}} = y')
    end

    local sql = utils.build_select_query(column_names, sub_layer.name, conditions,
                                         sub_layer.tiles.order_by, sub_layer.tiles.order_dir)

    local path = { main_layer.name,
                   '.', string.format('%02d', config.minzoom),
                   '-', string.format('%02d', config.maxzoom), '.sql.jinja2'}

    config.file = table.concat(path)

    utils.write_to_file(self.directory .. '/' .. config.file, sql .. "\n")

    return config
end

function plugin:build_layer_config(layer)
    local tiles = layer.tiles or {}
    if tiles.group then
        return
    end

    local config = {}

    -- Handle main (or only) layer of this layer group
    table.insert(config, self:build_sublayer_config(layer, layer))

    -- Handle sub layers of this layer group
    if plugin.themepark.layer_groups[layer.name] then
        for _, group_table in ipairs(plugin.themepark.layer_groups[layer.name]) do
            local sublayer = utils.find_name_in_array(plugin.themepark.layers, group_table.name)
            table.insert(config, self:build_sublayer_config(layer, sublayer))
        end
    end

    return config
end

function plugin:write_config(directory, options)
    self.directory = directory

    if not options then
        options = {}
    end

    local config = {
        metadata = {
            id = options.tileset or 'mytiles',
            name = options.name,
            attribution = options.attribution or plugin.themepark.options.attribution,
            version = options.version,
        },
        vector_layers = {}
    }

    for _, layer in ipairs(plugin.themepark.layers) do
        if layer.tiles ~= false then
            local layer_config = self:build_layer_config(layer)
            if layer_config then
                config.vector_layers[layer.name] = { sql = layer_config }
            end
        end
    end

    utils.write_to_file(self.directory .. '/config.yaml', lyaml.dump({ config }))
end

return plugin

-- ---------------------------------------------------------------------------
