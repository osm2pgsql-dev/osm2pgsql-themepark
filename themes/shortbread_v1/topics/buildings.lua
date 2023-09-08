-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: buildings
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'buildings',
    ids_type = 'area',
    geom = 'polygon',
    columns = themepark:columns({
    }),
    tags = {
        { key = 'building', on = 'a' },
    },
    tiles = {
        minzoom = 14,
        simplify = false,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('area', function(object, data)
    local t = object.tags

    if t.building and t.building ~= 'no' then
        for sgeom in object.as_area():geometries() do
            local a = { geom = sgeom }
            themepark:insert('buildings', a, t)
        end
    end
end)

-- ---------------------------------------------------------------------------
