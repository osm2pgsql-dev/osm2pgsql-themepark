-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: generic-polygons
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'polygons',
    ids = { type = 'area', id_column = 'area_id' },
    geom = 'geometry', -- needs to support polygon and multipolygon
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object)
    if object.is_closed and theme.has_area_tags(object.tags) then
        themepark:insert('polygons', {
            geom = object:as_polygon(),
            tags = object.tags
        })
    end
end)

themepark:add_proc('relation', function(object)
    if themepark:relation_is_area(object) then
        themepark:insert('polygons', {
            geom = object:as_multipolygon(),
            tags = object.tags
        })
    end
end)

-- ---------------------------------------------------------------------------
