-- ---------------------------------------------------------------------------
--
-- Example config for basic/generic topics
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

-- For debug mode set this or the environment variable THEMEPARK_DEBUG.
--themepark.debug = true

-- ---------------------------------------------------------------------------

themepark:add_topic('core/clean-tags')

themepark:add_topic('basic/generic-points')
themepark:add_topic('basic/generic-lines')
themepark:add_topic('basic/generic-polygons')
themepark:add_topic('basic/generic-boundaries')
themepark:add_topic('basic/generic-routes')

-- ---------------------------------------------------------------------------
