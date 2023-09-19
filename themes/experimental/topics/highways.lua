-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: highways
--
-- Osmium Prefilter: w/highway
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table({
    name = 'highways',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'tunnel', type = 'bool', not_null = true },
        { column = 'bridge', type = 'bool', not_null = true },
        { column = 'oneway', type = 'bool' },
        { column = 'oneway_reverse', type = 'bool' },
        { column = 'tracktype', type = 'text' },
        { column = 'surface', type = 'text' },
        { column = 'access', type = 'text' },
        { column = 'foot', type = 'text' },
        { column = 'bicycle', type = 'text' },
        { column = 'horse', type = 'text' },
        { column = 'layer', type = 'int', not_null = true },
        { column = 'area_id', type = 'int8', create_only = true },
    }),
})

local as_bool = function(value)
    return value == 'yes' or value == 'true' or value == '1'
end

themepark:add_proc('way', function(object, data)
    local t = object.tags
    if t.highway then
        local a = {
            kind = t.highway,
            tunnel = as_bool(t.tunnel) or t.tunnel == 'building_passage' or t.covered == 'yes',
            bridge = as_bool(t.bridge),
            oneway = false,
            oneway_reverse = false,
            tracktype = t.tracktype,
            surface = t.surface,
            access = t.access,
            foot = t.foot,
            bicycle = t.bicycle,
            horse = t.horse,
            layer = data.core.layer,
            geom = object:as_linestring()
        }

        if t.oneway == 'yes' or t.oneway == '1' or t.oneway == 'true' then
            a.oneway = true
        elseif t.oneway == '-1' then
            a.oneway = true
            a.oneway_reverse = true
        end

        themepark.themes.core.add_name(a, object)

        themepark:insert('highways', a, t)
    end
end)

-- ---------------------------------------------------------------------------
