local Event = require 'utils.event_core' --- @dep utils.event_core

local function auto_handle(ore)
    if ore.name == 'uranium-ore' or ore.name == 'crude-oil' then
        return nil
    end

    local miner = ore.surface.find_entities_filtered{area={{ore.position.x-1, ore.position.y-1}, {ore.position.x+1, ore.position.y+1}}, type='mining-drill'}
    local resources = miner.surface.find_entities_filtered{area={{miner.position.x - miner.prototype.mining_drill_radius, miner.position.y - miner.prototype.mining_drill_radius}, {miner.position.x + miner.prototype.mining_drill_radius, miner.position.y + miner.prototype.mining_drill_radius}}, type='resource'}

    for _, resource in pairs(resources) do
        if resource.amount > 0 then
            return nil
        end
    end

    miner.order_deconstruction(miner.force)
end

if #game.active_mods = 1 then
    Event.add(defines.events.on_resource_depleted, function(event)
        auto_handle(event.entity)
    end)
end
