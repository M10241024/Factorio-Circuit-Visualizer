
local NAMESPACE = "cv_"
local Queue = require("__circuit_visualizer__/queue")
local ENTITIES_PER_TICK = 200
local VIEV_DISTANCE = 250
local INPUT_OUTPUT_COMBINATORS = {
    ["arithmetic-combinator"] = true,
    ["decider-combinator"] = true,
    ["selector-combinator"] = true,
}
local MAX_ENITIES_FROM_GET_CONNECTED_ENTITIES = 1000

--[[
{
    [player] = {
        entities = {
            [entity_id] = {
                entity = entity,
                rendered_objects = { -- ids of lines and circles
                    length = 2,
                    0 = rendered_object,
                    1 = rendered_object,
                },
                visualized_connections = {
                    [connected_entity_id] = 0, -- visualized in a different way
                    [connected_entity_id] = 1, -- visualized by the "V" key
                },
            }
        }
        visualized_networks = {
            [network_id] = true,
        }
        selected_networks = {
            [network_id] = true,
        },
        position = {x=,y=},
        surface = surface_id,
        entities_to_update = Queue,
        selected_entity = {
            id = unit_number,
            connection_count = 0,
        },
    },
}
]]

-- make global[playr_index] the correct format instead of nil
local function setup_player_data(player_index)
    global[player_index] = global[player_index] or {
        entities = {},
        visualized_networks = {},
        selected_networks = {},
        entities_to_update = Queue.new(),
        selected_entity = {id = -1, connection_count = -1},
    }
    return global[player_index]
end

local function is_entity_valid(entity)
    return entity and entity.valid and entity.unit_number and entity.type ~= "entity-ghost"
end

local function get_connected_networks(entity)
    if not is_entity_valid(entity) then return {} end
    local connections = entity.circuit_connection_definitions
    if not connections then return {} end
    local network_ids = {}
    for _, connection in ipairs(connections) do
        local network_id = entity.get_circuit_network(connection.wire, connection.source_circuit_id).network_id
        local network_color = connection.wire
        network_ids[network_id] = network_color
    end
    return network_ids
end

local function get_connected_entities(entity, network_id)
    if not is_entity_valid(entity) then return {} end
    local entities_to_add = {entity}
    local added_entity_ids = {[entity.unit_number] = true}
    local added_entities = {[entity] = true}
    local networks = {}
    if network_id then
        networks[network_id] = true
    else
        for new_network_id, _ in pairs(get_connected_networks(entity)) do
            networks[new_network_id] = true
        end
    end
    local i = 1
    local last = 1
    while i <= MAX_ENITIES_FROM_GET_CONNECTED_ENTITIES and entities_to_add[i] do
        for _, connection in ipairs(entities_to_add[i].circuit_connection_definitions or {}) do
            local new_entity = connection.target_entity
            if new_entity.unit_number then
                local not_added_already = not added_entity_ids[new_entity.unit_number]
                local on_correct_network = not network_id or network_id == entities_to_add[i].get_circuit_network(connection.wire, connection.source_circuit_id).network_id
                if not_added_already and on_correct_network then
                    last = last + 1
                    entities_to_add[last] = new_entity
                    added_entity_ids[new_entity.unit_number] = true
                    added_entities[new_entity] = true
                    if not network_id then
                        for new_network_id, _ in pairs(get_connected_networks(new_entity)) do
                            networks[new_network_id] = true
                        end
                    end
                end
            end
        end
        entities_to_add[i] = nil
        i = i + 1
    end
    return added_entities, networks
end


-- used for random colors for different networks
local function hash(number)
    return (number * 15091509710923 + 4398608123) % 1092032804
end

local function get_color_and_offset(player, wire_type, network_id, return_half_color)
    local offset_value = .125
    local color = {0, 0, 0, 0}
    local offset = {x = 0, y = 0}
    if wire_type == defines.wire_type.red then
        color = settings.get_player_settings(player)[NAMESPACE .. "red_network_color"].value
        offset = {x = offset_value, y = -offset_value}
    elseif wire_type == defines.wire_type.green then
        color = settings.get_player_settings(player)[NAMESPACE .. "green_network_color"].value
        offset = {x = -offset_value, y = offset_value}
    end
    local max_brightness_change = settings.get_player_settings(player)[NAMESPACE .. "max_brightness_change"].value
    local brightness
    if max_brightness_change ~= 0 then
        brightness = ((hash(network_id) / 31098759) % (max_brightness_change * 2)) - max_brightness_change + 1
    else
        brightness = 1
    end
    color.a = settings.get_player_settings(player)[NAMESPACE .. "overlay_opacity"].value
    if return_half_color then
        color.a = color.a / 2
    end
    color.r = math.min(color.r * color.a * brightness, 1)
    color.g = math.min(color.g * color.a * brightness, 1)
    color.b = math.min(color.b * color.a * brightness, 1)
    return color, offset
end

-- offset for combinator inputs and outputs
local function get_extra_offset(entity, connector_id)
    if INPUT_OUTPUT_COMBINATORS[entity.type] then
        local offsets = {
            [defines.direction.north] = {x = 0, y = -0.5},
            [defines.direction.south] = {x = 0, y = 0.5},
            [defines.direction.west] = {x = -0.5, y = 0},
            [defines.direction.east] = {x = 0.5, y = 0},
        }
        local offset = offsets[entity.direction]
        if connector_id == defines.circuit_connector_id.combinator_input then
            offset.x = -offset.x
            offset.y = -offset.y
        end
        return offset
    else
        return {x = 0, y = 0}
    end
end

-- offset from the node circle
local function get_node_offset(node, target, offset_x, offset_y, dtx, dty)
    local x1 = node.position.x + offset_x
    local y1 = node.position.y + offset_y
    local x2 = target.position.x + dtx
    local y2 = target.position.y + dty
    local dx = x2 - x1
    local dy = y2 - y1
    local l = math.sqrt(dx * dx + dy * dy)
    if l == 0.0 then
        return { x = 0, y = 0 }
    end
    dx = dx / l
    dy = dy / l
    return { x = 0.25 * dx, y = 0.25 * dy }
end

local function visualize_entity(player, entity, visualize_network)
    -- check if player and entity even exist
    if not player or not entity or not entity.unit_number then return end
    -- check if entity should be visible to the player
    if entity.render_player and entity.render_player ~= player then return end
    if entity.render_to_forces and entity.render_to_forces[player.force] then return end
    -- setup all the data
    setup_player_data(player.index)
    global[player.index].entities[entity.unit_number] = global[player.index].entities[entity.unit_number] or {
        entity = entity,
        rendered_objects = {length = 0},
        visualized_connections = {},
    }
    local entity_data = global[player.index].entities[entity.unit_number]
    -- remove old visualizations and data
    if entity_data.rendered_objects.length > 0 then
        for i = 0, entity_data.rendered_objects.length - 1 do
            rendering.destroy(entity_data.rendered_objects[i])
        end
    end
    entity_data.rendered_objects = {length = 0}
    entity_data.visualized_connections = {length = 0}
    --- render new connections and nodes
    local rendered_objects = entity_data.rendered_objects
    local visualized_connections = entity_data.visualized_connections
    local network_colors_and_offsets = {} -- {[network_id] = {color = color, offset = offset}}
    -- render connections
    for _, connection in ipairs(entity.circuit_connection_definitions or {}) do
        local network_id = entity.get_circuit_network(connection.wire, connection.source_circuit_id).network_id
        local in_correct_network = visualize_network == nil or visualize_network(network_id)
        if in_correct_network then
            local color, color_offset = get_color_and_offset(player, connection.wire, network_id, false)
            local extra_from_offset = get_extra_offset(entity, connection.source_circuit_id)
            if connection.target_entity.unit_number and connection.target_entity.unit_number <= entity.unit_number and entity.surface == connection.target_entity.surface then
                local extra_to_offset = get_extra_offset(connection.target_entity, connection.target_circuit_id)
                local from_offset_x = color_offset.x + extra_from_offset.x
                local from_offset_y = color_offset.y + extra_from_offset.y
                local to_offset_x = color_offset.x + extra_to_offset.x
                local to_offset_y = color_offset.y + extra_to_offset.y
                local node_offset = get_node_offset(entity, connection.target_entity, from_offset_x, from_offset_y,
                    to_offset_x, to_offset_y)
                local line = rendering.draw_line {
                    color = color,
                    width = 2,
                    from = entity,
                    to = connection.target_entity,
                    from_offset = {
                        x = color_offset.x + extra_from_offset.x + node_offset.x,
                        y = color_offset.y + extra_from_offset.y + node_offset.y,
                    },
                    to_offset = {
                        x = color_offset.x + extra_to_offset.x - node_offset.x,
                        y = color_offset.y + extra_to_offset.y - node_offset.y,
                    },
                    surface = entity.surface,
                    players = {player},
                }
                rendered_objects[rendered_objects.length] = line
                rendered_objects.length = (rendered_objects.length or 0) + 1
            end

            if connection.target_entity.unit_number then
                visualized_connections[connection.target_entity.unit_number] = in_correct_network
            end
            
            network_colors_and_offsets[network_id] = {
                color = color,
                offset = {
                    x = color_offset.x + extra_from_offset.x,
                    y = color_offset.y + extra_from_offset.y,
                }
            }

            if connection.target_entity.unit_number == entity.unit_number then
                network_colors_and_offsets[network_id].offset_2 = {
                    x = color_offset.x - extra_from_offset.x,
                    y = color_offset.y - extra_from_offset.y,
                }
            end
        end
    end
    -- nothing was rendered
    if visualized_connections == {} then
        global[player.index].entities[entity.unit_number] = nil
        return
    end
    script.register_on_entity_destroyed(entity)
    -- render nodes
    for _, network_data in pairs(network_colors_and_offsets) do
        local circle = rendering.draw_circle{
            color = network_data.color,
            filled = true,
            radius = 0.125,
            target = entity,
            target_offset = network_data.offset,
            surface = entity.surface,
            players = {player},
        }
        rendered_objects[rendered_objects.length] = circle
        rendered_objects.length = (rendered_objects.length or 0) + 1
        if network_data.offset_2 then
            local circle = rendering.draw_circle{
                color = network_data.color,
                filled = true,
                radius = 0.125,
                target = entity,
                target_offset = network_data.offset_2,
                surface = entity.surface,
                players = {player},
            }
            rendered_objects[rendered_objects.length] = circle
            rendered_objects.length = (rendered_objects.length or 0) + 1
        end
    end
end

local function is_entity_visible(from, entity)
    local viev_distance = VIEV_DISTANCE - 10
    if not entity then return false end
    if not from.surface == entity.surface.index then
        return false
    end
    return entity.position.x > from.position.x - viev_distance and entity.position.x < from.position.x + viev_distance and
        entity.position.y > from.position.y - viev_distance and entity.position.y < from.position.y + viev_distance
end

local function get_visible_entities(from)
    local surface = game.get_surface(from.surface)
    if not surface then return {} end
    return surface.find_entities({{from.position.x - VIEV_DISTANCE, from.position.y - VIEV_DISTANCE}, {from.position.x + VIEV_DISTANCE, from.position.y + VIEV_DISTANCE}})
end

-- returns a function which tells which network connections should be drawn, or nil for all networks
local function in_which_networks_entity_should_be_drawn(player, entity)
    if not player or not entity then return end
    local is_overlay_on = player.is_shortcut_toggled(NAMESPACE .. "toggle_overlay")
    if is_overlay_on then
        setup_player_data(player.index)
        local from = {
            position = global[player.index].position or player.position,
            surface = global[player.index].surface or player.surface.index,
        }
        local is_visible = is_entity_visible(from, entity)
        if is_visible then
            return nil
        end
        --return function(network_id) return false end
    end
    setup_player_data(player.index)
    local selected_networks = global[player.index].selected_networks or {}
    local visualized_networks = global[player.index].visualized_networks or {}
    return function(network_id)
        if visualized_networks[network_id] then
            return 1
        elseif selected_networks[network_id] then
            return 0
        else
            return false
        end
    end
end

local function update(player, entity)
    if is_entity_valid(entity) then
        visualize_entity(player, entity, in_which_networks_entity_should_be_drawn(player, entity))
    end
end

local function queue_update(player, entity)
    if entity and entity.unit_number then
        local queue = setup_player_data(player.index).entities_to_update
        Queue.push(queue, entity, entity.unit_number)
    end
end

local function destroy_all_rendered_objects(player_index)
    global[player_index] = global[player_index] or {entities = {}, visualized_networks = {}}
    for _, entity_data in pairs(global[player_index].entities) do
        if entity_data.rendered_objects.length > 0 then
            for i = 0, entity_data.rendered_objects.length - 1 do
                rendering.destroy(entity_data.rendered_objects[i])
            end
        end
        entity_data.rendered_objects = {length = 0}
    end
end

-- used to update global[player.index].visualized_networks if networks change their ids
local function update_network_ids(player, entity)
    if not is_entity_valid(entity) then return end
    local entity_data = setup_player_data(player.index).entities[entity.unit_number]
    if not entity_data then return end
    for _, connection in ipairs(entity.circuit_connection_definitions or {}) do
        if connection.target_entity.unit_number and entity_data.visualized_connections[connection.target_entity.unit_number] == 1 then
            local network_id = entity.get_circuit_network(connection.wire, connection.source_circuit_id).network_id
            global[player.index].visualized_networks[network_id] = true
        end
    end
end


-- the mod visualized entities areound the selected entity insted of the player position for radar compatibility
local function on_position_changed(player, previous, next)
    if player.is_shortcut_toggled(NAMESPACE .. "toggle_overlay") then
        --- update all entities that were visible but now aren't and all entities that are visible but wern't
        -- update old
        for _, entity in ipairs(get_visible_entities(previous)) do
            if is_entity_valid(entity) and entity.circuit_connection_definitions then
                local was_visible = is_entity_visible(previous, entity)
                local is_visible = is_entity_visible(next, entity)
                if was_visible ~= is_visible then
                    queue_update(player, entity)
                end
            end
        end
        -- update new
        for _, entity in ipairs(get_visible_entities(next)) do
            if is_entity_valid(entity) and entity.circuit_connection_definitions then
                local was_visible = is_entity_visible(previous, entity)
                local is_visible = is_entity_visible(next, entity)
                if was_visible ~= is_visible then
                    queue_update(player, entity)
                end
            end
        end
    end
end

local function hide_all_networks(player) -- Make it hide all networks just for one player instead of all players
    destroy_all_rendered_objects(player.index)
    global[player.index] = nil
    player.set_shortcut_toggled(NAMESPACE .. "toggle_overlay", false)
end

local function update_all_entities(player)
    -- update all visible entities
    setup_player_data(player.index)
    local from = {
        position = global[player.index].position or player.position,
        surface = global[player.index].surface or player.surface.index,
    }
    for _, entity in ipairs(get_visible_entities(from)) do
        queue_update(player, entity)
    end
    -- update all visualized entities
    for _, entity_data in pairs(global[player.index].entities) do
        queue_update(player, entity_data.entity)
    end
end

local function on_toggle_overlay(player, toggled_on)
    --- update all visible entities
    setup_player_data(player.index)
    local from = {
        position = global[player.index].position or player.position,
        surface = global[player.index].surface or player.surface.index,
    }
    for _, entity in ipairs(get_visible_entities(from)) do
        queue_update(player, entity)
    end
end

local function on_visualize_network(player, selected_entity)
    --- update all connected entities
    -- check if player and entity exist
    if not player or not is_entity_valid(selected_entity) then return end
    -- prepare variables
    setup_player_data(player.index)
    local whole_network_visualization = player.is_shortcut_toggled(NAMESPACE .. "toggle_whole_network")
    local connected_networks = get_connected_networks(selected_entity)
    local is_already_visualized = false
    for network_id, _ in pairs(connected_networks) do
        if global[player.index].visualized_networks[network_id] then
            is_already_visualized = true
            break
        end
    end
    -- add/remove networks and update entities
    if whole_network_visualization then
        local entities, networks = get_connected_entities(selected_entity)
        for network_id, _ in pairs(networks) do
            global[player.index].visualized_networks[network_id] = not is_already_visualized
        end
        for entity, _ in pairs(entities) do
            queue_update(player, entity)
        end
    else
        for connected_network_id, _ in pairs(connected_networks) do
            local entities, networks = get_connected_entities(selected_entity, connected_network_id)
            for network_id, _ in pairs(networks) do
                global[player.index].visualized_networks[network_id] = not is_already_visualized
            end
            for entity, _ in pairs(entities) do
                queue_update(player, entity)
            end
        end
    end
end

-- when position changes only by a few tiles it's pointles to update a lot of entities so this function rounds down position to the nearest chunk corner
local function chunk_floor(position)
    local chunk_size = 32
    return {
        x = position.x - position.x % chunk_size,
        y = position.y - position.y % chunk_size,
    }
end

local function on_entity_selected(player, previous_entity)
    if player.is_shortcut_toggled(NAMESPACE .. "toggle_mouseover") then
        --- update all entities conected to previous and new network
        -- prepare variables
        setup_player_data(player.index)
        local whole_network_visualization = player.is_shortcut_toggled(NAMESPACE .. "toggle_whole_network")
        local selected_entity = player.selected
        -- set selected_networks and update selected entities
        if is_entity_valid(selected_entity) then
            if whole_network_visualization then
                local entities
                entities, global[player.index].selected_networks = get_connected_entities(selected_entity)
                for entity, _ in pairs(entities) do
                    queue_update(player, entity)
                end
            else
                local connected_networks = get_connected_networks(selected_entity)
                global[player.index].selected_networks = connected_networks
                for connected_network_id, _ in pairs(connected_networks) do
                    local entities, _ = get_connected_entities(selected_entity, connected_network_id)
                    for entity, _ in pairs(entities) do
                        queue_update(player, entity)
                    end
                end
            end
        else
            global[player.index].selected_networks = {}
        end
        if is_entity_valid(previous_entity) then
            -- update entities connected to previous_entity
            if whole_network_visualization then
                local entities, _ = get_connected_entities(previous_entity)
                for entity, _ in pairs(entities) do
                    queue_update(player, entity)
                end
            else
                for connected_network_id, _ in pairs(get_connected_networks(previous_entity)) do
                    local entities, _ = get_connected_entities(previous_entity, connected_network_id)
                    for entity, _ in pairs(entities) do
                        queue_update(player, entity)
                    end
                end
            end
        end
    end
    if is_entity_valid(player.selected) then
        setup_player_data(player.index)
        local previous_surface = global[player.index].surface or player.surface.index
        local previous_positon = global[player.index].position or player.position
        local next_surface = player.selected.surface.index
        local next_position = player.selected.position
        next_position = chunk_floor(next_position)
        local position_changed = previous_surface ~= next_surface or previous_positon.x ~= next_position.x or previous_positon.y ~= next_position.y
        if position_changed then
            global[player.index].surface = next_surface
            global[player.index].position = next_position
            on_position_changed(player, {position = previous_positon, surface = previous_surface}, {position = next_position, surface = next_surface})
        end
    end
end

local function on_entity_destroyed(player, entity_id)
    setup_player_data(player.index)
    local visualized_connections = global[player.index].entities[entity_id].visualized_connections
    for connected_entity_id, connection_type in pairs(visualized_connections) do
        local connected_entity = (global[player.index].entities[connected_entity_id] or {}).entity
        if is_entity_valid(connected_entity) then
            -- add visualized networks
            if connection_type == 1 then
                local second_visualized_connections = global[player.index].entities[connected_entity_id].visualized_connections
                for _, connection in ipairs(connected_entity.circuit_connection_definitions or {}) do
                    if connection.target_entity.unit_number and second_visualized_connections[connection.target_entity.unit_number] then
                        global[player.index].visualized_networks[connected_entity.get_circuit_network(connection.wire, connection.source_circuit_id).network_id] = true
                    end
                end
            end
            -- update all connected entities
            for entity, _ in pairs(get_connected_entities(connected_entity)) do
                queue_update(player, entity)
            end
        end
    end
    global[player.index].entities[entity_id] = nil
end

local function on_connections_changed(player, entity, created)
    local entity_data = global[player.index].entities[entity.unit_number]
    if entity_data then
        if not created then
            update_network_ids(player, entity)
        end
        for entity_to_update, _ in pairs(get_connected_entities(entity)) do
            queue_update(player, entity_to_update)
        end
        for connected_entity_id, _ in pairs(entity_data.visualized_connections) do
            local connected_entity_data = global[player.index].entities[connected_entity_id]
            if connected_entity_data then
                if not created then
                    update_network_ids(player, connected_entity_data.entity)
                end
                for entity_to_update, _ in pairs(get_connected_entities(connected_entity_data.entity)) do
                    queue_update(player, entity_to_update)
                end
            end
        end
    else
        queue_update(player, entity)
        for _, connected_entities in pairs(entity.circuit_connected_entities) do
            for _, entity_to_update in ipairs(connected_entities) do
                queue_update(player, entity_to_update)
            end
        end
    end
end

local function on_tick(player)
    if is_entity_valid(player.selected) then
        setup_player_data(player.index)
        local previous_entity_id = global[player.index].selected_entity.id
        local previous_connection_count = global[player.index].selected_entity.connection_count
        local current_entity_id = player.selected.unit_number
        local current_connection_count = #(player.selected.circuit_connection_definitions or {})
        global[player.index].selected_entity.id = current_entity_id
        global[player.index].selected_entity.connection_count = current_connection_count
        if previous_entity_id == current_entity_id and previous_connection_count ~= current_connection_count then
            on_entity_selected(player, nil)
            for player_id, _ in pairs(global) do
                local player_to_iterate = game.get_player(player_id)
                if player_to_iterate then
                    on_connections_changed(player_to_iterate, player.selected, previous_connection_count < current_connection_count)
                end
            end
        end
    end
    local queue = (global[player.index] or {}).entities_to_update
    if queue and not Queue.is_empty(queue) then
        for _ = 1, ENTITIES_PER_TICK do
            local entity = Queue.pop(queue)
            if not entity then
                break
            else
                update(player, entity)
            end
        end
    end
end

commands.add_command("circuit_visualizer_hide_networks", nil,
    function(event)
        local player = game.get_player(event.player_index)
        if event.parameter == "all" and player and player.admin then
            rendering.clear("circuit_visualizer")
            for player_id, _ in pairs(global) do
                global[player_id] = nil
                local current_player = game.get_player(player_id)
                current_player.set_shortcut_toggled(NAMESPACE .. "toggle_overlay", false)
            end
        elseif player then
            hide_all_networks(player)
        end
    end
)

script.on_event(defines.events.on_lua_shortcut,
    function(event)
        local toggleable_shortcuts = {
            [NAMESPACE .. "toggle_overlay"] = true,
            [NAMESPACE .. "toggle_mouseover"] = true,
            [NAMESPACE .. "toggle_whole_network"] = true,
        }
        local player = game.get_player(event.player_index)
        if not player then return end
        if toggleable_shortcuts[event.prototype_name] then
            local name = event.input_name or event.prototype_name
            local toggled_on = player.is_shortcut_toggled(name)
            player.set_shortcut_toggled(name, not toggled_on)
            if name == NAMESPACE .. "toggle_overlay" then
                on_toggle_overlay(player, not toggled_on)
            end
        elseif event.prototype_name == NAMESPACE .. "hide_all" then
            hide_all_networks(game.get_player(event.player_index))
        elseif event.prototype_name == NAMESPACE .. "reload_all" then
            update_all_entities(player)
        end
    end
)

script.on_event(NAMESPACE .. "visualize_network",
    function(event)
        local player = game.get_player(event.player_index)
        if not player then return end
        local selected_entity = player.selected
        if not selected_entity then return end
        if not selected_entity.unit_number then return end
        on_visualize_network(player, selected_entity)
    end
)

script.on_event(defines.events.on_selected_entity_changed,
    function(event)
        on_entity_selected(game.get_player(event.player_index), event.last_entity)
    end
)

script.on_event(defines.events.on_entity_destroyed,
    function(event)
        if not event.unit_number then return end
        for player_index, _ in pairs(global or {}) do
            local player = game.get_player(player_index)
            if player then
                if (global[player_index] or {entities = {}}).entities[event.unit_number] then
                    on_entity_destroyed(player, event.unit_number)
                    global[player_index].entities[event.unit_number] = nil
                end
            end
        end
    end
)

script.on_event(defines.events.on_tick,
    function(event)
        for player_index, _ in pairs(global or {}) do
            local player = game.get_player(player_index)
            if player then
                on_tick(player)
            end
        end
    end
)
