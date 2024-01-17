local Event = require 'utils.event_core' --- @dep utils.event_core

local function miner_check(entity)
    -- if any tile in the radius have resources
    if entity.mining_target and entity.mining_target.valid then
        if entity.mining_target.amount > 0 then
            return
        end
    end

    local resources = entity.surface.find_entities_filtered{area={{entity.position.x - entity.prototype.mining_drill_radius, entity.position.y - entity.prototype.mining_drill_radius}, {entity.position.x + entity.prototype.mining_drill_radius, entity.position.y + entity.prototype.mining_drill_radius}}, type='resource'}

    for _, resource in pairs(resources) do
        if resource.amount > 0 then
            return
        end
    end

    if entity.to_be_deconstructed(entity.force) then
        -- if it is already waiting to be deconstruct
        return
    end

    if next(entity.circuit_connected_entities.red) ~= nil or next(entity.circuit_connected_entities.green) ~= nil then
        -- connected to circuit network
        return
    end

    if not entity.minable then
        -- if it is minable
        return
    end

    if not entity.prototype.selectable_in_game then
        -- if it can select
        return
    end

    if entity.has_flag('not-deconstructable') then
        -- if it can deconstruct
        return
    end

    if entity.drop_target then
        if entity.drop_target.minable and entity.drop_target.prototype.selectable_in_game then
            if entity.drop_target.type == 'logistic-container' or entity.drop_target.type == 'container' then
                local chest_handle = true
                local entities = entity.surface.find_entities_filtered{area={{entity.position.x - 1, entity.position.y - 1}, {entity.position.x + 1, entity.position.y + 1}}, type={'mining-drill', 'inserter'}}

                for _, e in pairs(entities) do
                    if e.drop_target == entity.drop_target then
                        if not e.to_be_deconstructed(entity.force) then
                            chest_handle = false
                            break
                        end
                    end
                end

                if chest_handle then
                    entity.drop_target.order_deconstruction(entity.force)
                end
            end
        end
    end

    if entity.fluidbox and #entity.fluidbox > 0 then
        -- if require fluid to mine
        local pipe_build = {{x=0, y=0}}
        local radius = 1 + entity.prototype.mining_drill_radius
        local half = math.floor(entity.get_radius())
        local entities = entity.surface.find_entities_filtered{area={{entity.position.x - radius, entity.position.y - radius}, {entity.position.x + radius, entity.position.y + radius}}, type='mining-drill'}

        for _, e in pairs(entities) do
            if (e.position.x > entity.position.x) and (e.position.y == entity.position.y) then
                for h=1, half do
                    table.insert(pipe_build, {x=h, y=0})
                end

            elseif (e.position.x < entity.position.x) and (e.position.y == entity.position.y) then
                for h=1, half do
                    table.insert(pipe_build, {x=-h, y=0})
                end

            elseif (e.position.x == entity.position.x) and (e.position.y > entity.position.y) then
                for h=1, half do
                    table.insert(pipe_build, {x=0, y=h})
                end

            elseif (e.position.x == entity.position.x) and (e.position.y < entity.position.y) then
                for h=1, half do
                    table.insert(pipe_build, {x=0, y=-h})
                end
            end
        end

        entity.order_deconstruction(entity.force)

        for p=1, #pipe_build do
            entity.surface.create_entity{name='entity-ghost', position={x=entity.position.x + pipe_build[p].x, y=entity.position.y + pipe_build[p].y}, force=entity.force, inner_name='pipe', raise_built=true}
        end

    else
        entity.order_deconstruction(entity.force)
    end 
end

Event.add(defines.events.on_resource_depleted, function(event)
    if event.entity.prototype.infinite_resource then
        return
    end

    local entities = event.entity.surface.find_entities_filtered{area={{event.entity.position.x - 1, event.entity.position.y - 1}, {event.entity.position.x + 1, event.entity.position.y + 1}}, type='mining-drill'}

    if #entities == 0 then
        return
    end

    for _, entity in pairs(entities) do
        if ((math.abs(entity.position.x - event.entity.position.x) < entity.prototype.mining_drill_radius) and (math.abs(entity.position.y - event.entity.position.y) < entity.prototype.mining_drill_radius)) then
            miner_check(entity)
        end
    end
end)
