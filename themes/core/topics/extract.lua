-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: extract
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- ---------------------------------------------------------------------------

local locator

if cfg.locator == nil then
    locator = osm2pgsql.define_locator({
        name = 'themepark-core-extract-' .. math.random(100000000)
    })
else
    locator = cfg.locator
end

if cfg.bbox ~= nil then
    local b = cfg.bbox
    locator:add_bbox('inside', b[1], b[2], b[3], b[4])
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object)
    if not locator:first_intersecting(object:as_point()) then
        return 'stop'
    end
end)

themepark:add_proc('way', function(object)
    local geom
    if object.is_closed then
        geom = object:as_polygon()
    end

    if geom == nil or geom:is_null() then
        geom = object:as_linestring()
    end

    if not locator:first_intersecting(geom) then
        return 'stop'
    end
end)

themepark:add_proc('relation', function(object)
    local geom = object:as_multipolygon()

    if geom:is_null() then
        geom = object:as_geometrycollection()
    end

    if geom:is_null() then
        return 'stop'
    end

    if not locator:first_intersecting(geom) then
        return 'stop'
    end
end)

-- ---------------------------------------------------------------------------
