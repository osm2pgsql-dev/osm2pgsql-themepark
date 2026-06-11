-- ---------------------------------------------------------------------------
--
-- Theme: external
-- Topic: coastlines
--
-- ---------------------------------------------------------------------------

return function(themepark, theme, cfg)

local name = cfg.name or 'coastlines'

local tags = { { key = 'natural', value = 'coastline', on = 'w' } }

themepark:add_table{
    external = true,
    name = name,
    geom = 'linestring',
    columns = themepark:columns({}),
    tags = tags,
}

end

-- ---------------------------------------------------------------------------
