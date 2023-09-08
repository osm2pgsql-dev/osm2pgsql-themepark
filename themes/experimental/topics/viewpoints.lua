-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: viewpoints
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'viewpoints',
    ids_type = 'node',
    geom = 'point',
    columns = themepark:columns('core/name', {
        { column = 'direction', type = 'int' },
        { column = 'ele', type = 'int' },
        { column = 'ele_ft', type = 'int' },
    }),
    tiles = {
        minzoom = 12,
    }
}

local directions = {
    N = 0, north = 0,
    NNE = 22,
    NE = 45,
    ENE = 67,
    E = 90, east = 90,
    ESE = 112,
    SE = 135,
    SSE = 157,
    S = 180, south = 180,
    SSW = 202,
    SW = 225,
    WSW = 247,
    W = 270, west = 270,
    WNW = 292,
    NW = 315,
    NNW = 337
}

themepark:add_proc('node', function(object, data)
    if object.tags.tourism == 'viewpoint' then
        local a = {
            geom = object:as_point()
        }

        themepark.themes.core.add_name(a, object)

        local dbginfo = { direction = object.tags.direction }

        a.ele = data.core.ele_m
        a.ele_ft = data.core.ele_ft

        local d = object.tags.direction
        if d then
            local angle = directions[d]
            if angle then
                a.direction = angle
            elseif d == '0-360' then
                a.direction = nil
            else
                angle = string.match(d, '^(%d+)$')
                if angle then
                    a.direction = angle
                else
                    local from, to = string.match(d, '^(%d+)-(%d+)$')
                    if from ~= nil then
                        from = tonumber(from)
                        to = tonumber(to)
                        if from > to then
                            from = from - 360
                        end
                        a.direction = math.floor((to - from) / 2 + from)
                    end
                end
            end
        end

        themepark:insert('viewpoints', a, object.tags, dbginfo)
    end
end)

-- ---------------------------------------------------------------------------
