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

local function script_dir_impl(num)
    local src = debug.getinfo(num, "S").source
    return src:match("^@(.*/)") -- return directory
end

-- Return the directory of the script calling this function directly or
-- indirectly. Goes 'num' levels up the call stack, and returns the directory
-- of the script running the function found in that way. Returns the current
-- directory ('./') if that fails.
local function script_dir(num)
    local success, value = pcall(script_dir_impl, num)
    if success and value then
        return value
    end
    return './'
end

local themepark = {
    _columns = {},
    debug = false,
    dir = script_dir(1),
    layers = {},
    options = {
        schema = 'public',
        srid = 3857,
        attribution = '© OpenStreetMap contributors - https://openstreetmap.org/copyright',
        cluster = 'auto',
    },
    process = {
        node = {},
        way = {},
        relation = {},
        untagged_node = {},
        untagged_way = {},
        untagged_relation = {},
        deleted_node = {},
        deleted_way = {},
        deleted_relation = {},
        area = {},
        select_relation_members = {},
        after_nodes = {},
        after_ways = {},
        after_relations = {},
        gen = {}
    },
    tables = {},
    theme_search_path = {},
    themes = {},
}

if os.getenv('THEMEPARK_DEBUG') then
    themepark.debug = true
end

(function()
    -- Use search path from THEMEPARK_PATH env variable if available
    local search_path_from_env = os.getenv('THEMEPARK_PATH')
    if search_path_from_env then
        themepark.theme_search_path = osm2pgsql.split_string(search_path_from_env, ':')
    end

    -- Theme search path always contains the 'themes' directory in the
    -- themepark repo.
    local themes_dir = themepark.dir:gsub('/lua/$', '/themes')
    table.insert(themepark.theme_search_path, themes_dir)

    if themepark.debug then
        print("Themepark: Theme search path: " .. table.concat(themepark.theme_search_path, ':'))
    end
end)()

-- ---------------------------------------------------------------------------
-- set_option(NAME, VALUE)
--
-- Set option NAME to VALUE. Some available options are:
--   schema  - Database schema to be used for tables, indexes, etc.
--   srid    - SRID for all geometries (integer)
--   extent  - Set map extent for tile server (array: xmin, ymin, xmax, ymax)
-- ---------------------------------------------------------------------------
function themepark:set_option(name, value)
    if self.debug then
        print("Themepark: Setting option '" .. name .. "' to '" .. value .. "'.")
    end
    self.options[name] = value
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
-- Prepend DIR to search path for themes. If DIR is a relative path,
-- interpret it relative to the file the function was called from.
-- ---------------------------------------------------------------------------
function themepark:add_theme_dir(dir)
    if string.find(dir, '/') ~= 1 then
        dir = script_dir(5) .. dir
    end
    table.insert(self.theme_search_path, 1, dir)

    if self.debug then
        print("Themepark: Added theme directory at '" .. dir .. "'.")
        print("Themepark: Theme search path: " .. table.concat(themepark.theme_search_path, ':'))
    end
end

-- ---------------------------------------------------------------------------
-- init_theme(THEME)
--
-- Initialize THEME. Uses the theme search path. Returns the theme.
--
-- If the theme has already been initialized by an earlier call to this
-- function, the existing theme is returned.
-- ---------------------------------------------------------------------------
function themepark:init_theme(theme)
    if self.themes[theme] then
        return self.themes[theme]
    end

    if not theme then
        error('Missing theme argument to init_theme()')
    end

    if self.debug then
        print("Themepark: Loading theme '" .. theme .. "' ...")
    end

    for _, dir in ipairs(self.theme_search_path) do
        local theme_dir = dir .. '/' .. theme
        local theme_file = theme_dir .. '/init.lua'
        if self.debug then
            print("Themepark:   Trying to load from '" .. theme_file .. "' ...")
        end
        local file = io.open(theme_file)
        if file then
            local script = file:read('*a')
            file:close()

            local func, msg = load(script, theme_file, 't')
            if not func then
                error('Loading ' .. theme_file .. ' failed: ' .. msg)
            end

            self.themes[theme] = func(self)
            self.themes[theme].dir = theme_dir
            break
        end
    end

    if not self.themes[theme] then
        error("Themepark: Theme '" .. theme .. "' not found")
    end

    if self.debug then
        print("Themepark: Loading theme '" .. theme .. "' done.")
    end

    return self.themes[theme]
end

-- ---------------------------------------------------------------------------
-- add_topic(TOPIC, OPTIONS)
--
-- Add TOPIC. TOPIC consists of the THEME, a forward slash (/), and the topic
-- in that theme. Will initialize the theme if that hasn't been done already.
--
-- OPTIONS is an optional key/value table with config options forwarded to the
-- topic.
-- ---------------------------------------------------------------------------
function themepark:add_topic(topic, options)
    local theme_name = ''
    local slash = string.find(topic, '/')
    if slash then
        theme_name = string.sub(topic, 1, slash - 1)
        topic = string.sub(topic, slash + 1)
    else
        error("Missing '/' in topic: " .. topic)
    end

    local theme = self:init_theme(theme_name)

    if self.debug then
        print("Themepark: Adding topic '" .. topic .. "' from theme '" .. theme_name .. "' ...")
    end

    local filename = theme.dir .. '/topics/' .. topic .. '.lua'

    local file, errmsg = io.open(filename, 'r')
    if not file then
        error("No topic '" .. topic .. "' in theme '" .. theme_name .. "'")
    end

    local script = file:read('*a')
    file:close()

    local func, msg = load(script, filename, 't')
    if not func then
        error('Load failed: ' .. msg)
    end

    local result = func(self, theme, options or {})

    if self.debug then
        print("Themepark: Adding topic '" .. topic .. "' from theme '" .. theme_name .. "' done.")
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

    if self.debug and self.options.debug then
        table.insert(data.columns, {
            column = self.options.debug, type = 'jsonb'
        })
    end

    if self.debug and self.options.tags then
        table.insert(data.columns, {
            column = self.options.tags, type = 'jsonb'
        })
    end

    if self.options.unique_id then
        table.insert(data.columns, {
            column = self.options.unique_id,
            sql_type = 'bigint GENERATED BY DEFAULT AS IDENTITY',
            create_only = true
        })
        table.insert(data.indexes, {
            column = self.options.unique_id,
            unique = true,
            method = 'btree'
        })
    end

    if data.geom then
        local not_null = true
        if type(data.geom) == 'string' then
            data.geom_type = data.geom
            data.geom_column = 'geom'
            data.geom = nil
        elseif type(data.geom) == 'table' then
            data.geom_type = data.geom.type
            data.geom_column = data.geom.column
            if data.geom.not_null == false then
                not_null = false
            end
            data.geom = nil
        end
        table.insert(data.columns, 1, {
            column = data.geom_column,
            type = data.geom_type,
            projection = self.options.srid,
            expire = data.expire,
            not_null = not_null
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

    if not data.cluster then
        data.cluster = self.options.cluster
    end

    table.insert(self.layers, data)

    if not data.external then
        self.tables[name] = osm2pgsql.define_table(data)
    end
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function themepark:get_table(table_name)
    local dbtable = self.tables[table_name]
    if not dbtable then
        error("Unknown table '" .. table_name .. "'", 2)
    end
    return dbtable
end

function themepark:add_debug_info(attrs, tags, dbgdata)
    if not self.debug then
        return
    end

    local opt = self.options.tags
    if opt and tags then
        attrs[opt] = tags
    end
    opt = self.options.debug
    if opt and dbgdata then
        attrs[opt] = dbgdata
    end
end

function themepark:insert(table_name, data, tags, dbgdata)
    self:add_debug_info(data, tags, dbgdata)
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
    local ts = require('themepark/plugins/' .. name, self)
    ts.self = self
    return ts
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

function themepark.expand_template(str)
    str = string.gsub(str, '{schema}', themepark.options.schema)
    str = string.gsub(str, '{prefix}', themepark.options.prefix or '')
    -- ignore second return value of gsub
    return str
end

function themepark.with_prefix(name)
    return (themepark.options.prefix or '') .. name
end

-- ---------------------------------------------------------------------------

local call_each = function(funcs, ...)
    for _, func in ipairs(funcs) do
        if func(...) == 'stop' then
            return
        end
    end
end

function osm2pgsql.process_way(object)
    local data = {}

    call_each(themepark.process.way, object, data)

    if themepark:way_is_area(object) then
        object.as_area = object.as_polygon
        call_each(themepark.process.area, object, data)
    end
end

function osm2pgsql.process_relation(object)
    local data = {}

    call_each(themepark.process.relation, object, data)

    if themepark:relation_is_area(object) then
        object.as_area = object.as_multipolygon
        call_each(themepark.process.area, object, data)
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

local function gen_process_func_with_object(type)
    local funcs = themepark.process[type]
    return function(object)
        local data = {}
        call_each(funcs, object, data)
    end
end

local function gen_process_func(type)
    local funcs = themepark.process[type]
    return function()
        local data = {}
        call_each(funcs, data)
    end
end

osm2pgsql.process_node = gen_process_func_with_object('node')
osm2pgsql.process_untagged_node = gen_process_func_with_object('untagged_node')
osm2pgsql.process_untagged_way = gen_process_func_with_object('untagged_way')
osm2pgsql.process_untagged_relation = gen_process_func_with_object('untagged_relation')
osm2pgsql.process_deleted_node = gen_process_func_with_object('deleted_node')
osm2pgsql.process_deleted_way = gen_process_func_with_object('deleted_way')
osm2pgsql.process_deleted_relation = gen_process_func_with_object('deleted_relation')

osm2pgsql.after_nodes = gen_process_func('after_nodes')
osm2pgsql.after_ways = gen_process_func('after_ways')
osm2pgsql.after_relations = gen_process_func('after_relations')
osm2pgsql.process_gen = gen_process_func('gen')

-- ---------------------------------------------------------------------------

return themepark

-- ---------------------------------------------------------------------------
