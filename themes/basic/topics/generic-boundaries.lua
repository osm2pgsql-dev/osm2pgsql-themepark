-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: generic-boundaries
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'boundaries',
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
    if object.tags.type == 'boundary' or (object.tags.type == 'multipolygon' and object.tags.boundary) then
        themepark:insert('boundaries', {
            geom = object.as_multilinestring(),
            tags = object.tags
        })
    end
end)

-- ---------------------------------------------------------------------------
