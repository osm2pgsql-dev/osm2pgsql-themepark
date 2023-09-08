-- ---------------------------------------------------------------------------
--
-- Theme: experimental
-- Topic: places
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'place_labels',
    ids_type = 'node',
    geom = 'point',
    columns = themepark:columns('core/name', {
        { column = 'kind', type = 'text', not_null = true },
        { column = 'population', type = 'int' },
        { column = 'minzoom', type = 'int', tiles = 'minzoom' },
        { column = 'importance', type = 'real', create_only = true, tiles = false },
        { column = 'discr_iso', type = 'real', create_only = true, tiles = false },
        { column = 'irank', type = 'int', create_only = true, tiles = false },
        { column = 'dirank', type = 'int', create_only = true, tiles = false },
        { column = 'wikidata', type = 'text', tiles = false },
    }),
    indexes = {
        { method = 'btree', column = 'wikidata' },
    },
    tiles = {
        minzoom = 4,
    },
}

-- ---------------------------------------------------------------------------

local place_types = {
    city = { pop = 100000, minzoom = 6 },
    town = { pop = 5000, minzoom = 7 },
    village = { pop = 100, minzoom = 10 },
    hamlet = { pop = 10, minzoom = 10 },
    suburb = { pop = 1000, minzoom = 10 },
    quarter = { pop = 500, minzoom = 10 },
    neighborhood = { pop = 100, minzoom = 10 },
    isolated_dwelling = { pop = 5, minzoom = 10 },
    farm = { pop = 5, minzoom = 10 },
    island = { pop = 0, minzoom = 10 },
    locality = { pop = 0, minzoom = 10 },
}

local get_qcode = function(wd)
    if wd and wd:match('^Q%d+$') then
        return wd
    end
    return nil
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', function(object, data)
    local t = object.tags
    if not t.place then
        return
    end
    local pt = place_types[t.place]

    if pt == nil then
        return
    end

    local a = {
        kind = t.place,
        population = tonumber(t.population) or pt.pop,
        minzoom = pt.minzoom,
        wikidata = get_qcode(t.wikidata),
        geom = object:as_point()
    }

    themepark.themes.core.add_name(a, object)

    if t.capital == '4' then
        if t.place == 'city' or t.place == 'town' or t.place == 'village' or t.place == 'hamlet' then
            a.kind = 'state_capital'
            a.minzoom = 4
        end
    elseif t.capital == 'yes' then
        if t.place == 'city' or t.place == 'town' or t.place == 'village' or t.place == 'hamlet' then
            a.kind = 'capital'
            a.minzoom = 4
        end
    end

    themepark:insert('place_labels', a, t)
end)

-- ---------------------------------------------------------------------------

themepark:add_proc('gen', function(data)

    -- Always get the importance of a place from the wikipedia_article table
    osm2pgsql.run_sql({
        description = 'Get importance metric for places',
        sql = [[
UPDATE place_labels p SET importance = coalesce(
    (SELECT max(importance) FROM wikipedia_article w WHERE p.wikidata = w.wd_page_title), 0)
  WHERE importance IS NULL
]]
    })

    -- Only (re-)calculate the discrete isolation in 'create' mode of when
    -- forced to with config setting.
    if osm2pgsql.mode == 'create' or cfg.force_discrete_isolation then
        osm2pgsql.run_gen('discrete-isolation', {
            name = 'cities',
            debug = false,
            src_table = 'place_labels',
            dest_table = 'place_labels',
            id_column = 'osm_id',
            geom_column = 'geom',
            importance_column = 'importance'
        })
    end
end)

-- ---------------------------------------------------------------------------
