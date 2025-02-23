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
        { column = 'iucn_level', type = 'text' }, -- tag "iucn_level"
        { column = 'iucn', type = 'text' }, -- IUCN category from iucn_level or protect_class
        { column = 'wdpa', type = 'int' }, -- WDPA
        { column = 'capad_pa_id', type = 'text' }, -- Collaborative Australian Protected Areas Database (CAPAD)
        { column = 'dtp_id', type = 'text' }, -- DIGITIZE THE PLANET
    }),
})

themepark:add_table({
    name = 'protected_areas_errors',
    ids_type = 'area',
    geom = 'multipolygon',
    columns = themepark:columns({
        { column = 'ecode', type = 'text', not_null = true },
        { column = 'emsg', type = 'text', not_null = true },
        { column = 'value', type = 'text' },
    })
})

-- ---------------------------------------------------------------------------

local get_qcode = function(wd)
    if wd and wd:match('^Q%d+$') then
        return wd
    end
    return nil
end

-- See https://en.wikipedia.org/wiki/IUCN_protected_area_categories
local iucn_mapping = {
    -- these are the official levels
    ['IA']  = 'IA',  -- strict nature reserve
    ['IB']  = 'IB',  -- wilderness area
    ['II']  = 'II',  -- national park
    ['III'] = 'III', -- natural monument or feature
    ['IV']  = 'IV',  -- habitat or species management area
    ['V']   = 'V',   -- protected landscape or seascape
    ['VI']  = 'VI',  -- protected area with sustainable use of natural resources

    -- these are different forms of the official levels
    ['Ia']  = 'IA',
    ['Ib']  = 'IB',
    ['1a']  = 'IA',
    ['1b']  = 'IB',
    ['2']   = 'II',
    ['3']   = 'III',
    ['4']   = 'IV',
    ['5']   = 'V',
    ['6']   = 'VI',
}

local function valid_protect_class(pc)
    if pc == '1a' or pc == '1b' then
        return true
    end
    return pc:match('^%d%d?$')
end

-- ---------------------------------------------------------------------------

local error_messages = {
    dtp_id = 'invalid dtp_id (not a UUID)',
    iucn_level = 'invalid iucn_level',
    iucn_level_protect_class_mismatch = 'iucn_level tag does not match protect_class tag',
    operator_wikidata = 'invalid Q-item code for operator_wikidata tag',
    protect_class = 'invalid protect_class (allowed: 1a, 1b, 1-99)',
    ref_wdpa = 'invalid ref:WDPA tag (not an integer)',
    wikidata = 'invalid Q-item code for wikidata tag',
}

local function add_error(ecode, value, geom, tags)
    themepark:insert('protected_areas_errors', {
        ecode = ecode,
        emsg = error_messages[ecode],
        value = value,
        geom = geom,
    }, tags)
end

-- ---------------------------------------------------------------------------

themepark:add_proc('area', function(object, data)
    local t = object.tags
    if t.boundary == 'protected_area'
        or t.boundary == 'national_park' or t.boundary == 'water_protection_area'
        or t.leisure == 'nature_reserve' or t.protected_area then

        local geom = object:as_area()

        -- Check that wikidata tags contain syntactically valid Q codes
        -- https://www.wikidata.org/wiki/{wikidata_code}
        local wikidata_code = get_qcode(t.wikidata)
        local operator_wikidata_code = get_qcode(t.operator_wikidata)

        if t.wikidata ~= wikidata_code then
            add_error('wikidata', t.wikidata, geom, t)
        end
        if t.operator_wikidata ~= operator_wikidata_code then
            add_error('operator_wikidata', t.operator_wikidata, geom, t)
        end

        local iucn = iucn_mapping[t.iucn_level]
        if t.iucn_level and iucn == nil then
            add_error('iucn_level', t.iucn_level, geom, t)
        end

        if t.protect_class and not valid_protect_class(t.protect_class) then
            add_error('protect_class', t.protect_class, geom, t)
        end

        if iucn then
            if iucn_mapping[t.protect_class] and iucn ~= iucn_mapping[t.protect_class] then
                add_error('iucn_level_protect_class_mismatch', t.iucn_level .. ' <> ' .. t.protect_class, geom, t)
            end
        else
            iucn = iucn_mapping[t.protect_class]
        end

        -- WDPA is always an integer
        -- https://www.protectedplanet.net/{wdpa}
        local wdpa = t['ref:WDPA']
        if wdpa then
            if wdpa:match('^%d+$') then
                wdpa = tonumber(wdpa)
            else
                add_error('ref_wdpa', wdpa, geom, t)
                wdpa = nil
            end
        end

        -- Digitize The Planet uses UUIDs
        -- https://content.digitizetheplanet.org/de/rules/show_protectedarea/{dtp_id}
        local dtp_id = t.dtp_id
        if dtp_id and not dtp_id:match('^[0-9a-f-]+$') then
            add_error('dtp_id', dtp_id, geom, t)
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
            iucn_level = t.iucn_level,
            iucn = iucn,
            wdpa = wdpa,
            capad_pa_id = t['ref:capad:pa_id'],
            dtp_id = dtp_id,
            geom = geom,
        }

        themepark.themes.core.add_name(a, object)

        themepark:insert('protected_areas_boundaries', a, t)
    end
end)

-- ---------------------------------------------------------------------------
