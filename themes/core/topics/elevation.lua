-- ---------------------------------------------------------------------------
--
-- Theme: core
-- Topic: elevation
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

local feet_per_meter = 3.2808399

local function round(value)
    return math.floor(value + 0.5)
end

local function process(object, data)
    if not data.core then
        data.core = {}
    end

    local ele = object.tags.ele

    if not ele then
        return
    end

    local val, unit = osm2pgsql.split_unit(ele, 'm')
    if val == nil then
        return
    end

    local a = data.core
    if unit == 'm' then
        a.ele_m = round(val)
        a.ele_ft = round(val * feet_per_meter)
    elseif unit == 'ft' then
        a.ele_m = round(val / feet_per_meter)
        a.ele_ft = round(val)
    end
end

-- ---------------------------------------------------------------------------

themepark:add_proc('node', process)
themepark:add_proc('way', process)
themepark:add_proc('relation', process)

-- ---------------------------------------------------------------------------
