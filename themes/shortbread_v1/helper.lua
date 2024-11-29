-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
--
-- helper.lua
--
-- ---------------------------------------------------------------------------
--
-- Only use code in here that is independent of osm2pgsql, the themepark
-- framework and the theme, so that it can be unit-tested!
--
-- ---------------------------------------------------------------------------

local helper = {}

function helper.is_yes_true_or_one(value)
    return value == 'yes' or value == 'true' or value == '1'
end

return helper

-- ---------------------------------------------------------------------------
