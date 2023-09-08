-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: name-with-fallback
--
-- Config:
--   * keys - Tag keys for the name
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local name_keys = cfg.keys or { name = { 'name' } }
local name_columns = {}

local keys = {}
for k, _ in pairs(name_keys) do
    table.insert(keys, k)
end

table.sort(keys)

for _, k in ipairs(keys) do
    table.insert(name_columns, {
        column = k,
        type = 'text'
    })
end

themepark:register_columns('core', 'name', name_columns)

function theme.add_name(attrs, object)
    local has_name = false
    local t = object.tags

    for attr, list in pairs(name_keys) do
        for _, key in ipairs(list) do
            if t[key] then
                has_name = true
                attrs[attr] = t[key]
                break
            end
        end
    end

    return has_name
end

-- ---------------------------------------------------------------------------
