-- ---------------------------------------------------------------------------
--
-- Example config for experimental topics
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

themepark.debug = false

-- ---------------------------------------------------------------------------

themepark:set_option('debug', 'debug') -- Add JSONB column `debug` with debug infos in debug mode
themepark:set_option('tags', 'all_tags') -- Add JSONB column `tags` with original OSM tags in debug mode

-- ---------------------------------------------------------------------------

-- themepark:add_topic('core/clean-tags')

-- themepark:add_topic('core/name-single', { column = 'name' })
-- themepark:add_topic('core/name-list', { keys = {'name', 'name:de', 'name:en'} })

themepark:add_topic('core/name-with-fallback', {
    keys = {
        name = { 'name', 'name:en', 'name:de' },
        name_de = { 'name:de', 'name', 'name:en' },
        name_en = { 'name:en', 'name', 'name:de' },
    }
})

--themepark:add_topic('experimental/builtup')
--themepark:add_topic('experimental/places')
--themepark:add_topic('experimental/rivers')

themepark:add_topic('core/elevation')
themepark:add_topic('experimental/information')
themepark:add_topic('experimental/viewpoints')

-- ---------------------------------------------------------------------------

themepark:plugin('t-rex'):write_config('t-rex-config.toml', {})

-- ---------------------------------------------------------------------------
