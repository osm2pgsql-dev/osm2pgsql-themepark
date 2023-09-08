-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1_gen
-- Topic: land
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- ---------------------------------------------------------------------------

local gen_zoom_levels = { 6, 7, 8, 9, 10, 11 }

-- ---------------------------------------------------------------------------

local expire_outputs = {}
for _, zoom in ipairs(gen_zoom_levels) do
    expire_outputs[zoom] = osm2pgsql.define_expire_output({
        maxzoom = zoom,
        table = 'expire_land_z' .. zoom
    })

    themepark:add_table{
        name = 'land_z' .. zoom,
        ids_type = 'tile',
        geom = 'polygon',
        columns = themepark:columns({
            { column = 'kind', type = 'text' },
        }),
        tiles = {
            minzoom = zoom,
            maxzoom = zoom,
            xycondition = true,
            group = 'land',
        },
    }
end

themepark:add_table{
    name = 'land',
    ids_type = 'area',
    geom = 'multipolygon',
    expire = {
        { output = expire_outputs[6] },
        { output = expire_outputs[7] },
        { output = expire_outputs[8] },
        { output = expire_outputs[9] },
        { output = expire_outputs[10] },
        { output = expire_outputs[11] },
    },
    columns = themepark:columns({
        { column = 'kind', type = 'text', not_null = true },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
    }),
    tiles = {
        buffer_size = 1,
        make_valid = true,
        minzoom = 12,
        simplify = true,
    }
}

-- ---------------------------------------------------------------------------

local landuse_lookup = {
    forest = 7,
    grass = 11,
    meadow = 11,
    orchard = 11,
    vineyard = 11,
    allotments = 11,
    cemetery = 13,

    village_green = 11,
    recreation_ground = 11,
    greenhouse_horticulture = 11,
    plant_nursery = 11,

    residential = 10,
    industrial = 10,
    commercial = 10,
    garages = 10,
    retail = 10,
    railway = 10,
    landfill = 10,

    quarry = 11,

    brownfield = 10,
    greenfield = 10,
    farmyard = 10,
    farmland = 10,
}

local natural_lookup = {
    sand = 10,
    beach = 10,
    heath = 11,
    scrub = 11,
    grassland = 11,
    bare_rock = 11,
    scree = 11,
    shingle = 11,
}

local check_wetland = osm2pgsql.make_check_values_func({
    'swamp', 'bog', 'string_bog', 'wet_meadow', 'marsh'
})

local check_leisure = osm2pgsql.make_check_values_func({
    'golf_course', 'park', 'garden', 'playground', 'miniature_golf'
})

-- ---------------------------------------------------------------------------

themepark:add_proc('area', function(object, data)
    local t = object.tags
    local a = { geom = object.as_area() }

    local minzoom = landuse_lookup[t.landuse]
    if minzoom then
        a.kind = t.landuse
        a.minzoom = minzoom
    elseif t.natural == 'wood' then
        a.kind = 'forest'
        a.minzoom = 7
    elseif t.amenity == 'grave_yard' then
        a.kind = 'grave_yard'
        a.minzoom = 13
    else
        minzoom = natural_lookup[t.natural]
        if minzoom then
            a.kind = t.natural
            a.minzoom = minzoom
        else
            local wetland = check_wetland(t.wetland)
            if wetland then
                a.kind = wetland
                a.minzoom = 11
            else
                local leisure = check_leisure(t.leisure)
                if leisure then
                    a.kind = leisure
                    a.minzoom = 11
                end
            end
        end
    end

    if a.kind then
        themepark:insert('land', a, t)
    end
end)

-- ---------------------------------------------------------------------------

themepark:add_proc('gen', function(data)
    local zoom_to_condition = {
        [ 6] = "kind IN ('forest', 'bare_rock' )",
        [ 7] = "kind IN ('forest', 'bare_rock' )",
        [ 8] = "kind IN ('forest', 'bare_rock' )",
        [ 9] = "kind IN ('forest', 'bare_rock' )",
        [10] = "kind IN ('forest', 'bare_rock', 'sand', 'beach', "
               .. "'residential', 'industrial', 'commercial', 'garages', "
               .. "'retail', 'railway', 'landfill', 'brownfield', "
               .. "'greenfield', 'farmyard', 'farmland')",
        [11] = "kind NOT IN ('cemetery', 'grave_yard')",
    }
    for _, zoom in ipairs(gen_zoom_levels) do
        osm2pgsql.run_gen('raster-union', {
            schema = themepark.options.schema,
            name = 'land_z' .. zoom,
            debug = false,
            src_table = 'land',
            dest_table = 'land_z' .. zoom,
            zoom = zoom,
            geom_column = 'geom',
            group_by_column = 'kind',
            image_extent = 4096,
            margin = 0.05,
            turdsize = 100,
            make_valid = true,
            where = zoom_to_condition[zoom],
            expire_list = 'expire_land_z' .. zoom
        })
    end
end)

-- ---------------------------------------------------------------------------
