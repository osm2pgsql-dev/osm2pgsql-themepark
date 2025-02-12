-- ---------------------------------------------------------------------------
--
-- Theme: explore
-- Topic: postcodes
--
-- Note that ST_ConcaveHull and ST_VoronoiPolygons can crash PostgreSQL if
-- the dataset they operate on becomes too large, so this will not run on large
-- datasets.
--
-- TODO: Split up the data for those operations in a some way.
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- For nodes and centroids of buildings tagged with address information
themepark:add_table{
    name = 'postcode_points',
    ids_type = 'any',
    geom = 'point',
    columns = themepark:columns({
        { column = 'country', type = 'text' },
        { column = 'city', type = 'text' },
        { column = 'postcode', type = 'text' },
        { column = 'streetname', type = 'text' },
        { column = 'housenumber', type = 'text' },
    }),
}

-- Ways with a name and tagged as 'highway'
themepark:add_table{
    name = 'postcode_streets',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'country', type = 'text' },
        { column = 'city', type = 'text' },
        { column = 'postcode', type = 'text' },
        { column = 'postal_code', type = 'text' },
        { column = 'streetname', type = 'text' },
        { column = 'housenumber', type = 'text' },
    }),
}

-- Postcode points with invalid postcode
themepark:add_table{
    name = 'postcode_errors',
    ids_type = 'any',
    geom = 'point',
    columns = themepark:columns({
        { column = 'postcode', type = 'text' },
        { column = 'errormsg', type = 'text' },
    }),
}

-- Boundary relations with postcodes. Can be administrative boundaries or
-- special postcode boundaries.
themepark:add_table{
    name = 'postcode_boundaries',
    ids_type = 'relation',
    geom = 'multipolygon',
    columns = themepark:columns({
        { column = 'name', type = 'text' },
        { column = 'btype', type = 'text' }, -- boundary type
        { column = 'postal_code', type = 'text', not_null = true },
        { column = 'h1', type = 'text' }, -- postcode hierarchy level 1
        { column = 'h2', type = 'text' }, -- postcode hierarchy level 2
    }),
}

-- Postcode areas derived from postcode points using convex hull.
themepark:add_table{
    name = 'postcode_areas_hull',
    ids_type = false,
    geom = 'geometry',
    columns = themepark:columns({
        { column = 'postcode', type = 'text' },
    }),
}

-- Postcode areas derived from postcode points using Voronoi decomposition.
themepark:add_table{
    name = 'postcode_areas_voronoi',
    ids_type = false,
    geom = 'geometry',
    columns = themepark:columns({
        { column = 'postcode', type = 'text' },
    }),
}

-- ---------------------------------------------------------------------------

-- Any tags starting with 'addr:'?
local function has_addr_tag(tags)
    for k, _ in pairs(tags) do
        if k:sub(1, 5) == 'addr:'then
            return true
        end
    end
    return false
end

-- This function currently only works for German postcodes which always have
-- 5 digits. This needs to be adapted for other countries.
local function valid_postcode(code)
    return code:find('^%d%d%d%d%d$')
end

local function add_postcode_point(t, geom)
    if t['addr:postcode'] and not valid_postcode(t['addr:postcode']) then
        local a = {
            postcode = t['addr:postcode'],
            errormsg = 'invalid_postcode',
            geom = geom
        }

        themepark:insert('postcode_errors', a, t)
    end

    local a = {
        country = t['addr:country'],
        city = t['addr:city'],
        postcode = t['addr:postcode'],
        streetname = t['addr:street'],
        housenumber = t['addr:housenumber'],
        geom = geom
    }

    themepark:insert('postcode_points', a, t)
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object, data)
    local t = object.tags

    if not has_addr_tag(t) then
        return
    end

    add_postcode_point(t, object:as_point())
end)

themepark:add_proc('way', function(object, data)
    local t = object.tags

    if t.building and t.building ~= 'no' then
        add_postcode_point(t, object:as_polygon():centroid())
        return
    end

    if not t.highway or not t.name then
        return
    end

    local a = {
        name = t.name,
        country = t['addr:country'],
        city = t['addr:city'],
        postcode = t['addr:postcode'],
        postal_code = t.postal_code,
        streetname = t['addr:street'],
        housenumber = t['addr:housenumber'],
        geom = object:as_linestring()
    }

    themepark:insert('postcode_streets', a, t)
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags

    if t.type == 'multipolygon' and t.building and t.building ~= 'no' then
        add_postcode_point(t, object:as_multipolygon():centroid())
    end

    if t.type == 'boundary' and t.postal_code then
        local h1
        local h2

        if valid_postcode(t.postal_code) then
            h1 = t.postal_code:sub(1, 1)
            h2 = t.postal_code:sub(1, 2)
        end

        local a = {
            name = t.name,
            btype = t.boundary,
            postal_code = t.postal_code,
            h1 = h1,
            h2 = h2,
            geom = object:as_multipolygon()
        }

        themepark:insert('postcode_boundaries', a, t)
    end
end)

-- ---------------------------------------------------------------------------

themepark:add_proc('gen', function(data)

    osm2pgsql.run_sql({
        description = 'Derive postcode areas using concave hull',
        sql = { themepark.expand_template([[
TRUNCATE postcode_areas_hull
]]), themepark.expand_template([[
WITH merged AS (
   SELECT postcode, ST_Collect(geom) AS geom, count(*) AS num
      FROM {schema}.{prefix}postcode_points
      WHERE postcode IS NOT NULL
      GROUP BY postcode
)
INSERT INTO {schema}.{prefix}postcode_areas_hull (postcode, geom)
   SELECT postcode, ST_ConcaveHull(geom, 1)
      FROM merged WHERE num > 2
]])
        }
    })

    osm2pgsql.run_sql({
        description = 'Derive postcode areas using Voronoi',
        sql = { themepark.expand_template([[
TRUNCATE postcode_areas_voronoi
]]), themepark.expand_template([[
WITH vor AS (
    SELECT ST_VoronoiPolygons(ST_Collect(geom)) AS geom
        FROM {schema}.{prefix}postcode_points
        WHERE postcode IS NOT NULL
), dumped AS (
    SELECT (ST_Dump(geom)).geom AS geom FROM vor
), with_postcode AS (
    SELECT p.postcode, d.geom
        FROM dumped d, postcode_points p
        WHERE p.postcode IS NOT NULL
          AND ST_Intersects(p.geom, d.geom)
)
INSERT INTO {schema}.{prefix}postcode_areas_voronoi (postcode, geom)
    SELECT postcode, ST_Multi(ST_Union(geom)) AS geom FROM with_postcode
        GROUP BY postcode
]])
        }
    })

end)

-- ---------------------------------------------------------------------------
