#!/bin/sh
#
#  Uses luacheck to check all Lua files
#
#  Needs: https://github.com/mpeterv/luacheck (Debian package: lua-check)
#

luacheck \
    lua/themepark.lua \
    lua/themepark/*.lua \
    lua/themepark/*/*.lua \
    tests/*.lua \
    config/*.lua \
    themes/*/*.lua \
    themes/*/topics/*.lua

