-- ---------------------------------------------------------------------------
--
-- Example config for basic/nwr topic
--
-- Configuration for the osm2pgsql Themepark framework
--
-- ---------------------------------------------------------------------------

local themepark = require('themepark')

themepark.debug = false

-- ---------------------------------------------------------------------------

themepark:add_topic('core/clean-tags')

themepark:add_topic('basic/nwr')

-- ---------------------------------------------------------------------------
