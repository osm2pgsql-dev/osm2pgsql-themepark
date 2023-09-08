-- ---------------------------------------------------------------------------
--
-- Theme: external
-- Topic: continents
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local name = cfg.name or 'continents'

local tags = { { key = 'natural', value = 'coastline', on = 'w' } }

themepark:add_table{
    external = true,
    name = name,
    geom = 'polygon',
    columns = themepark:columns({}),
    tags = tags,
    tiles = {
        minzoom = 10
    }
}

themepark:add_table{
    external = true,
    name = name .. '_low',
    geom = 'polygon',
    columns = themepark:columns({}),
    tags = tags,
    tiles = {
        group = name,
        minzoom = 0,
        maxzoom = 9
    }
}

-- ---------------------------------------------------------------------------
