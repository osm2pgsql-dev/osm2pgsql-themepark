# Design: LuaRocks Packaging

## Directory Restructure

Themes move from the top-level `themes/` directory into the Lua module tree so LuaRocks installs them alongside the core library.

```
BEFORE                                    AFTER
──────────────────────────────────────    ──────────────────────────────────────
lua/
  themepark.lua                           lua/
  themepark/                                themepark.lua
    lexer.lua                               themepark/
    parser.lua                                lexer.lua
    utils.lua                                 parser.lua
    plugins/                                  utils.lua
      bbox.lua                                plugins/
      t-rex.lua                                 bbox.lua
      taginfo.lua                               t-rex.lua
      tilekiln.lua                              taginfo.lua
themes/                                         tilekiln.lua
  basic/          ──────────────────────▶     themes/
  core/                                         basic/
  experimental/                                 core/
  osmcarto/                                     experimental/
  shortbread_v1/                                osmcarto/
  shortbread_v1_gen/                            shortbread_v1/
  explore/        ← stays (non-Lua files)       shortbread_v1_gen/
  external/       ← stays (non-Lua files) themes/
                                            explore/    (not packaged)
                                            external/   (not packaged)
config/           ← unchanged (examples)  config/     (unchanged)
```

After the move, `LUA_PATH=lua/?.lua;;` (the existing dev setting) continues to resolve all modules correctly in development. After a LuaRocks install, the standard LuaRocks path handles it.

## Theme and Topic File Convention

Themes and topics currently use the vararg script pattern (loaded via `load()`):

```lua
-- current topic file
local themepark, theme, cfg = ...
themepark:add_table{ ... }
```

All theme `init.lua` and `topics/*.lua` files are converted to return a function:

```lua
-- new topic file
return function(themepark, theme, cfg)
    themepark:add_table{ ... }
end
```

`init.lua` files return a function that receives `themepark` and returns the theme table:

```lua
-- new init.lua
return function(themepark)
    local theme = {}
    return theme
end
```

This is the minimal change needed — the body of each file is identical, just wrapped.

## Loader Changes in `themepark.lua`

### Removed

- `script_dir_impl()` and `script_dir()` — no longer needed
- `themepark.dir` field
- `themepark.theme_search_path` table and all path-scanning logic
- `themepark:add_theme_dir()` — replaced (see hybrid fallback below)
- `theme.dir` assignment in `init_theme()`

### `init_theme()` — new logic

```lua
function themepark:init_theme(theme_name)
    if self.themes[theme_name] then
        return self.themes[theme_name]
    end

    -- 1. Try require() — works for built-in and LuaRocks-installed themes
    local ok, result = pcall(require, 'themepark/themes/' .. theme_name)
    if ok then
        self.themes[theme_name] = result(self)
        return self.themes[theme_name]
    end

    -- 2. File-system fallback — for custom themes via add_theme_dir() / THEMEPARK_PATH
    for _, dir in ipairs(self._custom_theme_dirs) do
        local theme_file = dir .. '/' .. theme_name .. '/init.lua'
        local file = io.open(theme_file)
        if file then
            local script = file:read('*a')
            file:close()
            local func = load(script, theme_file, 't')
            self.themes[theme_name] = func(self)
            return self.themes[theme_name]
        end
    end

    error("Themepark: Theme '" .. theme_name .. "' not found")
end
```

### `add_topic()` — new logic

```lua
function themepark:add_topic(topic, options)
    local theme_name, topic_name = ...  -- same parsing as before

    local theme = self:init_theme(theme_name)

    -- 1. Try require()
    local module = 'themepark/themes/' .. theme_name .. '/topics/' .. topic_name
    local ok, topic_func = pcall(require, module)
    if ok then
        topic_func(self, theme, options or {})
        return
    end

    -- 2. File-system fallback for custom themes
    for _, dir in ipairs(self._custom_theme_dirs) do
        local filename = dir .. '/' .. theme_name .. '/topics/' .. topic_name .. '.lua'
        local file = io.open(filename, 'r')
        if file then
            local script = file:read('*a')
            file:close()
            local func = load(script, filename, 't')
            local status, result = pcall(func, self, theme, options or {})
            if not status then error(result, 2) end
            return result
        end
    end

    error("No topic '" .. topic_name .. "' in theme '" .. theme_name .. "'")
end
```

### `add_theme_dir()` — preserved for custom themes

```lua
function themepark:add_theme_dir(dir)
    -- resolve relative paths the same way as before
    if string.find(dir, '/') ~= 1 then
        dir = script_dir(5) .. dir   -- keep helper for this one use case
    end
    table.insert(self._custom_theme_dirs, 1, dir)
end
```

### `THEMEPARK_PATH` — preserved

The environment variable still adds entries to `_custom_theme_dirs` at startup. Built-in themes are found via `require()` first, so the env variable only matters for user-defined custom themes.

## Plugin Lazy-Loading

The three plugins with external dependencies switch from top-level `require` to `pcall`-guarded lazy loading. Pattern applied to all three:

```lua
-- t-rex.lua
local function load_toml()
    local ok, lib = pcall(require, 'toml')
    if not ok then
        error("The t-rex plugin requires the 'lua-toml' package: luarocks install lua-toml")
    end
    return lib
end

-- called at the point of use:
local toml = load_toml()
utils.write_to_file(filename, toml.encode(config) .. "\n")
```

| Plugin | Module | LuaRocks install command |
|---|---|---|
| `t-rex` | `toml` | `luarocks install lua-toml` |
| `tilekiln` | `lyaml` | `luarocks install lyaml` |
| `taginfo` | `json` | `luarocks install lua-json` |

`bbox.lua` has no external dependencies (uses its own `dump_toml()` implementation).

## Rockspec

```lua
-- osm2pgsql-themepark-scm-1.rockspec
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
      ["themepark"]                = "lua/themepark.lua",
      ["themepark.lexer"]          = "lua/themepark/lexer.lua",
      ["themepark.parser"]         = "lua/themepark/parser.lua",
      ["themepark.utils"]          = "lua/themepark/utils.lua",
      -- plugins
      ["themepark.plugins.bbox"]    = "lua/themepark/plugins/bbox.lua",
      ["themepark.plugins.t-rex"]   = "lua/themepark/plugins/t-rex.lua",
      ["themepark.plugins.taginfo"] = "lua/themepark/plugins/taginfo.lua",
      ["themepark.plugins.tilekiln"]= "lua/themepark/plugins/tilekiln.lua",
      -- themes
      ["themepark.themes.basic"]    = "lua/themepark/themes/basic/init.lua",
      ["themepark.themes.core"]     = "lua/themepark/themes/core/init.lua",
      ["themepark.themes.experimental"] = "lua/themepark/themes/experimental/init.lua",
      ["themepark.themes.osmcarto"] = "lua/themepark/themes/osmcarto/init.lua",
      ["themepark.themes.shortbread_v1"]     = "lua/themepark/themes/shortbread_v1/init.lua",
      ["themepark.themes.shortbread_v1_gen"] = "lua/themepark/themes/shortbread_v1_gen/init.lua",
      -- ... all topics listed individually (see tasks.md)
   }
}
```

All topic files are listed individually in the `modules` table — there is no glob support in rockspecs.

## CI Updates

- `LUA_PATH` in CI stays `lua/?.lua;;` — continues to work for local dev and tests
- The `require('themepark/themes/...')` calls resolve via the same path
- No changes to `bin/run-tests.sh`

## What Does Not Change

- The public API: `require('themepark')`, `themepark:add_topic()`, `themepark:add_theme_dir()`, `themepark:plugin()`
- The `config/` example files
- The `themes/explore/` and `themes/external/` directories
- Test files (they only test `utils`, `lexer`, `parser` which are unchanged)
