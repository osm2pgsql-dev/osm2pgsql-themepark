-- ---------------------------------------------------------------------------
--
-- Osm2pgsql Themepark
--
-- A framework for pluggable osm2pgsql config files.
--
-- ---------------------------------------------------------------------------
--
-- themepark.lua
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

local function script_path_impl(num)
    local str = debug.getinfo(num, "S").source:sub(2)
    return str:match("(.*/)")
end

local function script_path(num)
    local success, value = pcall(script_path_impl, num)
    if success and value then
        return value
    end
    return './'
end

local themepark = {
    dir = script_path(2),
    debug = false,
    options = {
        schema = 'public',
        srid = 3857,
        attribution = '© OpenStreetMap contributors - https://openstreetmap.org/copyright',
    },
    layers = {},
    tables = {},
    themes = {},
    _columns = {},
    pre = function() return true end,
    process = {
        node = {},
        way = {},
        relation = {},
        area = {},
        select_relation_members = {},
        gen = {}
    },
}

themepark.theme_path = { script_path(3) .. '../themes/', themepark.dir .. 'themes/' }

-- ---------------------------------------------------------------------------
-- set_option(NAME, VALUE)
--
-- Set option NAME to VALUE. Some available options are:
--   schema  - Database schema to be used for tables, indexes, etc.
--   srid    - SRID for all geometries (integer)
--   extent  - Set map extent for tile server (array: xmin, ymin, xmax, ymax)
-- ---------------------------------------------------------------------------
function themepark:set_option(name, value)
    if themepark.debug then
        print("Themepark: Setting option '" .. name .. "' to '" .. value .. "'.")
    end
    themepark.options[name] = value
end

-- ---------------------------------------------------------------------------
-- register_columns(THEME, NAME, COLUMNS)
--
-- Register a set of columns (one or more) under the name NAME for the
-- THEME.
-- ---------------------------------------------------------------------------
function themepark:register_columns(theme, name, columns)
    if not self._columns[theme] then
        self._columns[theme] = {}
    end
    self._columns[theme][name] = columns
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:columns(...)
    local columns = {}
    for _, v in ipairs{...} do
        local cols = v
        if type(v) == 'string' then
            local elements = osm2pgsql.split_string(v, '/')
            cols = self._columns[elements[1]][elements[2]]
        end
        for _, c in ipairs(cols) do
            table.insert(columns, c)
        end
    end

    return columns
end

-- ---------------------------------------------------------------------------
-- add_theme_dir(DIR)
--
-- Append DIR to search path for themes. If DIR is a relative path,
-- interpret it relative to the file the function was called from.
-- ---------------------------------------------------------------------------
function themepark:add_theme_dir(dir)
    if string.find(dir, '/') ~= 1 then
        dir = script_path(5) .. dir .. '/'
    end
    if themepark.debug then
        print("Themepark: Add theme directory at '" .. dir .. "'.")
    end
    table.insert(themepark.theme_path, dir .. '/')
end

-- ---------------------------------------------------------------------------
-- init_theme(THEME)
--
-- Initialize THEME. Uses the theme search path.
-- ---------------------------------------------------------------------------
function themepark:init_theme(theme)
    if theme == '' then
        local dir = script_path(2)
        themepark.themes[''] = { dir = dir }
        if themepark.debug then
            print("Themepark: Loading theme '' with path '" .. dir .. "' ...")
        end
        return
    end

    if not theme then
        error('Missing theme argument to init_theme()')
    end

    if themepark.debug then
        print("Themepark: Loading theme '" .. theme .. "' ...")
    end

    for _, dir in ipairs(themepark.theme_path) do
        local theme_dir = dir .. theme
        local theme_file = theme_dir .. '/init.lua'
        if themepark.debug then
            print("Themepark:   Trying to load from '" .. theme_file .. "' ...")
        end
        local file = io.open(theme_file)
        if file then
            themepark.themes[theme] = dofile(theme_file)
            themepark.themes[theme].dir = theme_dir
            break
        end
    end

    if not themepark.themes[theme] then
        error("Themepark: Theme '" .. theme .. "' not found")
    end

    if themepark.debug then
        print("Themepark: Loading theme '" .. theme .. "' done.")
    end
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:add_topic(topic, cfg)
    local theme = ''
    local slash = string.find(topic, '/')
    if slash then
        theme = string.sub(topic, 1, slash - 1)
        topic = string.sub(topic, slash + 1)
    end

    if not themepark.themes[theme] then
        themepark:init_theme(theme)
    end

    if themepark.debug then
        print("Themepark: Adding topic '" .. topic .. "' from theme '" .. theme .. "' ...")
    end

    local filename = themepark.themes[theme].dir .. '/topics/' .. topic .. '.lua'

    local file, errmsg = io.open(filename, 'r')
    if not file then
        error("No topic '" .. topic .. "' in theme '" .. theme .. "'")
    end

    local script = file:read('a*')
    file:close()

    local func, msg = load(script, filename, 't')
    if not func then
        error('Load failed: ' .. msg)
    end

    local result = func(self, self.themes[theme], cfg or {})

    if themepark.debug then
        print("Themepark: Adding topic '" .. topic .. "' from theme '" .. theme .. "' done.")
    end

    return result
end

-- ---------------------------------------------------------------------------
-- This function gets all the options from the add_table() function and should
-- decide based on the "ids_type" setting how to set the "ids" field for
-- osm2pgsql flex and return that.
-- ---------------------------------------------------------------------------
function themepark:ids_policy(data)
    if not data.ids_type then
        error('Neither "ids" nor "ids_type" is set on table "' .. data.name .. '"')
    end

    local ids = { create_index = 'always' }
    if data.ids_type == 'node' or data.ids_type == 'way' or data.ids_type == 'relation' or data.ids_type == 'area' then
        ids.type = data.ids_type
        ids.id_column = data.ids_type .. '_id'
        return ids
    elseif data.ids_type == 'any' then
        ids.type = 'any'
        ids.type_column = 'osm_type'
        ids.id_column = 'osm_id'
        return ids
    elseif data.ids_type == 'tile' then
        ids.type = 'tile'
        return ids
    end

    error('Unknown id policy: ' .. data.ids_type)
end

-- ---------------------------------------------------------------------------
--
--
-- ---------------------------------------------------------------------------
function themepark:add_table(data)
    local name = data.name
    if self.tables[name] then
        error("There is already a table called '" .. name .. "'", 2)
    end

    if not data.ids then
        if not data.external and data.ids_type ~= false then
            data.ids = self:ids_policy(data)
        end
    end

    if not data.indexes then
        data.indexes = {}
    end

    if data.tiles == nil then
        data.tiles = {}
    end

    if not data.columns then
        data.columns = {}
    end

    if themepark.debug and themepark.options.debug then
        table.insert(data.columns, {
            column = themepark.options.debug, type = 'jsonb'
        })
    end

    if themepark.debug and themepark.options.tags then
        table.insert(data.columns, {
            column = themepark.options.tags, type = 'jsonb'
        })
    end

    if themepark.options.unique_id then
        table.insert(data.columns, {
            column = themepark.options.unique_id,
            sql_type = 'bigint GENERATED BY DEFAULT AS IDENTITY',
            create_only = true
        })
        table.insert(data.indexes, {
            column = themepark.options.unique_id,
            unique = true,
            method = 'btree'
        })
    end

    if data.geom then
        if type(data.geom) == 'string' then
            data.geom_type = data.geom
            data.geom_column = 'geom'
            data.geom = nil
        elseif type(data.geom) == 'table' then
            data.geom_type = data.geom.type
            data.geom_column = data.geom.column
            data.geom = nil
        end
        table.insert(data.columns, {
            column = data.geom_column,
            type = data.geom_type,
            srid = themepark.options.srid,
            expire = data.expire,
            not_null = true
        })
        table.insert(data.indexes, {
            column = data.geom_column,
            method = 'gist'
        })
    end

    if self.options.prefix then
        data.name = self.options.prefix .. data.name
    end

    if not data.schema then
        data.schema = self.options.schema
    end

    table.insert(self.layers, data)

    if not data.external then
        self.tables[name] = osm2pgsql.define_table(data)
    end
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:get_table(table_name)
    return self.tables[table_name]
end

function themepark:add_debug_info(attrs, tags, dbgdata)
    if not themepark.debug then
        return
    end

    local opt = themepark.options.tags
    if opt and tags then
        attrs[opt] = tags
    end
    opt = themepark.options.debug
    if opt and dbgdata then
        attrs[opt] = dbgdata
    end
end

function themepark:insert(table_name, data, tags, dbgdata)
    themepark:add_debug_info(data, tags, dbgdata)
    return self:get_table(table_name):insert(data)
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:add_proc(what, func)
    table.insert(self.process[what], func)
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:init_layer_groups()
    -- If we already computed the layer groups, we are done
    if self.layer_groups ~= nil then
        return
    end

    local groups = {}

    for _, layer in ipairs(self.layers) do
        if layer.tiles and layer.tiles.group then
            if not groups[layer.tiles.group] then
                groups[layer.tiles.group] = {}
            end
            table.insert(groups[layer.tiles.group], {
                minzoom = layer.tiles.minzoom,
                maxzoom = layer.tiles.maxzoom,
                name = layer.name
            })
        end
    end

    self.layer_groups = groups
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:plugin(name)
    self:init_layer_groups()
    local ts = require('themepark/plugins/' .. name, themepark)
    ts.themepark = self
    return ts;
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark.nullif(val, nullval)
    if val == nullval then
        return nil
    end
    return val
end

-- ---------------------------------------------------------------------------

-- This function should return `true` when it is called with a way object
-- that can be understood as an area (polygon). You can override this in your
-- setup code.
function themepark:way_is_area(object)
    return object.is_closed
end

-- This function should return `true` when it is called with a relation object
-- that can be understood as an area (multipolygon). You can override this in
-- your setup code.
function themepark:relation_is_area(object)
    return object.tags.type == 'multipolygon' or object.tags.type == 'boundary'
end

-- ---------------------------------------------------------------------------

function themepark.expand_template(command)
    local res = string.gsub(command, '{schema}', themepark.options.schema)
    -- ignore second return value of gsub
    return res
end

-- ---------------------------------------------------------------------------

local process_area = function(object, data)
    for _, func in ipairs(themepark.process.area) do
        if func(object, data) == 'stop' then
            return
        end
    end
end

function osm2pgsql.process_node(object)
    local data = {}

    for _, func in ipairs(themepark.process.node) do
        if func(object, data) == 'stop' then
            return
        end
    end
end

function osm2pgsql.process_way(object)
    local data = {}

    for _, func in ipairs(themepark.process.way) do
        if func(object, data) == 'stop' then
            return
        end
    end

    if themepark:way_is_area(object) then
        object.as_area = object.as_polygon
        process_area(object, data)
    end
end

function osm2pgsql.process_relation(object)
    local data = {}

    for _, func in ipairs(themepark.process.relation) do
        if func(object, data) == 'stop' then
            return
        end
    end

    if themepark:relation_is_area(object) then
        object.as_area = object.as_multipolygon
        process_area(object, data)
    end
end

function osm2pgsql.select_relation_members(relation)
    local members

    for _, func in ipairs(themepark.process.select_relation_members) do
        local m = func(relation)
        if m then
            if members then
                for _, v in ipairs(m.ways) do
                    table.insert(members.ways, v)
                end
            else
                members = m
            end
        end
    end

    return members
end

function osm2pgsql.process_gen()
    local data = {}

    for _, func in ipairs(themepark.process.gen) do
        if func(data) == 'stop' then
            return
        end
    end
end

-- ---------------------------------------------------------------------------

return themepark

-- ---------------------------------------------------------------------------
