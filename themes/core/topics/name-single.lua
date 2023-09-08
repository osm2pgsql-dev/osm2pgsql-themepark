-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: name-single
--
-- Config:
--   * key - Tag key for the name, for example "name:it" (default: "name").
--   * column - Column name (default: "name").
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local name_tag = cfg.key or 'name'
local name_column = cfg.column or 'name'

themepark:register_columns('core', 'name', {
    { column = name_column, type = 'text' }
})

function theme.add_name(attrs, object)
    local name = object.tags[name_tag]
    if name then
        attrs[name_column] = name
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
