-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1_gen
-- Topic: water
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- ---------------------------------------------------------------------------

local gen_levels = { 'l', 'm', 's' }
local gen_config = {
    l = { minzoom = 10, maxzoom = 11, genzoom = 12 },
    m = { minzoom =  8, maxzoom =  9, genzoom = 10 },
    s = { minzoom =  6, maxzoom =  7, genzoom =  8 },
}

-- ---------------------------------------------------------------------------

local expire_levels = {}

for _, level in ipairs(gen_levels) do
    expire_levels[level] = osm2pgsql.define_expire_output({
        maxzoom = gen_config[level].genzoom,
        table = 'expire_water_polygons_' .. level
    })

    themepark:add_table{
        name = 'water_polygons_' .. level,
        ids_type = 'tile',
        geom = 'polygon',
        columns = {
            { column = 'kind', type = 'text', not_null = true },
        },
        tiles = {
            minzoom = gen_config[level].minzoom,
            maxzoom = gen_config[level].maxzoom,
            group = 'water_polygons',
        },
    }
end

themepark:add_table{
    name = 'water_polygons',
    ids_type = 'area',
    geom = 'multipolygon',
    expire = {
        { output = expire_levels.l },
        { output = expire_levels.m },
        { output = expire_levels.s },
    },
    columns = themepark:columns({
        { column = 'kind', type = 'text', not_null = true },
        { column = 'way_area', type = 'real' },
    }),
    tiles = {
        minzoom = 12,
        simplify = false,
    },
}

themepark:add_table{
    name = 'water_polygons_labels',
    ids_type = 'area',
    geom = 'point',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'way_area', type = 'real' },
    }),
    tiles = {
        minzoom = 5,
        order_by = 'way_area',
        order_dir = 'desc',
    }
}

-- Shortbread: water_lines and water_lines_labels
themepark:add_table{
    name = 'water_lines',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'tunnel', type = 'bool' },
        { column = 'bridge', type = 'bool' },
        { column = 'width', type = 'real' }, -- extension, not in Shortbread
        { column = 'layer', type = 'int', not_null = true },
        { column = 'minzoom', type = 'int', not_null = true, tiles = 'minzoom' },
    }),
    tiles = {
        minzoom = 12
    },
}

local expire_lines = osm2pgsql.define_expire_output({
    table = 'expire_water_lines'
})

-- Used as basis for generalized data
themepark:add_table{
    name = 'water_lines_gen_interim',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'tunnel', type = 'bool', not_null = true },
        { column = 'bridge', type = 'bool', not_null = true },
    }),
    expire = {{ output = expire_lines }},
    tiles = false
}

-- For generalized water lines
themepark:add_table{
    name = 'water_lines_gen',
    ids_type = false,
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'tunnel', type = 'bool', not_null = true },
        { column = 'bridge', type = 'bool', not_null = true },
    }),
    tiles = {
        group = 'water_lines',
        minzoom = 5,
        maxzoom = 11,
    },
}

-- ---------------------------------------------------------------------------

local check_waterway = osm2pgsql.make_check_values_func({
    'river', 'canal', 'stream', 'ditch'
})

local feet_per_meter = 3.2808399

local round = function(value)
    return math.floor(value + 0.5)
end

local parse_width = function(w)
    local val, unit = osm2pgsql.split_unit(w, 'm')
    if not val then
        return nil
    end

    if unit ~= 'ft' then -- TODO: also handle syntax with ' as feet
        val = round(val / feet_per_meter)
    elseif unit ~= 'm' then
        val = round(val)
    else -- unknown unit
        val = nil
    end
    if val and val > 200 then -- don't trust large values
        return nil
    end
    return val
end

-- ---------------------------------------------------------------------------

local get_bridge_value = osm2pgsql.make_check_values_func({
    'yes', 'viaduct', 'boardwalk', 'cantilever', 'covered', 'low_water_crossing', 'movable', 'trestle'
}, false)

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object, data)
    local t = object.tags
    local waterway = t.waterway
    if check_waterway(waterway) then
        local a = {
            kind = waterway,
            geom = object:as_linestring(),
            layer = data.core.layer,
            width = parse_width(t.width),
            bridge = get_bridge_value(t.bridge),
            tunnel = false
        }
        if t.tunnel == 'yes' or t.tunnel == 'building_passage' or t.covered == 'yes' then
            a.tunnel = true
        end

        if a.kind == 'stream' or a.kind == 'ditch' then
            a.minzoom = 14
        else
            a.minzoom = 9
        end

        themepark.themes.core.add_name(a, object)
        themepark:insert('water_lines', a, t)
        if a.kind == 'river' or a.kind == 'canal' then
            themepark:insert('water_lines_gen_interim', a, t)
        end
    end
end)

themepark:add_proc('area', function(object, data)
    local t = object.tags
    local kind

    if t.natural == 'glacier' then
        kind = 'glacier'
    elseif t.natural == 'water' then
        if t.water == 'river' then
            kind = 'river'
        else
            kind = 'water'
        end
    elseif t.waterway == 'riverbank' then
        kind = 'river'
    elseif t.waterway == 'dock' or t.waterway == 'canal' then
        kind = t.waterway
    elseif t.landuse == 'basin' or t.landuse == 'reservoir' then
        kind = t.landuse
    end

    if not kind then
        return
    end

    local g = object:as_area():transform(3857)
    local a = {
        kind = kind,
        way_area = round(g:area()),
        geom = g
    }
    themepark:insert('water_polygons', a)

    if themepark.themes.core.add_name(a, object) then
        if a.way_area > 10000 then
            a.geom = g:pole_of_inaccessibility()
            themepark:insert('water_polygons_labels', a)
        end
    end
end)

-- ---------------------------------------------------------------------------

local name_columns = {}
for _, column in ipairs(themepark:columns('core/name')) do
    table.insert(name_columns, column.column)
end

local name_list = table.concat(name_columns, ', ')

themepark:add_proc('gen', function(data)
    for _, level in ipairs(gen_levels) do
        osm2pgsql.run_gen('raster-union', {
            schema = themepark.options.schema,
            name = 'water_polygons_' .. level,
            debug = false,
            src_table = 'water_polygons',
            dest_table = 'water_polygons_' .. level,
            zoom = gen_config[level].genzoom,
            geom_column = 'geom',
            group_by_column = 'kind',
            margin = 0.0,
            make_valid = true,
            expire_list = 'expire_water_polygons_' .. level
        })
    end

    osm2pgsql.run_sql({
        description = 'Merge water lines for small zoom levels',
        if_has_rows = themepark.expand_template('SELECT 1 FROM {schema}.expire_water_lines LIMIT 1'),
        transaction = true,
        sql = {
            themepark.expand_template([[
CREATE TABLE {schema}.water_lines_gen_new
(LIKE {schema}.water_lines_gen INCLUDING IDENTITY)]]),
            themepark.expand_template([[
WITH merged AS
    (SELECT ]] .. name_list .. [[, kind, tunnel, bridge, ST_LineMerge(ST_Collect(geom)) AS geom
        FROM {schema}.water_lines_gen_interim
            GROUP BY kind, ]] .. name_list .. [[, tunnel, bridge),
simplified AS
    (SELECT ]] .. name_list .. [[, kind, tunnel, bridge,
            ST_Simplify((ST_Dump(geom)).geom, 20) AS geom FROM merged)
INSERT INTO {schema}.water_lines_gen_new (]] .. name_list .. [[, kind, tunnel, bridge, geom)
    SELECT * FROM simplified WHERE geom IS NOT NULL
]]),
            themepark.expand_template('ANALYZE {schema}.water_lines_gen_new'),
            themepark.expand_template('CREATE INDEX ON {schema}.water_lines_gen_new USING GIST (geom)'),
            themepark.expand_template('DROP TABLE {schema}.water_lines_gen'),
            themepark.expand_template('ALTER TABLE {schema}.water_lines_gen_new RENAME TO water_lines_gen'),
            themepark.expand_template('TRUNCATE {schema}.expire_water_lines'),
        }
    })
end)

-- ---------------------------------------------------------------------------
