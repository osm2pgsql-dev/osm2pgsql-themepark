-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: information
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'information',
    ids_type = 'node',
    geom = 'point',
    columns = themepark:columns({
        { column = 'class', type = 'text' },
        { column = 'name', type = 'text' },
    }),
    tiles = {
        minzoom = 12,
    }
}

themepark:add_proc('node', function(object, data)
    local a = {
        geom = object:as_point(),
        name = object.tags.name
    }

    if object.tags.tourism == 'information' then
        a.class = object.tags.information

        if a.class then
            local dbginfo = { operator = object.tags.operator }
            themepark:insert('information', a, object.tags, dbginfo)
        end
    end
end)

-- ---------------------------------------------------------------------------
