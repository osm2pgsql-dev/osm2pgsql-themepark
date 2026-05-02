# Proposal: LuaRocks Packaging

## Summary

Reorganize osm2pgsql-themepark so it can be installed via LuaRocks (`luarocks install osm2pgsql-themepark`) and used without manually cloning the repository or managing `LUA_PATH`.

## Problem

Currently users must:
1. Clone or download the repository
2. Manually set `LUA_PATH=lua/?.lua;;` before running osm2pgsql
3. Know to look for themes in the `themes/` sibling directory

There is no published LuaRocks package, no rockspec, and the theme discovery mechanism relies on a file-system path hack (`themepark.dir:gsub('/lua/$', '/themes')`) that breaks completely when the library is installed anywhere other than the exact cloned layout.

## Solution

1. Move the built-in themes into the Lua module tree (`lua/themepark/themes/`) so LuaRocks installs them alongside the core library.
2. Switch theme and topic loading from `io.open`/`load()` to standard `require()`, making themes proper Lua modules.
3. Keep a file-system fallback for custom user themes (via `add_theme_dir()` / `THEMEPARK_PATH`) for backward compatibility.
4. Add lazy-loading with helpful error messages to the three plugins that depend on optional external libraries.
5. Create an `osm2pgsql-themepark-scm-1.rockspec`.

## Goals

- `luarocks install osm2pgsql-themepark` installs the full framework and all built-in themes
- `require('themepark')` works from any install path without manual `LUA_PATH` setup
- `themepark:add_topic('shortbread_v1/streets')` API is unchanged
- Custom themes via `add_theme_dir()` and `THEMEPARK_PATH` continue to work
- Plugins fail with a clear "install X via luarocks" message when optional deps are missing

## Non-Goals

- Packaging `themes/explore/` and `themes/external/` (contain non-Lua binary/shell files; deferred to separate packages)
- Changing the user-facing config file API
- Publishing to the LuaRocks server (that is a follow-on step)

## Success Criteria

- `luarocks make osm2pgsql-themepark-scm-1.rockspec` succeeds
- `require('themepark')` works after a luarocks install
- All existing tests pass
- CI passes
