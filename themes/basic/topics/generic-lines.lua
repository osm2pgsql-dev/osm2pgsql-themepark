-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: generic-lines
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'lines',
    ids = { type = 'way', id_column = 'way_id' },
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object)
    if not object.is_closed or not theme.has_area_tags(object.tags) then
        themepark:insert('lines', {
            geom = object.as_linestring(),
            tags = object.tags
        })
    end
end)

-- ---------------------------------------------------------------------------
