-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: generic-points
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'points',
    ids = { type = 'node', id_column = 'node_id' },
    geom = 'point',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object)
    themepark:insert('points', {
        geom = object.as_point(),
        tags = object.tags
    })
end)

-- ---------------------------------------------------------------------------
