-- ---------------------------------------------------------------------------
--
-- Example config for protected_areas topic
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

themepark.debug = true

themepark:set_option('srid', 4326)
themepark:set_option('tags', 'all_tags')

-- ---------------------------------------------------------------------------

themepark:add_topic('core/clean-tags')
themepark:add_topic('core/layer')

themepark:add_topic('core/name-single', { column = 'name' })
themepark:add_topic('experimental/protected_areas')
themepark:add_topic('experimental/highways')

-- ---------------------------------------------------------------------------
