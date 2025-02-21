-- ---------------------------------------------------------------------------
--
-- Theme: explore
-- Topic: protected_areas
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table({
    name = 'protected_areas_boundaries',
    ids_type = 'area',
    geom = 'multipolygon',
    columns = themepark:columns('core/name', {
        { column = 'boundary', type = 'text' },
        { column = 'protect_class', type = 'text' },
        { column = 'protection_title', type = 'text' },
        { column = 'short_protection_title', type = 'text' },
        { column = 'nature_reserve', type = 'bool', not_null = true }, -- has tag leisure=nature_reserve
        { column = 'ref', type = 'text' },
        { column = 'access', type = 'text' },
        { column = 'wikidata', type = 'text' },
        { column = 'website', type = 'text' },
        { column = 'operator', type = 'text' },
        { column = 'operator_wikidata', type = 'text' },
        { column = 'related_law', type = 'text' },
        { column = 'related_law_url', type = 'text' },
        { column = 'iucn', type = 'text' }, -- tag "ref:IUCN"
        { column = 'iucn_level', type = 'text' }, -- tag "iucn_level"
        { column = 'wdpa', type = 'int' }, -- WDPA
        { column = 'capad_pa_id', type = 'text' }, -- Collaborative Australian Protected Areas Database (CAPAD)
        { column = 'dtp_id', type = 'text' }, -- DIGITIZE THE PLANET
    }),
})

themepark:add_table({
    name = 'protected_areas_errors',
    ids_type = 'area',
    geom = 'multipolygon',
    columns = {
        { column = 'errormsg', type = 'text', not_null = true },
        { column = 'value', type = 'text' },
    }
})

local get_qcode = function(wd)
    if wd and wd:match('^Q%d+$') then
        return wd
    end
    return nil
end

themepark:add_proc('area', function(object, data)
    local t = object.tags
    if t.boundary == 'protected_area'
        or t.boundary == 'national_park' or t.boundary == 'water_protection_area'
        or t.leisure == 'nature_reserve' or t.protected_area then

        -- Check that wikidata tags contain syntactically valid Q codes
        -- https://www.wikidata.org/wiki/{wikidata_code}
        local wikidata_code = get_qcode(t.wikidata)
        local operator_wikidata_code = get_qcode(t.operator_wikidata)

        if t.wikidata ~= wikidata_code then
            themepark:insert('protected_areas_errors', {
                errormsg = 'invalid Q-item code for wikidata tag',
                value = t.wikidata
            }, t)
        end
        if t.operator_wikidata ~= operator_wikidata_code then
            themepark:insert('protected_areas_errors', {
                errormsg = 'invalid Q-item code for operator_wikidata tag',
                value = t.operator_wikidata
            }, t)
        end

        -- WDPA is always an integer
        -- https://www.protectedplanet.net/{wdpa}
        local wdpa = t['ref:WDPA']
        if wdpa and wdpa:match('^%d+$') then
            wdpa = tonumber(wdpa)
        else
            themepark:insert('protected_areas_errors', { errormsg = 'not a number in ref:WDPA tag', value = wdpa }, t)
            wdpa = nil
        end

        -- Digitize The Planet uses UUIDs
        -- https://content.digitizetheplanet.org/de/rules/show_protectedarea/{dtp_id}
        local dtp_id = t.dtp_id
        if dtp_id and not dtp_id:match('^[0-9a-f-]+$') then
            themepark:insert('protected_areas_errors', { errormsg = 'not a UUID in dtp_id tag', value = dtp_id }, t)
        end

        local a = {
            boundary = t.boundary,
            protect_class = t.protect_class,
            protection_title = t.protection_title,
            short_protection_title = t.short_protection_title,
            nature_reserve = (t.leisure == 'nature_reserve'),
            protected_area = t.protected_area,
            ref = t.ref,
            access = t.access,
            wikidata = wikidata_code,
            website = t.website,
            operator = t.operator,
            operator_wikidata = operator_wikidata_code,
            related_law = t.related_law,
            related_law_url = t['related_law:url'],
            iucn = t['ref:IUCN'],
            iucn_level = t.iucn_level,
            wdpa = wdpa,
            capad_pa_id = t['ref:capad:pa_id'],
            dtp_id = dtp_id,
            geom = object:as_area(),
        }

        themepark.themes.core.add_name(a, object)

        themepark:insert('protected_areas_boundaries', a, t)
    end
end)

-- ---------------------------------------------------------------------------
