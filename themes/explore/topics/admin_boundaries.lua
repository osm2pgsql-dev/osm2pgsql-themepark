-- ---------------------------------------------------------------------------
--
-- Theme: explore
-- Topic: admin_boundaries
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table({
    name = 'admin_boundaries_ways',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'admin_level', type = 'int' },
        { column = 'min_admin_level', type = 'int' },
        { column = 'border_type', type = 'text' },
        { column = 'maritime', type = 'bool' },
        { column = 'coastline', type = 'bool' },
        { column = 'disputed_on_way', type = 'text' },
        { column = 'disputed', type = 'bool' },
        { column = 'is_rel_member', type = 'bool' },
    }),
})


themepark:add_table({
    name = 'admin_boundaries_relations',
    ids_type = 'relation',
    geom = 'multilinestring',
    columns = themepark:columns({
        { column = 'admin_level', type = 'int' },
        { column = 'type', type = 'text' },
        { column = 'border_type', type = 'text' },
        { column = 'wikidata', type = 'text' },
        { column = 'maritime', type = 'bool' },
        { column = 'disputed', type = 'bool' },
    }),
})

themepark:add_table({
    name = 'admin_boundaries_areas',
    ids_type = 'relation',
    geom = 'multipolygon',
    columns = themepark:columns({
        { column = 'admin_level', type = 'int' },
        { column = 'type', type = 'text' },
        { column = 'border_type', type = 'text' },
        { column = 'wikidata', type = 'text' },
        { column = 'maritime', type = 'bool' },
        { column = 'disputed', type = 'bool' },
    }),
})

themepark:add_table({
    name = 'admin_boundaries_errors',
    ids_type = 'any',
    geom = 'multilinestring',
    columns = {
        { column = 'errormsg', type = 'text', not_null = true },
        { column = 'value', type = 'text' },
    },
})

-- ---------------------------------------------------------------------------
-- Storage of information from boundary relations for use by boundary ways
-- (two-stage processing).

-- Minimum admin level of all relations that reference a way id
local min_admin_level = {}

-- Minimum admin level of all relations tagged boundary=disputed that
-- reference a way id
local min_disputed_admin_level = {}

-- ---------------------------------------------------------------------------

-- Get numerical admin level from string
local function get_admin_level(value)
    if not value or not string.match(value, '^[1-9][0-9]?$') then
        return nil
    end

    return tonumber(value)
end

local function add_error(msg, value, geom, tags)
    themepark:insert('admin_boundaries_errors', {
        errormsg = msg,
        value = value,
        geom = geom,
    }, tags)
end

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object, data)
    local t = object.tags

    if osm2pgsql.stage == 1 and not (t.boundary == 'administrative' or t.boundary == 'disputed') then
        return
    end

    local min_admin_level_from_rels = min_admin_level[object.id] or 1

    -- Set disputed flag either from disputed or boundary tag on the way...
    local disputed = (t.disputed == 'yes' or t.boundary == 'disputed')

    -- .. or from a parent relation with boundary=disputed
    if osm2pgsql.stage == 2
        and min_disputed_admin_level[object.id]
        and min_disputed_admin_level[object.id] <= min_admin_level_from_rels then
        disputed = true
    end

    local a = {
        admin_level = t.admin_level,
        border_type = t.border_type,
        maritime = (t.maritime == 'yes'),
        coastline = (t.natural == 'coastline'),
        disputed_on_way = t.disputed,
        disputed = disputed,
        min_admin_level = min_admin_level_from_rels,
        is_rel_member = (osm2pgsql.stage == 2),
        geom = object:as_linestring(),
    }

    themepark:insert('admin_boundaries_ways', a, t)
end)

themepark:add_proc('select_relation_members', function(relation)
    if relation.tags.boundary == 'administrative' then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags

    if t.boundary ~= 'administrative' and t.boundary ~= 'disputed' then
        return
    end

    local admin_level = t.admin_level
    local numeric_admin_level = get_admin_level(admin_level)

    local geom_multilinestring = object:as_multilinestring()
    local geom_multipolygon = object:as_multipolygon()

    if t.type ~= 'boundary' and t.type ~= 'multipolygon' then
        add_error('missing type tag', nil, geom_multilinestring, t)
    end

    if t.boundary == 'administrative' and geom_multipolygon:is_null() then
        add_error('not a (multi)polygon', nil, geom_multilinestring, t)
    end

    if numeric_admin_level == nil then
        add_error('invalid admin level (not set or not number)', t.admin_level, geom_multilinestring, t)
    elseif numeric_admin_level < 2 or numeric_admin_level > 11 then
        add_error('admin level not between 2 and 11', t.admin_level, geom_multilinestring, t)
    end

    if t.maritime and t.maritime ~= 'yes' then
        add_error('invalid maritime tag value', t.maritime, geom_multilinestring, t)
    end

    local a = {
        admin_level = numeric_admin_level,
        type = t.type,
        border_type = t.border_type,
        wikidata = t.wikidata,
        maritime = (t.maritime == 'yes'),
        disputed = (t.boundary == 'disputed'),
    }

    if geom_multipolygon:is_null() then
        a.geom = geom_multilinestring
        themepark:insert('admin_boundaries_relations', a, t)
    else
        a.geom = geom_multipolygon
        themepark:insert('admin_boundaries_areas', a, t)
    end

    if numeric_admin_level == nil then
        return
    end

    if t.boundary == 'administrative' then
        for _, id in ipairs(osm2pgsql.way_member_ids(object)) do
            if not min_admin_level[id] or min_admin_level[id] > numeric_admin_level then
                min_admin_level[id] = numeric_admin_level
            end
        end
    elseif t.boundary == 'disputed' then
        -- Ways in relations tagged boundary=disputed are flagged as disputed
        -- if either the relation doesn't have an admin_level tag or the
        -- admin_level tag is <= the admin level the way got from the
        -- boundary=administrative relation(s).
        for _, id in ipairs(osm2pgsql.way_member_ids(object)) do
            if not min_disputed_admin_level[id] or min_disputed_admin_level[id] > numeric_admin_level then
                min_disputed_admin_level[id] = numeric_admin_level
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
