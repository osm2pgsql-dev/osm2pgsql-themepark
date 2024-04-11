-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: generic-routes
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'routes',
    ids = { type = 'relation', id_column = 'relation_id' },
    geom = 'multilinestring',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('relation', function(object)
    if object.tags.type == 'route' then
        themepark:insert('routes', {
            geom = object:as_multilinestring(),
            tags = object.tags
        })
    end
end)

-- ---------------------------------------------------------------------------
