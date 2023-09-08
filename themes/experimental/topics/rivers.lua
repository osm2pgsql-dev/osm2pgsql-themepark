-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: rivers
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'rivers',
    ids_type = 'relation',
    geom = 'multilinestring',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text' },
    }),
    tiles = {
        minzoom = 5,
    },
}

-- ---------------------------------------------------------------------------

themepark:add_proc('relation', function(object, data)
    local t = object.tags

    if not t.type or t.type ~= 'waterway' then
        return
    end

    if not (t.waterway and (t.type == 'river' or t.type == 'canal')) then
        return
    end

    local a = {
        kind = t.waterway
    }

    a.geom = object.as_multilinestring()
    themepark.themes.core.add_name(a, object)
    themepark:insert('rivers', a, t)
end)

-- ---------------------------------------------------------------------------
