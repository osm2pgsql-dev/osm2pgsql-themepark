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
    columns = themepark:columns('core/name', {
        { column = 'admin_level', type = 'int' },
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

    local t = object.tags
    local a = {
        admin_level = info.admin_level,
        maritime = (t.maritime and (t.maritime == 'yes' or t.natural == 'coastline')),
        disputed = info.disputed or (t.disputed and t.disputed == 'yes'),
        geom = object:as_linestring()
    }
    themepark.themes.core.add_name(a, object)
    themepark:insert('boundaries', a, t)
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
                rinfos[member.ref] = { admin_level = admin_level }
            elseif rinfos[member.ref].admin_level > admin_level then
                rinfos[member.ref].admin_level = admin_level
            end
            rinfos[member.ref].disputed = (t.boundary == 'disputed')
        end
    end
end)

-- ---------------------------------------------------------------------------
