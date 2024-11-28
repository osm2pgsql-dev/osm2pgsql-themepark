-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: boundaries
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'boundaries',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'admin_level', type = 'int', not_null = true },
        { column = 'maritime', type = 'bool' },
        { column = 'disputed', type = 'bool' },
    }),
    tags = {
        { key = 'admin_level', values = { '2', '4' }, on = 'r' },
        { key = 'boundary', values = { 'administrative', 'disputed' }, on = 'r' },
        { key = 'disputed', value = 'yes', on = 'w' },
        { key = 'maritime', value = 'yes', on = 'w' },
        { key = 'natural', value = 'coastline', on = 'w' },
        { key = 'type', value = 'boundary', on = 'r' },
    },
    tiles = {
        minzoom = 2
    }
}

-- ---------------------------------------------------------------------------
-- Storage of information from boundary relations for use by boundary ways
-- (two-stage processing).

-- Minimum admin level of all relations that reference a way id
local min_admin_level = {}

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

    local admin_level = min_admin_level[object.id]
    if not admin_level then
        return
    end

    local t = object.tags

    -- Set disputed flag either from disputed tag on the way...
    local disputed = (t.disputed == 'yes')

    -- .. or from a parent relation with boundary=disputed
    if min_disputed_admin_level[object.id] and min_disputed_admin_level[object.id] <= admin_level then
        disputed = true
    end

    local a = {
        admin_level = admin_level,
        maritime = (t.maritime and (t.maritime == 'yes' or t.natural == 'coastline')),
        disputed = disputed,
        geom = object:as_linestring()
    }

    themepark:insert('boundaries', a, t)
end)

themepark:add_proc('select_relation_members', function(relation)
    if is_admin_boundary(relation.tags) then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end)

themepark:add_proc('relation', function(object, data)
    if is_admin_boundary(object.tags) then
        local admin_level = tonumber(object.tags.admin_level)

        for _, id in ipairs(osm2pgsql.way_member_ids(object)) do
            if not min_admin_level[id] or min_admin_level[id] > admin_level then
                min_admin_level[id] = admin_level
            end
        end

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

-- ---------------------------------------------------------------------------
