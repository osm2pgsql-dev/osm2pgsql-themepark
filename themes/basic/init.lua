-- ---------------------------------------------------------------------------
--
-- Theme: basic
--
-- ---------------------------------------------------------------------------

local theme = {}

local function init_polygon_lookup()
    -- Objects with any of the following keys will be treated as polygon
    local polygon_keys = {
        'abandoned:aeroway',
        'abandoned:amenity',
        'abandoned:building',
        'abandoned:landuse',
        'abandoned:power',
        'aeroway',
        'allotments',
        'amenity',
        'area:highway',
        'building',
        'building:part',
        'club',
        'craft',
        'emergency',
        'golf',
        'harbour',
        'healthcare',
        'historic',
        'landuse',
        'leisure',
        'man_made',
        'military',
        'natural',
        'office',
        'place',
        'power',
        'public_transport',
        'shop',
        'tourism',
        'water',
        'wetland'
    }

    -- Objects with these key/value combinations will be treated as linestring
    local linestring_values = {
        aeroway = {'taxiway', 'runway'},
        emergency = {'designated', 'destination', 'no', 'official', 'yes'},
        golf = {'cartpath', 'hole', 'path'},
        historic = {'citywalls'},
        leisure = {'track', 'slipway'},
        man_made = {'breakwater', 'cutline', 'embankment', 'groyne', 'pipeline'},
        natural = {'cliff', 'earth_bank', 'tree_row', 'ridge', 'arete'},
        power = {'cable', 'line', 'minor_line'},
        tourism = {'yes'}
    }

    -- Objects with these key/value combinations will be treated as polygon
    local polygon_values = {
        aerialway = {'station'},
        boundary = {'aboriginal_lands', 'national_park', 'protected_area'},
        highway = {'services', 'rest_area'},
        junction = {'yes'},
        railway = {'station'},
        waterway = {'dock', 'boatyard', 'fuel', 'riverbank'}
    }

    local lookup_table = {}

    local function init_values(list, set_to)
        for key, values in pairs(list) do
            for _, value in ipairs(values) do
                if lookup_table[key] == nil then
                    lookup_table[key] = {}
                end
                lookup_table[key][value] = set_to
            end
        end
    end

    init_values(linestring_values, false)
    init_values(polygon_values, true)

    for _, key in ipairs(polygon_keys) do
        if lookup_table[key] == nil then
            lookup_table[key] = true
        else
            lookup_table[key][''] = true
        end
    end

    return lookup_table
end

local is_polygon = init_polygon_lookup()

-- Helper function that looks at the tags and decides if this is an area.
function theme.has_area_tags(tags)
    local area = tags.area
    if area == 'yes' then
        return true
    end
    if area == 'no' then
        return false
    end

    for k, v in pairs(tags) do
        local item = is_polygon[k]
        if item == true then
            return true
        end
        if item ~= nil then
            if item[v] ~= nil then
                return item[v]
            end
            if item[''] ~= nil then
                return item[v]
            end
        end
    end
end

return theme

-- ---------------------------------------------------------------------------
