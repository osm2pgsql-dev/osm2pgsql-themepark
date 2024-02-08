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
-- It used zoom level 0, so there will always be at most one entry which
-- triggers re-calculation of all boundaries in the world.
local expire_boundaries = osm2pgsql.define_expire_output({
    table = 'expire_boundaries'
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
local rinfos = {}

-- ---------------------------------------------------------------------------

-- Check if this looks like a boundary and return admin_level as number
-- Return nil if this is not a valid boundary.
local function get_admin_level(tags)
    local type = tags.type

    if type == 'boundary' or type == 'multipolygon' then
        local boundary = tags.boundary
        if boundary == 'administrative' or boundary == 'disputed' then
            return tonumber(tags.admin_level)
        end
    end
end

-- Check the (numeric) admin level. Change this depending on which admin
-- levels you want to process. Shortbread only shows 2 and 4.
local function valid_admin_level(level)
    return level == 2 or level == 4
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
    local a = {
        relation_ids    = '{' .. table.concat(info.rel_ids, ',') .. '}',
        admin_level     = info.admin_level,
        maritime        = (t.maritime ~= nil and (t.maritime == 'yes')),
        disputed        = (info.disputed or (t.disputed ~= nil and t.disputed == 'yes')),
        closure_segment = (t.closure_segment ~= nil and t.closure_segment == 'yes'),
        coastline       = (t.natural ~= nil and t.natural == 'coastline'),
        geom            = object:as_linestring(),
    }

    themepark:insert('boundaries_ways_interim', a, t)
end)

themepark:add_proc('select_relation_members', function(relation)
    if valid_admin_level(get_admin_level(relation.tags)) then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags

    local admin_level = get_admin_level(t)

    if not valid_admin_level(admin_level) then
        return
    end

    for _, member in ipairs(object.members) do
        if member.type == 'w' then
            if not rinfos[member.ref] then
                rinfos[member.ref] = { admin_level = admin_level, rel_ids = {} }
            elseif rinfos[member.ref].admin_level > admin_level then
                rinfos[member.ref].admin_level = admin_level
            end
            table.insert(rinfos[member.ref].rel_ids, object.id)
            rinfos[member.ref].disputed = (t.boundary == 'disputed')
        end
    end

    local a = {
        admin_level = admin_level,
        maritime    = (t.maritime ~= nil and t.maritime == 'yes'),
        disputed    = (t.disputed ~= nil and t.disputed == 'yes'),
        geom        = object:as_multilinestring(),
    }

    themepark.themes.core.add_name(a, object)
    themepark:insert('boundaries_relations_interim', a, t)
end)

local function gen_commands(sql, level)
    local c = gen_config[level]

    table.insert(sql, 'CREATE TABLE {schema}.boundaries_' .. level ..
                      '_new (LIKE {schema}.boundaries_' .. level .. ' INCLUDING IDENTITY)')

    table.insert(sql, [[
WITH simplified AS (
    SELECT way_ids, relation_ids, admin_level, maritime, disputed, ST_SimplifyVW(geom, ]] .. c.simplify .. [[) AS geom
        FROM {schema}.boundaries ]] .. c.condition .. [[
)
INSERT INTO {schema}.boundaries_]] .. level .. [[_new (way_ids, relation_ids, admin_level, maritime, disputed, geom)
    SELECT way_ids, relation_ids, admin_level, maritime, disputed, geom
    FROM simplified WHERE ST_Length(geom) > ]] .. c.minlength)

    table.insert(sql, 'ANALYZE {schema}.boundaries_' .. level .. '_new')
    table.insert(sql, 'CREATE INDEX ON {schema}.boundaries_' .. level .. '_new USING GIST (geom)')
    table.insert(sql, 'DROP TABLE {schema}.boundaries_' .. level)
    table.insert(sql, 'ALTER TABLE {schema}.boundaries_' .. level .. '_new RENAME TO boundaries_' .. level)
end

themepark:add_proc('gen', function(data)
    local sql = {
        'CREATE TABLE {schema}.boundaries_new (LIKE {schema}.boundaries INCLUDING IDENTITY)',
        [[
WITH multigeom AS (
SELECT array_agg(way_id ORDER BY way_id) AS way_ids,
    relation_ids,
    min(admin_level) AS admin_level,
    (maritime OR coastline) AS maritime,
    disputed,
    ST_LineMerge(ST_Collect(geom)) AS geom
    FROM {schema}.boundaries_ways_interim
        WHERE closure_segment IS FALSE
        GROUP BY relation_ids, maritime OR coastline, disputed
)
INSERT INTO {schema}.boundaries_new (way_ids, relation_ids, admin_level, maritime, disputed, geom)
SELECT way_ids, relation_ids, admin_level, maritime, disputed, (ST_Dump(geom)).geom AS geom
    FROM multigeom ]],
        'ANALYZE {schema}.boundaries_new',
        'CREATE INDEX ON {schema}.boundaries_new USING GIST (geom)',
        'DROP TABLE {schema}.boundaries',
        'ALTER TABLE {schema}.boundaries_new RENAME TO boundaries'
    }

    gen_commands(sql, 'l');
    gen_commands(sql, 'm');
    gen_commands(sql, 's');

    table.insert(sql, 'TRUNCATE {schema}.expire_boundaries')

    local expanded_sql = {}
    for _, s in ipairs(sql) do
        table.insert(expanded_sql, themepark.expand_template(s))
    end

    osm2pgsql.run_sql({
        description = 'Merge boundary lines for small zoom levels',
        if_has_rows = themepark.expand_template('SELECT 1 FROM {schema}.expire_boundaries LIMIT 1'),
        transaction = true,
        sql = expanded_sql
    })
end)

-- ---------------------------------------------------------------------------
