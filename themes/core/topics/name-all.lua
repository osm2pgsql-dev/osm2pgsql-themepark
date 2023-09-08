-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: name-all
--
-- Add all names found in the tags to a JSONB column. Tags that contain
-- names are:
--   * `name`
--   * `name:XX`
--   * `name:XX-*`
--   * `name:XX_*`
--
-- Config:
--   * column - Column name (default: "name").
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local name_column = cfg.column or 'name'

themepark:register_columns('core', 'name', {
    { column = name_column, type = 'jsonb' }
})

local check_name = osm2pgsql.make_check_values_func({
    'alt_name', 'old_name', 'official_name', 'int_name', 'short_name', 'loc_name', 'nat_name'
})

function theme.add_name(attrs, object)
    local a = {}
    for k, v in pairs(object.tags) do
        if k == 'name' then
            a.name = v
        else
            if check_name(k) then
                a[k] = v
            else
                local m = string.match(k, '^name:([a-z][a-z])$')
                if m then
                    a[m] = v
                else
                    m = string.match(k, '^name:([a-z][a-z][-_]%a+)$')
                    if m then
                        a[m] = v
                    end
                end
            end
        end
    end

    if next(a) then
        attrs[name_column] = a
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
