-- ---------------------------------------------------------------------------
--
-- Theme: basic
-- Topic: nwr
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'nodes',
    ids = { type = 'node', id_column = 'node_id' },
    geom = 'point',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    },
}

themepark:add_table{
    name = 'ways',
    ids = { type = 'way', id_column = 'way_id' },
    geom = 'linestring',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
        { column = 'nodes', type = 'text', sql_type = 'int8[]' }
    }),
    tiles = {
        minzoom = 8,
    }
}

themepark:add_table{
    name = 'relations',
    ids = { type = 'relation', id_column = 'relation_id' },
    geom = 'geometry',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
        { column = 'members', type = 'jsonb' }
    }),
    tiles = {
        minzoom = 8,
    }
}

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object)
    themepark:insert('nodes', {
        geom = object.as_point(),
        tags = object.tags
    })
end)

themepark:add_proc('way', function(object)
    themepark:insert('ways', {
        geom = object.as_linestring(),
        tags = object.tags,
        nodes = '{' .. table.concat(object.nodes, ',') .. '}'
    })
end)

themepark:add_proc('relation', function(object)
    themepark:insert('relations', {
        geom = object.as_geometrycollection(),
        tags = object.tags,
        members = object.members
    })
end)

-- ---------------------------------------------------------------------------
