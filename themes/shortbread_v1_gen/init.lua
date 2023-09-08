-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1_gen
--
-- ---------------------------------------------------------------------------

local theme = {}

theme.full_gen = (osm2pgsql.mode == 'create') or (os.getenv('OSM2PGSQL_GEN') == 'full')
print("DEBUG: Doing full generalization: ", theme.full_gen)

return theme

-- ---------------------------------------------------------------------------
