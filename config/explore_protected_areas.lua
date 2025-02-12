-- ---------------------------------------------------------------------------
--
-- Example config for exploring OSM data
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

-- For debug mode set this or the environment variable THEMEPARK_DEBUG.
themepark.debug = true

-- ---------------------------------------------------------------------------

themepark:set_option('debug', 'debug') -- Add JSONB column `debug` with debug infos in debug mode
themepark:set_option('tags', 'all_tags') -- Add JSONB column `tags` with original OSM tags in debug mode

-- ---------------------------------------------------------------------------

themepark:add_topic('core/name-with-fallback', {
    keys = {
        name = { 'name', 'name:en', 'name:de' },
        name_de = { 'name:de', 'name', 'name:en' },
        name_en = { 'name:en', 'name', 'name:de' },
    }
})

themepark:add_topic('explore/protected_areas')

-- ---------------------------------------------------------------------------
