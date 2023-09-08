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

themepark:add_proc('way', function(object, data)
    if osm2pgsql.stage == 1 then
        return
    end

    local t = object.tags
    local info = rinfos[object.id]
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
    local t = relation.tags
    -- Only interested in relations with type=boundary, boundary=administrative
    if t.type == 'boundary' and t.boundary == 'administrative'
       and (t.admin_level == '2' or t.admin_level == '4') then
        return { ways = osm2pgsql.way_member_ids(relation) }
    end
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags
    if t.type ~= 'boundary' then
        return
    end

    if (t.boundary == 'administrative' or t.boundary == 'disputed')
       and (t.admin_level == '2' or t.admin_level == '4') then
        local admin_level = tonumber(t.admin_level)
        for _, member in ipairs(object.members) do
            if member.type == 'w' then
                if not rinfos[member.ref] then
                    rinfos[member.ref] = { admin_level = admin_level }
                elseif rinfos[member.ref].admin_level > admin_level then
                    rinfos[member.ref].admin_level = admin_level
                end
                rinfos[member.ref].disputed = t.boundary == 'disputed'
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
