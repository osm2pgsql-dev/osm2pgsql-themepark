-- ---------------------------------------------------------------------------
--
-- Theme: explore
-- Topic: restrictions
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

-- Every way tagged "highway".
themepark:add_table{
    name = 'restrictions_highways',
    ids_type = 'way',
    geom = 'linestring',
    columns = {
        { column = 'type', type = 'text', not_null = true },
        { column = 'oneway', type = 'direction' },
    },
    tags = {
        { key = 'highway', on = 'w' },
        { key = 'oneway', on = 'w' },
    },
}

themepark:add_table{
    name = 'restrictions_parking',
    ids_type = 'way',
    geom = 'polygon',
    columns = {
    },
    tags = {
        { key = 'amenity', value = 'parking', on = 'w' },
    },
}

-- Every relation tagged "type=restriction".
themepark:add_table{
    name = 'restrictions_relations',
    ids_type = 'relation',
    geom = 'geometry',
    columns = {
        { column = 'type', type = 'text' }, -- 'no', 'only', or 'unknown'
        { column = 'restriction', type = 'text' }, -- value of 'restriction' tag
        { column = 'buffered_geom', type = 'geometry', create_only = true },
        { column = 'anchor', type = 'point', create_only = true }, -- used for labelling
        { column = 'error_message', type = 'text' },
        { column = 'from', type = 'int2' }, -- number of members with role 'from'
        { column = 'to', type = 'int2' }, -- number of members with role 'to'
        { column = 'via', type = 'int2' }, -- number of members with role 'via'
        { column = 'members', type = 'jsonb' },
    },
    tags = {
        { key = 'type', value = 'restriction', on = 'r' },
    },
}

themepark:add_table{
    name = 'restrictions_nodes',
    ids_type = 'node',
    geom = 'point',
    columns = {
        { column = 'relation_id', type = 'int8', not_null = true },
        { column = 'type', type = 'text' }, -- 'no', 'only', or 'unknown'
        { column = 'restriction', type = 'text' }, -- value of 'restriction' tag from relation
        { column = 'role', type = 'text' }, -- role of this member
        { column = 'error_message', type = 'text' },
    },
}

themepark:add_table{
    name = 'restrictions_ways',
    ids_type = 'way',
    geom = 'linestring',
    columns = {
        { column = 'relation_id', type = 'int8', not_null = true },
        { column = 'type', type = 'text' }, -- 'no', 'only', or 'unknown'
        { column = 'restriction', type = 'text' }, -- value of 'restriction' tag from relation
        { column = 'role', type = 'text' }, -- role of this member
        { column = 'error_message', type = 'text' },
    },
}

-- ---------------------------------------------------------------------------

local valid_role = {
    from = 1,
    to   = 1,
    via  = 1,
}

local valid_restriction = {
    no_right_turn    = 1,
    no_left_turn     = 1,
    no_u_turn        = 1,
    no_straight_on   = 1,
    only_right_turn  = 1,
    only_left_turn   = 1,
    only_u_turn      = 1,
    only_straight_on = 1,
    no_entry         = 1,
    no_exit          = 1,
}

-- ---------------------------------------------------------------------------

local members = { n = {}, w = {} }

themepark:add_proc('node', function(object, data)
    if osm2pgsql.stage ~= 2 then
        return
    end

    local member_of = members.n[object.id]

    if not member_of then
        return
    end

    local t = object.tags

    local a = {
        geom = object:as_point(),
    }

    for _, relinfo in ipairs(member_of) do
        if not valid_role[relinfo[4]] then
            a.error_message = "unknown role"
        end
        a.relation_id = relinfo[1]
        a.restriction = relinfo[2]
        a.type = relinfo[3]
        a.role = relinfo[4]
        themepark:insert('restrictions_nodes', a, t)
    end
end)

-- Highway types that are only for pedestrians are usually not interesting
-- for turn restrictions, so we don't want to import them.
local function is_interesting_highway(hw)
    if not hw then
        return false
    end

    return hw ~= 'platform' and hw ~= 'path' and hw ~= 'steps' and hw ~= 'footway'
end

themepark:add_proc('way', function(object, data)
    local t = object.tags

    if is_interesting_highway(t.highway) then
        local a = {
            type = t.highway,
            oneway = t.oneway,
            geom = object:as_linestring(),
        }

        if a.type == 'motorway' and t.oneway == nil then
            a.oneway = 1
        end

        themepark:insert('restrictions_highways', a, t)
    end

    if t.amenity == 'parking' and object.is_closed then
        themepark:insert('restrictions_parking', { geom = object:as_polygon() }, t)
    end

    if osm2pgsql.stage ~= 2 then
        return
    end

    local member_of = members.w[object.id]

    if not member_of then
        return
    end

    local a = {
        geom = object:as_linestring(),
    }

    for _, relinfo in ipairs(member_of) do
        if not valid_role[relinfo[4]] then
            a.error_message = "unknown role"
        end
        a.relation_id = relinfo[1]
        a.restriction = relinfo[2]
        a.type = relinfo[3]
        a.role = relinfo[4]
        themepark:insert('restrictions_ways', a, t)
    end
end)

themepark:add_proc('select_relation_members', function(relation)
    if relation.tags.type == 'restriction' then
        return {
            nodes = osm2pgsql.node_member_ids(relation),
            ways = osm2pgsql.way_member_ids(relation),
        }
    end
end)

themepark:add_proc('relation', function(object, data)
    local t = object.tags

    if t.type ~= 'restriction' then
        return
    end

    local r = t.restriction
    local error_messages = {}

    local rtype
    if r == nil then
        table.insert(error_messages, "missing 'restriction' tag")
    elseif r:match('^no_') then
        rtype = 'no'
    elseif r:match('^only_') then
        rtype = 'only'
    else
        rtype = 'unknown'
    end

    local count_from = 0
    local count_to = 0
    local count_via_node = 0
    local count_via_way = 0
    for _, member in ipairs(object.members) do
        if member.type == 'r' then
            table.insert(error_messages, "member of type relation")
        end
        if member.role == 'from' then
            if member.type == 'w' then
                count_from = count_from + 1
            else
                table.insert(error_messages, "non-way member with role 'from'")
            end
        elseif member.role == 'to' then
            if member.type == 'w' then
                count_to = count_to + 1
            else
                table.insert(error_messages, "non-way member with role 'to'")
            end
        elseif member.role == 'via' then
            if member.type == 'n' then
                count_via_node = count_via_node + 1
            elseif member.type == 'w' then
                count_via_way = count_via_way + 1
            end
        else
            table.insert(error_messages, "unknown member role")
        end
    end

    if not valid_restriction[r] then
        table.insert(error_messages, "unknown restriction type")
    end

    if count_from == 0 then
        table.insert(error_messages, "missing 'from' role")
    elseif count_from > 1 and r ~= 'no_entry' then
        table.insert(error_messages, "too many (>1) members with role 'from'")
    end

    if count_to == 0 then
        table.insert(error_messages, "missing 'to' role")
    elseif count_to > 1 and r ~= 'no_exit' then
        table.insert(error_messages, "too many (>1) members with role 'to'")
    end

    if count_via_node > 0 and count_via_way > 0 then
        table.insert(error_messages, "role 'via' on node and way")
    elseif count_via_node > 1 then
        table.insert(error_messages, "too many members (>1) with role 'via'")
    end

    local a = {
        type = rtype,
        members = object.members,
        restriction = r,
        from = count_from,
        to = count_to,
        via = count_via_node + count_via_way,
        geom = object:as_geometrycollection(),
    }

    if #error_messages > 0 then
        a.error_message = table.concat(error_messages, ', ')
    end

    themepark:insert('restrictions_relations', a, t)

    for _, member in ipairs(object.members) do
        if member.type == 'n' or member.type == 'w' then
            local m = members[member.type]
            if not m[member.ref] then
                m[member.ref] = {}
            end
            table.insert(m[member.ref], { object.id, r, rtype, member.role })
        end
    end
end)

-- ---------------------------------------------------------------------------

themepark:add_proc('gen', function(data)

    osm2pgsql.run_sql({
        description = "Set labelling point for relations from 'via' nodes",
        sql = themepark.expand_template([[
UPDATE {schema}.{prefix}restrictions_relations r
    SET anchor = n.geom
    FROM {schema}.{prefix}restrictions_nodes n
    WHERE r.relation_id = n.relation_id AND anchor IS NULL AND n.role = 'via'
]]
        )
    })

    osm2pgsql.run_sql({
        description = "Set labelling point for relations from 'via' ways",
        sql = themepark.expand_template([[
UPDATE {schema}.{prefix}restrictions_relations r
    SET anchor = ST_PointN(w.geom, 1)
    FROM {schema}.{prefix}restrictions_ways w
    WHERE r.relation_id = w.relation_id AND anchor IS NULL AND w.role = 'via'
]]
        )
    })

    osm2pgsql.run_sql({
        description = 'Buffer relations for display',
        sql = themepark.expand_template([[
UPDATE {schema}.{prefix}restrictions_relations
    SET buffered_geom = ST_Buffer(geom, 10)
    WHERE buffered_geom IS NULL
]]
        )
    })

end)

-- ---------------------------------------------------------------------------
