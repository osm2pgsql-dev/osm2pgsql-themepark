-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: streets
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'streets',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'link', type = 'bool' },
        { column = 'rail', type = 'bool' },
        { column = 'tunnel', type = 'bool', not_null = true },
        { column = 'bridge', type = 'bool', not_null = true },
        { column = 'oneway', type = 'bool' },
        { column = 'oneway_reverse', type = 'bool' },
        { column = 'tracktype', type = 'text' },
        { column = 'surface', type = 'text' },
        { column = 'service', type = 'text' },
        { column = 'bicycle', type = 'text' },
        { column = 'horse', type = 'text' },
        { column = 'layer', type = 'int', not_null = true },
        { column = 'ref', type = 'text' },
        { column = 'ref_rows', type = 'int' },
        { column = 'ref_cols', type = 'int' },
        { column = 'z_order', type = 'int' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tags = {
        { key = 'aeroway', values = { 'runway', 'taxiway' }, on = 'w' },
        { key = 'bicycle', on = 'w' },
        { key = 'bridge', value = 'yes', on = 'w' },
        { key = 'covered', value = 'yes', on = 'w' },
        { key = 'highway', on = 'w' },
        { key = 'highway', value = 'motorway_junction', on = 'n' },
        { key = 'horse', on = 'w' },
        { key = 'layer', on = 'w' },
        { key = 'railway', on = 'w' },
        { key = 'ref', on = 'w' },
        { key = 'service', on = 'w' },
        { key = 'surface', on = 'w' },
        { key = 'tracktype', on = 'w' },
        { key = 'tunnel', values = { 'yes', 'building_passage' } , on = 'w' },
    },
    tiles = {
        minzoom = 14,
        order_by = 'z_order',
        order_dir = 'asc',
    },
}

-- XXX There is some duplication here, because many of the entries in 'streets'
--     are also in this table.
themepark:add_table{
    name = 'street_labels',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'layer', type = 'int', not_null = true },
        { column = 'ref', type = 'text' },
        { column = 'ref_rows', type = 'int' },
        { column = 'ref_cols', type = 'int' },
        { column = 'z_order', type = 'int' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tiles = {
        minzoom = 14,
        order_by = 'z_order',
        order_dir = 'asc',
    },
}

themepark:add_table{
    name = 'streets_med',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'link', type = 'bool' },
        { column = 'rail', type = 'bool' },
        { column = 'tunnel', type = 'bool', not_null = true },
        { column = 'bridge', type = 'bool', not_null = true },
        { column = 'tracktype', type = 'text' },
        { column = 'surface', type = 'text' },
        { column = 'service', type = 'text' },
        { column = 'layer', type = 'int', not_null = true },
        { column = 'ref', type = 'text' },
        { column = 'ref_rows', type = 'int' },
        { column = 'ref_cols', type = 'int' },
        { column = 'z_order', type = 'int' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tiles = {
        minzoom = 11,
        maxzoom = 13,
        group = 'streets',
        order_by = 'z_order',
        order_dir = 'asc',
    },
}

themepark:add_table{
    name = 'streets_low',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'kind', type = 'text', not_null = true },
        { column = 'ref', type = 'text' },
        { column = 'rail', type = 'bool' },
        { column = 'z_order', type = 'int' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tiles = {
        minzoom = 5,
        maxzoom = 10,
        group = 'streets',
        order_by = 'z_order',
        order_dir = 'asc',
    },
}

themepark:add_table{
    name = 'street_polygons',
    ids_type = 'way',
    geom = 'polygon',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'rail', type = 'bool' },
        { column = 'tunnel', type = 'bool' },
        { column = 'bridge', type = 'bool' },
        { column = 'surface', type = 'text' },
        { column = 'z_order', type = 'int' },
    }),
    tiles = {
        minzoom = 11,
        order_by = 'z_order',
        order_dir = 'desc',
    },
}

themepark:add_table{
    name = 'streets_labels_points',
    ids_type = 'node',
    geom = 'point',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text' },
        { column = 'ref', type = 'text' },
    }),
    tiles = {
        minzoom = 12,
    },
}

-- ---------------------------------------------------------------------------

local Z_STEP = 14

local highway_lookup = {
--  highway tag          z  minzoom
    motorway        = { 10,  5 },
    trunk           = {  9,  6 },
    primary         = {  8,  8 },
    secondary       = {  7,  9 },
    tertiary        = {  6, 10 },

    tertiary_link   = {  5, 12 },
    secondary_link  = {  5, 12 },
    primary_link    = {  5, 12 },
    trunk_link      = {  5, 12 },
    motorway_link   = {  5, 12 },

    unclassified    = {  5, 12 },
    residential     = {  5, 12 },
    busway          = {  5, 12 },
    busway_guideway = {  5, 12 },
    road            = {  5, 12 },

    living_street   = {  4, 13 },
    pedestrian      = {  4, 13 },
    service         = {  3, 13 },

    track           = {  2, 13 },
    footway         = {  2, 13 },
    path            = {  2, 13 },
    cycleway        = {  2, 13 },
    bridleway       = {  2, 13 },

    steps           = {  1, 13 },
    platform        = {  1, 13 },
}

local railway_lookup = {
    rail            = { 12,  8 },
    narrow_gauge    = { 11,  8 },
    tram            = { 11, 10 },
    light_rail      = { 11, 10 },
    funicular       = { 11, 10 },
    subway          = { 11, 10 },
    monorail        = { 11, 10 },
}

local aeroway_lookup = {
    runway  = 11,
    taxiway = 13,
}

local as_bool = function(value)
    return value == 'yes' or value == 'true' or value == '1'
end

local set_ref_attributes = function(a, t)
    if not t.ref then
        return
    end

    local refs = {}
    local rows = 0
    local cols = 0

    for word in string.gmatch(t.ref, "([^;]+);?") do
        rows = rows + 1
        cols = math.max(cols, string.len(word))
        table.insert(refs, word)
    end

    a.ref = table.concat(refs, '\n')
    a.ref_rows = rows
    a.ref_cols = cols
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object, data)
    local t = object.tags

    if t.highway and t.highway == 'motorway_junction' then
        local a = {
            kind = t.highway,
            ref = t.ref,
            geom = object:as_point()
        }
        themepark.themes.core.add_name(a, object)
        themepark:add_debug_info(a, t)
        themepark:insert('streets_labels_points', a)
    end
end)

local process_as_area = function(object, data)
    if not object.is_closed then
        return
    end

    local t = object.tags
    local a = {
        layer = data.core.layer,
    }
    a.z_order = Z_STEP * a.layer

    if t.highway == 'pedestrian' or t.highway == 'service' then
        a.kind = t.highway
    elseif t.aeroway == 'runway' or t.aeroway == 'taxiway' then
        a.kind = t.aeroway
    else
        return
    end

    a.surface = t.surface

    if as_bool(t.tunnel) or t.tunnel == 'building_passage' or t.covered == 'yes' then
        a.tunnel = true
        a.z_order = a.z_order - Z_STEP
    else
        a.tunnel = false
    end

    if as_bool(t.bridge) then
        a.bridge = true
        a.z_order = a.z_order + Z_STEP
    else
        a.bridge = false
    end

    a.geom = object:as_polygon()

    themepark.themes.core.add_name(a, object)
    themepark:add_debug_info(a, t)
    themepark:insert('street_polygons', a)
end

themepark:add_proc('way', function(object, data)
    local t = object.tags
    if t.area == 'yes' then
        process_as_area(object, data)
        return
    end

    local a = {
        oneway = false,
        oneway_reverse = false,
        layer = data.core.layer,
        rail = false
    }

    if t.highway then
        local hwinfo = highway_lookup[t.highway]
        if not hwinfo then
            return
        end

        local kind, num = string.gsub(t.highway, '_link$', '')
        if num > 0 then
            a.kind = kind
            a.link = true
        else
            a.kind = t.highway
            a.link = false
        end

        if t.oneway == 'yes' or t.oneway == '1' or t.oneway == 'true' then
            a.oneway = true
            a.oneway_reverse = false
        elseif t.oneway == '-1' then
            a.oneway = true
            a.oneway_reverse = true
        end

        if a.kind == 'track' then
            a.tracktype = t.tracktype
        end

        a.surface = t.surface
        a.service = t.service
        a.bicycle = t.bicycle
        a.horse = t.horse

        a.z_order = Z_STEP * a.layer + hwinfo[1]
        a.minzoom = hwinfo[2]
    elseif t.railway then
        local rwinfo = railway_lookup[t.railway]
        if not rwinfo then
            return
        end
        a.kind = t.railway
        a.rail = true
        a.service = t.service
        a.z_order = Z_STEP * a.layer + rwinfo[1]
        a.minzoom = rwinfo[2]
        if a.minzoom == 8 and t.service then
            a.minzoom = 10
            a.z_order = a.z_order + 1
        end
    elseif t.aeroway then
        local awinfo = aeroway_lookup[t.aeroway]
        if not awinfo then
            return
        end
        a.kind = t.aeroway
        a.z_order = Z_STEP * a.layer
        a.minzoom = awinfo
    else
        return
    end

    if as_bool(t.tunnel) or t.tunnel == 'building_passage' or t.covered == 'yes' then
        a.tunnel = true
        a.z_order = a.z_order - Z_STEP
    else
        a.tunnel = false
    end

    if as_bool(t.bridge) then
        a.bridge = true
        a.z_order = a.z_order + Z_STEP
    else
        a.bridge = false
    end

    set_ref_attributes(a, t)

    a.geom = object:as_linestring()

    themepark.themes.core.add_name(a, object)
    themepark:add_debug_info(a, t)

    themepark:insert('streets', a)

    if a.name or a.ref then
        themepark:insert('street_labels', a)
    end

    if a.minzoom < 13 then -- XXX TODO some kind of off-by-one error here?
        themepark:insert('streets_med', a)
    end
    if a.minzoom < 10 then -- XXX TODO some kind of off-by-one error here?
        themepark:insert('streets_low', a)
    end
end)

-- ---------------------------------------------------------------------------
