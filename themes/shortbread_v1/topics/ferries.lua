-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: ferries
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'ferries',
    ids_type = 'way',
    geom = 'linestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'motor_vehicle', type = 'bool' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tags = {
        { key = 'route', value = 'ferry', on = 'w' },
        { key = 'motor_vehicle', on = 'w' },
    },
    tiles = {
        minzoom = 10,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object, data)
    local t = object.tags

    if t.route == 'ferry' then
        local a = {
            kind = 'ferry',
            geom = object:as_linestring()
        }

        if t.motor_vehicle and t.motor_vehicle ~= 'no' then
            a.motor_vehicle = true
            a.minzoom = 10
        else
            a.motor_vehicle = false
            a.minzoom = 12
        end

        themepark.themes.core.add_name(a, object)
        themepark:insert('ferries', a, t)
    end
end)

-- ---------------------------------------------------------------------------
