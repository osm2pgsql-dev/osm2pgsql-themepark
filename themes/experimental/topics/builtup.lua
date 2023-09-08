-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: builtup
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'builtup_src',
    ids_type = 'area',
    geom = 'polygon',
    tiles = false,
}

themepark:add_table{
    name = 'roads_src',
    ids_type = 'way',
    geom = 'linestring',
    tiles = false,
}

themepark:add_table{
    name = 'builtup',
    geom = 'polygon',
    ids_type = 'tile',
    columns = themepark:columns({
        { column = 'id', sql_type = 'serial' },
        { column = 'area', type = 'real' },
    }),
    tiles = false,
}

-- ---------------------------------------------------------------------------

local is_builtup_landuse = osm2pgsql.make_check_values_func(
    { 'residential', 'industrial', 'commercial', 'retail',
      'village_green', 'garages' })

local is_builtup_leisure = osm2pgsql.make_check_values_func(
    { 'pitch', 'park', 'playground', 'sports_centre', 'stadium' })

local is_builtup_amenity = osm2pgsql.make_check_values_func(
    { 'hospital', 'police', 'university' })

local is_highway = osm2pgsql.make_check_values_func(
    { 'primary', 'secondary', 'tertiary',
      'primary_link', 'secondary_link', 'tertiary_link',
      'service', 'residential', 'pedestrian' })

local is_built_area = function(tags)
    if is_builtup_landuse(tags.landuse) then
        return true
    end
    if is_builtup_leisure(tags.leisure) then
        return true
    end
    if is_builtup_amenity(tags.amenity) then
        return true
    end
    if tags.military == 'barracks' then
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------

themepark:add_proc('way', function(object, data)
    if object.is_closed then
        return
    end
    local hw = object.tags.highway
    if is_highway(hw) then
        themepark:insert('roads_src', {
            geom = object:as_linestring()
        })
    end
end)

themepark:add_proc('area', function(object, data)
    if is_built_area(object.tags) then
        local geom = object:as_area()
        for g in geom:geometries() do
            themepark:insert('builtup_src', {
                geom = g
            })
        end
    end
end)

themepark:add_proc('gen', function(data)
    osm2pgsql.run_gen('builtup', {
        name = 'builtup',
        debug = false,
        src_table = 'builtup_src',
        src_tables = 'builtup_src,buildings,roads_src',
        dest_table = 'builtup',
        image_extent = 2048,
        image_buffer = 0,
        min_area = 0.0,
        margin = 0,
        buffer_size = '10,2,6',
        turdsize = 1024,
        zoom = 9,
        make_valid = true,
        area_column = 'area'
    })
end)

-- ---------------------------------------------------------------------------
