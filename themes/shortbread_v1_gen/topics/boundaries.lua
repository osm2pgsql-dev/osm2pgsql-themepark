-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1_gen
-- Topic: boundaries
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- ---------------------------------------------------------------------------

local gen_levels = { 'l', 'm', 's' }
local gen_config = {
    l = { minzoom = 8, maxzoom = 10, simplify =   '200000', minlength =  '100', condition = '' },
    m = { minzoom = 6, maxzoom =  7, simplify =  '2000000', minlength = '1000', condition = '' },
    s = { minzoom = 2, maxzoom =  5, simplify = '10000000', minlength = '1000', condition = 'WHERE admin_level = 2'},
}

-- ---------------------------------------------------------------------------

-- If anything related to boundaries changes, this expire table gets an entry.
-- It uses zoom level 0, so there will always be at most one entry which
-- triggers re-calculation of all boundaries in the world.
local expire_boundaries = osm2pgsql.define_expire_output({
    table = themepark.with_prefix('expire_boundaries')
})

-- This table contains all the ways that are members of a boundary relation.
-- From this interim table the output tables "boundaries", "boundaries_l",
-- "boundaries_m", and "boundaries_s" are generated.
themepark:add_table{
    name = 'boundaries_ways_interim',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'relation_ids', sql_type = 'int8[]', not_null = true },
        { column = 'admin_level', type = 'int', not_null = true },
        { column = 'maritime', type = 'bool', not_null = true },
        { column = 'coastline', type = 'bool', not_null = true },
        { column = 'closure_segment', type = 'bool', not_null = true },
        { column = 'disputed', type = 'bool', not_null = true },
    }),
    expire = {{ output = expire_boundaries }},
    tiles = false
}

-- This table of boundary relations is currently only needed to trigger
-- changes.
themepark:add_table{
    name = 'boundaries_relations_interim',
    ids_type = 'relation',
    geom = 'multilinestring',
    columns = themepark:columns('core/name', {
        { column = 'admin_level', type = 'int', not_null = true },
        { column = 'maritime', type = 'bool', not_null = true },
        { column = 'disputed', type = 'bool', not_null = true },
    }),
    expire = {{ output = expire_boundaries }},
    tiles = false
}

themepark:add_table{
    name = 'boundaries',
    ids_type = false,
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'way_ids', sql_type = 'int8[]', not_null = true, tiles = false },
        { column = 'relation_ids', sql_type = 'int8[]', not_null = true, tiles = false },
        { column = 'admin_level', type = 'int', not_null = true },
        { column = 'maritime', type = 'bool', not_null = true },
        { column = 'disputed', type = 'bool', not_null = true },
    }),
    tiles = {
        minzoom = 11,
        simplify = false,
    }
}

for _, level in ipairs(gen_levels) do
    themepark:add_table{
        name = 'boundaries_' .. level,
        ids_type = false,
        geom = 'linestring',
        columns = themepark:columns({
            { column = 'way_ids', sql_type = 'int8[]', not_null = true, tiles = false },
            { column = 'relation_ids', sql_type = 'int8[]', not_null = true, tiles = false },
            { column = 'admin_level', type = 'int', not_null = true },
            { column = 'maritime', type = 'bool', not_null = true },
            { column = 'disputed', type = 'bool', not_null = true },
        }),
        tiles = {
            minzoom = gen_config[level].minzoom,
            maxzoom = gen_config[level].maxzoom,
            group = 'boundaries',
            simplify = false,
        }
    }
end

-- ---------------------------------------------------------------------------

-- Storage of information from boundary relations for use by boundary ways
-- (two-stage processing).

-- Relation ids and minimum admin level of all relations that reference a way id
local rinfos = {}

-- Minimum admin level of all relations tagged boundary=disputed that
-- reference a way id
local min_disputed_admin_level = {}

-- ---------------------------------------------------------------------------

-- Shortbread is only interested in level 2 and level 4 admin boundaries.
local function is_admin_boundary(tags)
    return (tags.type == 'boundary' or tags.type == 'multipolygon')
           and tags.boundary == 'administrative'
           and (tags.admin_level == '2' or tags.admin_level == '4')
end

-- Get numerical admin level from string, default to 1 if invalid
local function get_admin_level(value)
    if not value or not string.match(value, '^[1-9][0-9]?$') then
        return 1
    end

    return tonumber(value)
end

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object, data)
    if osm2pgsql.stage == 1 then
        return
    end

    local info = rinfos[object.id]
    if not info then
        return
    end

    table.sort(info.rel_ids)

    local t = object.tags

    -- Set disputed flag either from disputed tag on the way...
    local disputed = (t.disputed == 'yes')

    -- .. or from a parent relation with boundary=disputed
    if min_disputed_admin_level[object.id] and min_disputed_admin_level[object.id] <= info.admin_level then
        disputed = true
    end

    local a = {
        relation_ids    = '{' .. table.concat(info.rel_ids, ',') .. '}',
        admin_level     = info.admin_level,
        maritime        = (t.maritime ~= nil and (t.maritime == 'yes')),
        disputed        = disputed,
        closure_segment = (t.closure_segment ~= nil and t.closure_segment == 'yes'),
        coastline       = (t.natural ~= nil and t.natural == 'coastline'),
        geom            = object:as_linestring(),
    }

    themepark:insert('boundaries_ways_interim', a, t)
end)

themepark:add_proc('select_relation_members', function(relation)
    if is_admin_boundary(relation.tags) then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end)

themepark:add_proc('relation', function(object, data)
    if is_admin_boundary(object.tags) then
        local t = object.tags

        local admin_level = tonumber(t.admin_level)

        for _, id in ipairs(osm2pgsql.way_member_ids(object)) do
            if not rinfos[id] then
                rinfos[id] = { admin_level = admin_level, rel_ids = {} }
            elseif rinfos[id].admin_level > admin_level then
                rinfos[id].admin_level = admin_level
            end
            table.insert(rinfos[id].rel_ids, object.id)
        end

        local a = {
            admin_level = admin_level,
            maritime    = (t.maritime ~= nil and t.maritime == 'yes'),
            disputed    = (t.disputed ~= nil and t.disputed == 'yes'),
            geom        = object:as_multilinestring(),
        }

        themepark.themes.core.add_name(a, object)
        themepark:insert('boundaries_relations_interim', a, t)

        return
    end

    if object.tags.boundary == 'disputed' then
        -- Ways in relations tagged boundary=disputed are flagged as disputed
        -- if either the relation doesn't have an admin_level tag or the
        -- admin_level tag is <= the admin level the way got from the
        -- boundary=administrative relation(s).
        local admin_level = get_admin_level(object.tags.admin_level)

        for _, id in ipairs(osm2pgsql.way_member_ids(object)) do
            if not min_disputed_admin_level[id] or min_disputed_admin_level[id] > admin_level then
                min_disputed_admin_level[id] = admin_level
            end
        end
    end
end)

local function gen_commands(sql, level)
    local c = gen_config[level]

    table.insert(sql, 'CREATE TABLE {schema}.{prefix}boundaries_' .. level ..
                      '_new (LIKE {schema}.{prefix}boundaries_' .. level .. ' INCLUDING IDENTITY)')

    table.insert(sql, [[
WITH simplified AS (
    SELECT way_ids, relation_ids, admin_level, maritime, disputed, ST_SimplifyVW(geom, ]] .. c.simplify .. [[) AS geom
        FROM {schema}.{prefix}boundaries ]] .. c.condition .. [[
)
INSERT INTO {schema}.{prefix}boundaries_]] .. level ..
    [[_new (way_ids, relation_ids, admin_level, maritime, disputed, geom)
    SELECT way_ids, relation_ids, admin_level, maritime, disputed, geom
    FROM simplified WHERE ST_Length(geom) > ]] .. c.minlength)

    table.insert(sql, 'ANALYZE {schema}.{prefix}boundaries_' .. level .. '_new')
    table.insert(sql, 'CREATE INDEX ON {schema}.{prefix}boundaries_' .. level ..
                      '_new USING GIST (geom)')
    table.insert(sql, 'DROP TABLE {schema}.{prefix}boundaries_' .. level)
    table.insert(sql, 'ALTER TABLE {schema}.{prefix}boundaries_' .. level ..
                      '_new RENAME TO {prefix}boundaries_' .. level)
end

themepark:add_proc('gen', function(data)
    local sql = {
        'CREATE TABLE {schema}.{prefix}boundaries_new (LIKE {schema}.{prefix}boundaries INCLUDING IDENTITY)',
        [[
WITH multigeom AS (
SELECT array_agg(way_id ORDER BY way_id) AS way_ids,
    relation_ids,
    min(admin_level) AS admin_level,
    (maritime OR coastline) AS maritime,
    disputed,
    ST_LineMerge(ST_Collect(geom)) AS geom
    FROM {schema}.{prefix}boundaries_ways_interim
        WHERE closure_segment IS FALSE
        GROUP BY relation_ids, maritime OR coastline, disputed
)
INSERT INTO {schema}.{prefix}boundaries_new (way_ids, relation_ids, admin_level, maritime, disputed, geom)
SELECT way_ids, relation_ids, admin_level, maritime, disputed, (ST_Dump(geom)).geom AS geom
    FROM multigeom ]],
        'ANALYZE {schema}.{prefix}boundaries_new',
        'CREATE INDEX ON {schema}.{prefix}boundaries_new USING GIST (geom)',
        'DROP TABLE {schema}.{prefix}boundaries',
        'ALTER TABLE {schema}.{prefix}boundaries_new RENAME TO {prefix}boundaries'
    }

    gen_commands(sql, 'l');
    gen_commands(sql, 'm');
    gen_commands(sql, 's');

    table.insert(sql, 'TRUNCATE {schema}.{prefix}expire_boundaries')

    local expanded_sql = {}
    for _, s in ipairs(sql) do
        table.insert(expanded_sql, themepark.expand_template(s))
    end

    osm2pgsql.run_sql({
        description = 'Merge boundary lines for small zoom levels',
        if_has_rows = themepark.expand_template('SELECT 1 FROM {schema}.{prefix}expire_boundaries LIMIT 1'),
        transaction = true,
        sql = expanded_sql
    })
end)

-- ---------------------------------------------------------------------------
