-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: name-list
--
-- Config:
--   * keys - Tag keys for the name, for example {"name", "name:fr"}
--
-- There will be columns for all tags in the config. Column names will have
-- all characters that are non-alphabetic replaced by '_', so "name:fr" will
-- show up as "name_fr".
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local name_keys = cfg.keys or {"name"}
local name_columns = {}

local replace_non_letters = function(str)
    return string.gsub(str, '[^a-z]', '_')
end

for _, k in pairs(name_keys) do
    name_columns[#name_columns + 1] = {
        column = replace_non_letters(k),
        type = 'text'
    }
end

themepark:register_columns('core', 'name', name_columns)

function theme.add_name(attrs, object)
    local has_name = false

    for _, k in pairs(name_keys) do
        if object.tags[k] then
            has_name = true
            attrs[replace_non_letters(k)] = object.tags[k]
        end
    end

    return has_name
end

-- ---------------------------------------------------------------------------
