-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: layer
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local function process(object, data)
    if not data.core then
        data.core = {}
    end

    local layer = tonumber(object.tags.layer)

    if layer == nil then
        layer = 0
    elseif layer > 7 then
        layer = 7
    elseif layer < -7 then
        layer = -7
    end

    data.core.layer = layer
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', process)
themepark:add_proc('way', process)
themepark:add_proc('relation', process)

-- ---------------------------------------------------------------------------
