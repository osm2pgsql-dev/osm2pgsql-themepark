package = "osm2pgsql-themepark"
version = "scm-1"

source = {
   url = "git+https://github.com/osm2pgsql-dev/osm2pgsql-themepark.git"
}

description = {
   summary = "A framework for pluggable osm2pgsql config files",
   homepage = "https://osm2pgsql.org/themepark/",
   license = "Apache-2.0"
}

dependencies = {
   "lua >= 5.1"
}

build = {
   type = "builtin",
   modules = {
      -- core
      ["themepark"]                 = "lua/themepark.lua",
      ["themepark.lexer"]           = "lua/themepark/lexer.lua",
      ["themepark.parser"]          = "lua/themepark/parser.lua",
      ["themepark.utils"]           = "lua/themepark/utils.lua",
      -- plugins (optional deps: lua-toml, lyaml, lua-json)
      ["themepark.plugins.bbox"]    = "lua/themepark/plugins/bbox.lua",
      ["themepark.plugins.t-rex"]   = "lua/themepark/plugins/t-rex.lua",
      ["themepark.plugins.taginfo"] = "lua/themepark/plugins/taginfo.lua",
      ["themepark.plugins.tilekiln"]= "lua/themepark/plugins/tilekiln.lua",
      -- themes
      ["themepark.themes.basic"] = "lua/themepark/themes/basic/init.lua",
      ["themepark.themes.basic.topics.generic-boundaries"] = "lua/themepark/themes/basic/topics/generic-boundaries.lua",
      ["themepark.themes.basic.topics.generic-lines"] = "lua/themepark/themes/basic/topics/generic-lines.lua",
      ["themepark.themes.basic.topics.generic-points"] = "lua/themepark/themes/basic/topics/generic-points.lua",
      ["themepark.themes.basic.topics.generic-polygons"] = "lua/themepark/themes/basic/topics/generic-polygons.lua",
      ["themepark.themes.basic.topics.generic-routes"] = "lua/themepark/themes/basic/topics/generic-routes.lua",
      ["themepark.themes.basic.topics.nwr"] = "lua/themepark/themes/basic/topics/nwr.lua",
      ["themepark.themes.core"] = "lua/themepark/themes/core/init.lua",
      ["themepark.themes.core.topics.clean-tags"] = "lua/themepark/themes/core/topics/clean-tags.lua",
      ["themepark.themes.core.topics.elevation"] = "lua/themepark/themes/core/topics/elevation.lua",
      ["themepark.themes.core.topics.layer"] = "lua/themepark/themes/core/topics/layer.lua",
      ["themepark.themes.core.topics.name-all"] = "lua/themepark/themes/core/topics/name-all.lua",
      ["themepark.themes.core.topics.name-list"] = "lua/themepark/themes/core/topics/name-list.lua",
      ["themepark.themes.core.topics.name-single"] = "lua/themepark/themes/core/topics/name-single.lua",
      ["themepark.themes.core.topics.name-with-fallback"] = "lua/themepark/themes/core/topics/name-with-fallback.lua",
      ["themepark.themes.experimental"] = "lua/themepark/themes/experimental/init.lua",
      ["themepark.themes.experimental.topics.builtup"] = "lua/themepark/themes/experimental/topics/builtup.lua",
      ["themepark.themes.experimental.topics.highways"] = "lua/themepark/themes/experimental/topics/highways.lua",
      ["themepark.themes.experimental.topics.information"] = "lua/themepark/themes/experimental/topics/information.lua",
      ["themepark.themes.experimental.topics.places"] = "lua/themepark/themes/experimental/topics/places.lua",
      ["themepark.themes.experimental.topics.power"] = "lua/themepark/themes/experimental/topics/power.lua",
      ["themepark.themes.experimental.topics.rivers"] = "lua/themepark/themes/experimental/topics/rivers.lua",
      ["themepark.themes.experimental.topics.viewpoints"] = "lua/themepark/themes/experimental/topics/viewpoints.lua",
      ["themepark.themes.external"] = "lua/themepark/themes/external/init.lua",
      ["themepark.themes.external.topics.coastlines"] = "lua/themepark/themes/external/topics/coastlines.lua",
      ["themepark.themes.external.topics.continents"] = "lua/themepark/themes/external/topics/continents.lua",
      ["themepark.themes.external.topics.oceans"] = "lua/themepark/themes/external/topics/oceans.lua",
      ["themepark.themes.osmcarto"] = "lua/themepark/themes/osmcarto/init.lua",
      ["themepark.themes.osmcarto.topics.osmcarto"] = "lua/themepark/themes/osmcarto/topics/osmcarto.lua",
      ["themepark.themes.shortbread_v1"] = "lua/themepark/themes/shortbread_v1/init.lua",
      ["themepark.themes.shortbread_v1.topics.addresses"] = "lua/themepark/themes/shortbread_v1/topics/addresses.lua",
      ["themepark.themes.shortbread_v1.topics.aerialways"] = "lua/themepark/themes/shortbread_v1/topics/aerialways.lua",
      ["themepark.themes.shortbread_v1.topics.boundaries"] = "lua/themepark/themes/shortbread_v1/topics/boundaries.lua",
      ["themepark.themes.shortbread_v1.topics.boundary_labels"] = "lua/themepark/themes/shortbread_v1/topics/boundary_labels.lua",
      ["themepark.themes.shortbread_v1.topics.bridges"] = "lua/themepark/themes/shortbread_v1/topics/bridges.lua",
      ["themepark.themes.shortbread_v1.topics.buildings"] = "lua/themepark/themes/shortbread_v1/topics/buildings.lua",
      ["themepark.themes.shortbread_v1.topics.dams"] = "lua/themepark/themes/shortbread_v1/topics/dams.lua",
      ["themepark.themes.shortbread_v1.topics.ferries"] = "lua/themepark/themes/shortbread_v1/topics/ferries.lua",
      ["themepark.themes.shortbread_v1.topics.land"] = "lua/themepark/themes/shortbread_v1/topics/land.lua",
      ["themepark.themes.shortbread_v1.topics.piers"] = "lua/themepark/themes/shortbread_v1/topics/piers.lua",
      ["themepark.themes.shortbread_v1.topics.places"] = "lua/themepark/themes/shortbread_v1/topics/places.lua",
      ["themepark.themes.shortbread_v1.topics.pois"] = "lua/themepark/themes/shortbread_v1/topics/pois.lua",
      ["themepark.themes.shortbread_v1.topics.public_transport"] = "lua/themepark/themes/shortbread_v1/topics/public_transport.lua",
      ["themepark.themes.shortbread_v1.topics.sites"] = "lua/themepark/themes/shortbread_v1/topics/sites.lua",
      ["themepark.themes.shortbread_v1.topics.streets"] = "lua/themepark/themes/shortbread_v1/topics/streets.lua",
      ["themepark.themes.shortbread_v1.topics.water"] = "lua/themepark/themes/shortbread_v1/topics/water.lua",
      ["themepark.themes.shortbread_v1_gen"] = "lua/themepark/themes/shortbread_v1_gen/init.lua",
      ["themepark.themes.shortbread_v1_gen.topics.boundaries"] = "lua/themepark/themes/shortbread_v1_gen/topics/boundaries.lua",
      ["themepark.themes.shortbread_v1_gen.topics.land"] = "lua/themepark/themes/shortbread_v1_gen/topics/land.lua",
      ["themepark.themes.shortbread_v1_gen.topics.streets"] = "lua/themepark/themes/shortbread_v1_gen/topics/streets.lua",
      ["themepark.themes.shortbread_v1_gen.topics.water"] = "lua/themepark/themes/shortbread_v1_gen/topics/water.lua",
   }
}
