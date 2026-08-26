-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: pois
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'pois',
    ids_type = 'any',
    geom = 'point',
    columns = themepark:columns('core/name', {
        { column = 'amenity', type = 'text' },
        { column = 'leisure', type = 'text' },
        { column = 'tourism', type = 'text' },
        { column = 'shop', type = 'text' },
        { column = 'man_made', type = 'text' },
        { column = 'historic', type = 'text' },
        { column = 'emergency', type = 'text' },
        { column = 'highway', type = 'text' },
        { column = 'office', type = 'text' },
        { column = 'housename', type = 'text' },
        { column = 'housenumber', type = 'text' },
        { column = 'cuisine', type = 'text' },
        { column = 'sport', type = 'text' },
        { column = 'vending', type = 'text' },
        { column = 'information', type = 'text' },
        { column = 'tower:type', type = 'text' },
        { column = 'religion', type = 'text' },
        { column = 'denomination', type = 'text' },
        { column = 'recycling:glass_bottles', type = 'bool' },
        { column = 'recycling:paper', type = 'bool' },
        { column = 'recycling:clothes', type = 'bool' },
        { column = 'recycling:scrap_metal', type = 'bool' },
        { column = 'atm', type = 'bool' },
    }),
    tags = {
        { key = 'amenity' },
        { key = 'emergency' },
        { key = 'highway' },
        { key = 'historic' },
        { key = 'leisure' },
        { key = 'man_made' },
        { key = 'office' },
        { key = 'shop' },
        { key = 'tourism' },
        { key = 'addr:housename' },
        { key = 'addr:housenumber' },
        { key = 'cuisine' },
        { key = 'sport' },
        { key = 'vending' },
        { key = 'information' },
        { key = 'tower:type' },
        { key = 'religion' },
        { key = 'denomination' },
        { key = 'recycling:glass_bottles' },
        { key = 'recycling:paper' },
        { key = 'recycling:clothes' },
        { key = 'recycling:scrap_metal' },
        { key = 'atm' },
    },
    tiles = {
        minzoom = 14,
    },
}

-- ---------------------------------------------------------------------------

local get_value = {}

get_value.amenity = osm2pgsql.make_check_values_func({
    'arts_centre',
    'atm',
    'bank',
    'bar',
    'bench',
    'bicycle_rental',
    'biergarten',
    'cafe',
    'car_rental',
    'car_sharing',
    'car_wash',
    'cinema',
    'clinic',
    'college',
    'community_centre',
    'courthouse',
    'dentist',
    'doctors',
    'drinking_water',
    'embassy',
    'fast_food',
    'fire_station',
    'food_court',
    'fountain',
    'fuel',
    'grave_yard',
    'hospital',
    'hunting_stand',
    'library',
    'marketplace',
    'nightclub',
    'nursing_home',
    'pharmacy',
    'place_of_worship',
    'police',
    'post_box',
    'post_office',
    'prison',
    'pub',
    'public_building',
    'recycling',
    'restaurant',
    'school',
    'shelter',
    'telephone',
    'theatre',
    'toilets',
    'townhall',
    'university',
    'vending_machine',
    'veterinary',
    'waste_basket',
})

get_value.emergency = osm2pgsql.make_check_values_func({
    'defibrillator',
    'fire_hydrant',
    'phone',
})

get_value.highway = osm2pgsql.make_check_values_func({
    'emergency_access_point'
})

get_value.historic = osm2pgsql.make_check_values_func({
    'archaelogical_site',
    'battlefield',
    'castle',
    'fort',
    'memorial',
    'monument',
    'ruins',
    'wayside_cross',
    'wayside_shrine',
})

get_value.leisure = osm2pgsql.make_check_values_func({
    'dog_park',
    'golf_course',
    'ice_rink',
    'park',
    'pitch',
    'playground',
    'sports_centre',
    'stadium',
    'swimming_pool',
    'water_park',
})

get_value.man_made = osm2pgsql.make_check_values_func({
    'lighthouse',
    'surveillance',
    'tower',
    'wastewater_plant',
    'water_well',
    'water_works',
    'watermill',
    'windmill',
})

get_value.office = osm2pgsql.make_check_values_func({
    'diplomatic'
})

get_value.shop = osm2pgsql.make_check_values_func({
    'alcohol',
    'bakery',
    'beauty',
    'beverages',
    'bicycle',
    'books',
    'butcher',
    'car',
    'chemist',
    'clothes',
    'computer',
    'convenience',
    'department_store',
    'doityourself',
    'dry_cleaning',
    'florist',
    'furniture',
    'garden_centre',
    'general',
    'gift',
    'greengrocer',
    'hairdresser',
    'hardware',
    'jewelry',
    'kiosk',
    'laundry',
    'mall',
    'mobile_phone',
    'newsagent',
    'optician',
    'outdoor',
    'shoes',
    'sports',
    'stationery',
    'supermarket',
    'toys',
    'travel_agency',
    'video',
})

get_value.tourism = osm2pgsql.make_check_values_func({
    'alpine_hut',
    'artwork',
    'bed_and_breakfast',
    'camp_site',
    'caravan_site',
    'chalet',
    'guest_house',
    'hostel',
    'hotel',
    'information',
    'motel',
    'picnic_site',
    'theme_park',
    'viewpoint',
    'zoo',
})

-- ---------------------------------------------------------------------------

local add_extra_attributes = {}

add_extra_attributes.amenity = function(a, t)
    if t.amenity == 'vending_machine' then
        a.vending = t.vending
    elseif t.amenity == 'place_of_worship' then
        a.religion = t.religion
        a.denomination = t.denomination
    elseif t.amenity == 'restaurant' or t.amenity == 'fast_food' or
           t.amenity == 'pub' or t.amenity == 'bar' or t.amenity == 'cafe' then
        a.cuisine = t.cuisine
    elseif t.amenity == 'recycling' then
        a['recycling:glass_bottles'] = t['recycling:glass_bottles'] == 'yes'
        a['recycling:paper'] = t['recycling:paper'] == 'yes'
        a['recycling:clothes'] = t['recycling:clothes'] == 'yes'
        a['recycling:scrap_metal'] = t['recycling:scrap_metal'] == 'yes'
    elseif t.amenity == 'bank' then
        a.atm = t.atm == 'yes'
    end
end

add_extra_attributes.tourism = function(a, t)
    if t.tourism == 'information' then
        a.information = t.information
    end
end

add_extra_attributes.man_made = function(a, t)
    if t.man_made == 'tower' then
        a['tower:type'] = t['tower:type']
    end
end

-- ---------------------------------------------------------------------------

local get_attributes = function(object)
    local t = object.tags
    local a = {}

    local is_poi = false
    for _, k in ipairs({'amenity', 'leisure', 'tourism', 'shop', 'man_made',
                        'historic', 'emergency', 'highway', 'office'}) do
        local v = get_value[k](t[k])
        if v then
            a[k] = v
            if add_extra_attributes[k] then
                add_extra_attributes[k](a, t)
            end
            is_poi = true
        end
    end

    if not is_poi then
        return nil
    end

    a.housename = t['addr:housename']
    a.housenumber = t['addr:housenumber']

    themepark.themes.core.add_name(a, object)

    return a
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object, data)
    local a = get_attributes(object)
    if a then
        a.geom = object:as_point()
        themepark:insert('pois', a, object.tags)
        data.shortbread_in_pois = true
    end
end)

themepark:add_proc('area', function(object, data)
    local a = get_attributes(object)
    if a then
        a.geom = object:as_area():centroid()
        themepark:insert('pois', a, object.tags)
        data.shortbread_in_pois = true
    end
end)

-- ---------------------------------------------------------------------------
