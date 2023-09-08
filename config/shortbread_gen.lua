-- ---------------------------------------------------------------------------
--
-- Shortbread theme with generalization
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

themepark.debug = false

-- Add JSONB column `tags` with original OSM tags in debug mode
themepark:set_option('tags', 'all_tags')

-- ---------------------------------------------------------------------------

-- themepark:add_topic('core/name-single', { column = 'name' })
-- themepark:add_topic('core/name-list', { keys = {'name', 'name:de', 'name:en'} })

themepark:add_topic('core/name-with-fallback', {
    keys = {
        name = { 'name', 'name:en', 'name:de' },
        name_de = { 'name:de', 'name', 'name:en' },
        name_en = { 'name:en', 'name', 'name:de' },
    }
})

themepark:add_topic('core/layer')

themepark:add_topic('external/oceans', { name = 'ocean' })

themepark:add_topic('shortbread_v1/aerialways')
themepark:add_topic('shortbread_v1_gen/boundaries')
themepark:add_topic('shortbread_v1/boundary_labels')
themepark:add_topic('shortbread_v1/bridges')
themepark:add_topic('shortbread_v1/buildings')
themepark:add_topic('shortbread_v1/dams')
themepark:add_topic('shortbread_v1/ferries')
themepark:add_topic('shortbread_v1_gen/land')
themepark:add_topic('shortbread_v1/piers')
themepark:add_topic('shortbread_v1/places')
themepark:add_topic('shortbread_v1/pois')
themepark:add_topic('shortbread_v1/public_transport')
themepark:add_topic('shortbread_v1/sites')
themepark:add_topic('shortbread_v1_gen/streets')
themepark:add_topic('shortbread_v1_gen/water')

-- Must be after "pois" layer, because as per Shortbread spec addresses that
-- are already in "pois" should not be in the "addresses" layer.
themepark:add_topic('shortbread_v1/addresses')

-- ---------------------------------------------------------------------------

if osm2pgsql.mode == 'create' then
    themepark:plugin('t-rex'):write_config('t-rex-config.toml', {
        tileset = 'osm',
        extra_layers = {
            {
                buffer_size = 10,
                name = 'street_labels',
                geometry_type = 'LINESTRING',
                query = {
                    {
                        minzoom = 14,
                        sql = [[
SELECT "name","name_de","name_en","kind","layer","ref","ref_rows","ref_cols","z_order","geom"
    FROM "streets"
    WHERE "geom" && !bbox! AND !zoom! >= "minzoom"
    ORDER BY "z_order" asc]]
                    },
                    {
                        minzoom = 11,
                        maxzoom = 13,
                        sql = [[
SELECT "name","name_de","name_en","kind","layer","ref","ref_rows","ref_cols","z_order","geom"
    FROM "streets_med"
    WHERE "geom" && !bbox! AND !zoom! >= "minzoom"
    ORDER BY "z_order" asc]]
                    },
                }
            }
        }
    })

--    themepark:plugin('tilekiln'):write_config('tk')
end

-- ---------------------------------------------------------------------------
