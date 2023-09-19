-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: protected_areas
--
-- Osmium Prefilter: boundary=protected_area,national_park,water_protection_area
--                   protect_class protection_title short_protection_title
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'protected_areas',
    ids_type = 'area',
    geom = 'multipolygon',
    columns = themepark:columns('core/name', {
        { column = 'boundary', type = 'text' },
        { column = 'protect_class', type = 'text' },
        { column = 'protection_title', type = 'text' },
        { column = 'short_protection_title', type = 'text' },
        { column = 'ref', type = 'text' },
        { column = 'access', type = 'text' },
        { column = 'wikidata', type = 'text' }, -- WIKIDATA https://www.wikidata.org/wiki/Q123
        { column = 'wdpa', type = 'text' }, -- WDPA https://www.protectedplanet.net/32666
        { column = 'iucn', type = 'text' },
        { column = 'iucn_level', type = 'text' },
        { column = 'dtp_id', type = 'text' }, -- DIGITIZE THE PLANET
        -- https://content.digitizetheplanet.org/de/rules/show_protectedarea/bc04f80f-5342-4c40-8d13-1da5be7da6ea
        { column = 'capad_pa_id', type = 'text' }, -- Collaborative Australian Protected Areas Database (CAPAD)
    }),
}

themepark:add_proc('area', function(object, data)
    local t = object.tags
    if t.boundary == 'protected_area' or t.boundary == 'national_park' or t.boundary == 'water_protection_area' then
        local a = {
            boundary = t.boundary,
            protect_class = t.protect_class,
            protection_title = t.protection_title,
            short_protection_title = t.short_protection_title,
            ref = t.ref,
            access = t.access,
            wikidata = t.wikidata,
            wdpa = t['ref:WDPA'],
            iucn = t['ref:IUCN'],
            iucn_level = t.iucn_level,
            dtp_id = t.dtp_id,
            capad_pa_id = t['ref:capad:pa_id'],
            geom = object:as_area(),
        }

        themepark.themes.core.add_name(a, object)

        themepark:insert('protected_areas', a, t)
    end
end)

-- ---------------------------------------------------------------------------
