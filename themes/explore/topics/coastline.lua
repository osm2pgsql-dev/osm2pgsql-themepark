-- ---------------------------------------------------------------------------
--
-- Theme: explore
-- Topic: coastline
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local expire = osm2pgsql.define_expire_output({
    maxzoom = 1,
    table = themepark.with_prefix('coastline_expire'),
})

-- There shouldn't be any nodes tagged natural=coastline, but that sometimes
-- happens. They will end up in this table.
themepark:add_table{
    name = 'coastline_nodes',
    ids = { type = 'node', id_column = 'node_id', create_index = 'unique' }, -- primary_key
    geom = 'point',
    columns = {},
    tags = {
        { key = 'natural', values = 'coastline', on = 'n' },
    },
}

-- All ways tagged natural=coastline.
themepark:add_table{
    name = 'coastline_ways',
    ids = { type = 'way', id_column = 'way_id', create_index = 'unique' }, -- primary_key
    geom = 'linestring',
    columns = {
        { column = 'bogus', type = 'bool', not_null = true }, -- if tagged coastline=bogus
        { column = 'closure_segment', type = 'bool', not_null = true }, -- if tagged closure_segment=yes
    },
    expire = {
        { output = expire },
    },
    tags = {
        { key = 'natural', values = 'coastline', on = 'w' },
        { key = 'coastline', values = 'bogus', on = 'w' },
        { key = 'closure_segment', values = 'yes', on = 'w' },
    },
}

-- There shouldn't be any relations tagged natural=coastline, but that
-- sometimes happens. They will end up in this table.
themepark:add_table{
    name = 'coastline_relations',
    ids_type = 'relation',
    geom = 'geometry',
    columns = {},
    tags = {
        { key = 'natural', values = 'coastline', on = 'r' },
    },
}

themepark:add_table{
    name = 'coastline_joined',
    ids_type = 'tile',
    geom = 'linestring',
    columns = {
        { column = 'length', type = 'real' },
        { column = 'orientation', type = 'bool' },
    },
}

-- This table contains all the places where the coastline intersects. This
-- should never happen, because the coastline must always be continuous.
-- Intersection can be a point or a line (if there are coastline ways one
-- on top of the other.)
themepark:add_table{
    name = 'coastline_intersections',
    ids_type = 'tile',
    geom = 'geometry',
    columns = {
        { column = 'way1_id', type = 'int8', not_null = true },
        { column = 'way2_id', type = 'int8', not_null = true },
        { column = 'way1_geom', type = 'linestring', not_null = true },
        { column = 'way2_geom', type = 'linestring', not_null = true },
    },
}

-- This table contains all the points where a coastline ends. This should
-- never happen, because the coastline must always be continuous.
themepark:add_table{
    name = 'coastline_endpoints',
    ids_type = false,
    geom = 'point',
    columns = {
        { column = 'num', type = 'int', not_null = true }, -- how many coastline ways end in this point?
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object, data)
    local t = object.tags
    if t.natural == 'coastline' then
        local a = { geom = object:as_point() }
        themepark:insert('coastline_nodes', a, t)
    end
end)

themepark:add_proc('way', function(object, data)
    local t = object.tags
    if t.natural == 'coastline' then
        local a = {
            bogus = (t.coastline == 'bogus'),
            closure_segment = (t.closure_segment == 'yes'),
            geom = object:as_linestring()
        }
        themepark:insert('coastline_ways', a, t)
    end
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags
    if t.natural == 'coastline' then
        for sgeom in object:as_geometrycollection():geometries() do
            local a = { geom = sgeom }
            themepark:insert('coastline_relations', a, t)
        end
    end
end)

-- ---------------------------------------------------------------------------

themepark:add_proc('gen', function(data)

    -- This can't be done for the whole planet, because ST_Collect() will
    -- try to create a MultiLineString that is too large. We could probably
    -- do this in two steps, first doing what is done here and then LineMerge
    -- the result again, but this is left as an exercise for the reader.
    osm2pgsql.run_gen('tile-sql', {
        name = 'join-coastline',
        src_table = themepark.with_prefix('coastline_ways'),
        dest_table = themepark.with_prefix('coastline_joined'),
        debug = true,
        expire_list = themepark.with_prefix('coastline_expire'),
        zoom = 2,
        sql = [[
WITH
bounds AS (
    SELECT ST_TileEnvelope({ZOOM}, {X}, {Y}) AS geom
),
joined AS (
    SELECT {X} AS x, {Y} AS y, ST_LineMerge(ST_Collect(c.geom), true) AS geom
        FROM coastline_ways c, bounds b
        WHERE c.geom && b.geom AND ST_Intersects(ST_StartPoint(c.geom), b.geom)
),
dumped AS (
    SELECT x, y, (ST_Dump(geom)).geom AS geom FROM joined
)
INSERT INTO coastline_joined (x, y, length, geom, orientation)
    SELECT x, y, ST_Length(geom), geom,
        CASE ST_IsClosed(geom) AND ST_NumPoints(geom) >= 4
            WHEN true THEN ST_IsPolygonCCW(ST_MakePolygon(geom))
            ELSE NULL
        END
        FROM dumped
]]
    })

    -- Find all points where the coastline ends. There should be none, of
    -- course.
    osm2pgsql.run_sql({
        description = 'find endpoints',
        sql = { themepark.expand_template([[
TRUNCATE {schema}.{prefix}coastline_endpoints
]]), themepark.expand_template([[
WITH
open_ended AS (
    SELECT ST_StartPoint(geom) AS p0, ST_EndPoint(geom) AS p1
        FROM {schema}.{prefix}coastline_ways WHERE NOT ST_IsClosed(geom)
),
endpoints AS (
    SELECT p0 AS geom FROM open_ended
    UNION ALL
    SELECT p1 AS geom FROM open_ended
)
INSERT INTO {schema}.{prefix}coastline_endpoints (geom, num)
    SELECT e.geom, count(*)
        FROM endpoints e
        GROUP BY e.geom HAVING count(*) != 2
]])
        }
    })

    -- Coastline ways can intersect with themselves or with another coastline
    -- way. Both of these case are detected here. Results can either be a
    -- point or a (multi)linestring.
    osm2pgsql.run_gen('tile-sql', {
        name = 'find-coastline-intersections',
        src_table = themepark.with_prefix('coastline_ways'),
        dest_table = themepark.with_prefix('coastline_intersections'),
        debug = true,
        zoom = 9,
        sql = themepark.expand_template([[
WITH
bounds AS (
    SELECT ST_TileEnvelope({ZOOM}, {X}, {Y}) AS geom
),
in_tile AS (
    SELECT c.way_id, c.geom
        FROM {schema}.{prefix}coastline_ways c, bounds b
        WHERE c.geom && b.geom
)
INSERT INTO {schema}.{prefix}coastline_intersections (geom, way1_id, way2_id, way1_geom, way2_geom, x, y)
SELECT ST_Intersection(a.geom, b.geom) AS geom, a.way_id, b.way_id, a.geom, b.geom, {X}, {Y}
    FROM in_tile a, in_tile b
    WHERE (a.way_id < b.way_id
            AND a.geom && b.geom
            AND ST_Relate(a.geom, b.geom, 'T********'))
        OR (a.way_id = b.way_id AND NOT ST_IsSimple(a.geom))
]])
    })

end)

-- ---------------------------------------------------------------------------
