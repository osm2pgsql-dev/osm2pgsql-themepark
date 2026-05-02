# Tasks: LuaRocks Packaging

- [x] Move theme directories into the Lua tree
- [x] Wrap theme init.lua files
- [x] Wrap topic files
- [x] Refactor lua/themepark.lua loader
- [x] Add lazy-loading to plugins
- [x] Create osm2pgsql-themepark-scm-1.rockspec
- [x] Verify with luarocks make
- [x] Run existing tests
- [x] Update CI

## Details

### Task: Move theme directories into the Lua tree

Move the 6 built-in theme directories from `themes/` into `lua/themepark/themes/`. Leave `themes/explore/` and `themes/external/` in place. Use `git mv` to preserve history.

```
themes/basic/          → lua/themepark/themes/basic/
themes/core/           → lua/themepark/themes/core/
themes/experimental/   → lua/themepark/themes/experimental/
themes/osmcarto/       → lua/themepark/themes/osmcarto/
themes/shortbread_v1/       → lua/themepark/themes/shortbread_v1/
themes/shortbread_v1_gen/   → lua/themepark/themes/shortbread_v1_gen/
```

### Task: Wrap theme init.lua files

Each `init.lua` must return a function that receives `themepark` and returns the theme table. Wrap all 6:

- `lua/themepark/themes/basic/init.lua`
- `lua/themepark/themes/core/init.lua`
- `lua/themepark/themes/experimental/init.lua`
- `lua/themepark/themes/osmcarto/init.lua`
- `lua/themepark/themes/shortbread_v1/init.lua`
- `lua/themepark/themes/shortbread_v1_gen/init.lua`

Pattern:
```lua
return function(themepark)
    -- existing content unchanged
end
```

### Task: Wrap topic files

Replace `local themepark, theme, cfg = ...` and wrap all 41 topic files in `return function(themepark, theme, cfg) ... end`.

basic (6): generic-boundaries, generic-lines, generic-points, generic-polygons, generic-routes, nwr
core (7): clean-tags, elevation, layer, name-all, name-list, name-single, name-with-fallback
experimental (7): builtup, highways, information, places, power, rivers, viewpoints
osmcarto (1): osmcarto
shortbread_v1 (16): addresses, aerialways, boundaries, boundary_labels, bridges, buildings, dams, ferries, land, piers, places, pois, public_transport, sites, streets, water
shortbread_v1_gen (4): boundaries, land, streets, water

### Task: Refactor lua/themepark.lua loader

1. Remove `script_dir_impl()`, `script_dir()`, `themepark.dir`, `themepark.theme_search_path`
2. Add `themepark._custom_theme_dirs = {}` field
3. Rewrite `init_theme()`: try `require('themepark/themes/' .. name)` first, fall back to `_custom_theme_dirs` file-system scan
4. Rewrite `add_topic()`: try `require('themepark/themes/' .. theme .. '/topics/' .. topic)` first, fall back to `_custom_theme_dirs` scan
5. Rewrite `add_theme_dir()`: push to `_custom_theme_dirs`, keep relative-path resolution using a local `script_dir` helper scoped only to this function
6. Rewrite `THEMEPARK_PATH` startup block: split on `:` and push entries to `_custom_theme_dirs`
7. Remove `theme.dir` assignment from `init_theme()`

### Task: Add lazy-loading to plugins

**t-rex.lua**: Replace `local toml = require 'toml'` with a `load_toml()` helper using `pcall`. Error message: `"The t-rex plugin requires the 'lua-toml' package.\nInstall it with: luarocks install lua-toml"`

**tilekiln.lua**: Replace `local lyaml = require 'lyaml'` similarly. Error message: `"The tilekiln plugin requires the 'lyaml' package.\nInstall it with: luarocks install lyaml"`

**taginfo.lua**: Replace `local json = require 'json'` similarly. Error message: `"The taginfo plugin requires the 'lua-json' package.\nInstall it with: luarocks install lua-json"`

Call the loader function at the point of first use inside `write_config()`.

### Task: Create osm2pgsql-themepark-scm-1.rockspec

Create at the repository root with `build.type = "builtin"`. The `modules` table enumerates all Lua files individually (rockspecs have no glob support). Module naming: replace path separators with `.`, drop `lua/` prefix and `.lua` suffix.

Core: themepark, themepark.lexer, themepark.parser, themepark.utils
Plugins: themepark.plugins.bbox, themepark.plugins.t-rex, themepark.plugins.taginfo, themepark.plugins.tilekiln
Theme inits: themepark.themes.basic, themepark.themes.core, themepark.themes.experimental, themepark.themes.osmcarto, themepark.themes.shortbread_v1, themepark.themes.shortbread_v1_gen
Topics: one entry per topic file, e.g. themepark.themes.basic.topics.generic-boundaries

### Task: Verify with luarocks make

Run `luarocks make osm2pgsql-themepark-scm-1.rockspec` and confirm it succeeds. Fix any missing module entries in the rockspec.

### Task: Run existing tests

Run `bin/run-tests.sh` with `LUA_PATH=lua/?.lua;;` and confirm all tests pass.

### Task: Update CI

Add a `luarocks make` validation step to `.github/workflows/ci.yml`:
```yaml
- name: Validate rockspec
  run: luarocks make osm2pgsql-themepark-scm-1.rockspec
```
