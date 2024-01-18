--[[-- Control Module - shared spawn
    - a shared base of individual spawn
    @control shared spawn
]]

local Global = require 'utils.global' --- @dep utils.global
local Event = require 'utils.event' --- @dep utils.event
local Commands = require 'expcore.commands' --- @dep expcore.commands
local config = require 'config.shared_spawn' --- @dep config.vlayer

local shared_spawn = {}
local shared_spawn_data = {
    base = {},
    shared_base = {}
}

Global.register(shared_spawn_data, function(tbl)
    shared_spawn_data = tbl
end)

function shared_spawn.base_create(player, location)
    if shared_spawn_data.base[player.name] then
        return
    end

    shared_spawn_data.base[player.name] = {
        location = location,
        player = {player.name}
    }

    local tiles_to_make = {}

    for x=-config.deconstruction_radius, config.deconstruction_radius do
        for y=-config.deconstruction_radius, config.deconstruction_radius do
            if math.max(x, y) > config.base_radius then
                table.insert(tiles_to_make, {name=config.deconstruction_tile, position={x=location.x+x, y=location.y+y}})

            else
                table.insert(tiles_to_make, {name=config.base_tile, position={x=location.x+x, y=location.y+y}})
            end
        end
    end

    for x=math.floor(config.deconstruction_radius / 2) - 4, math.floor(config.deconstruction_radius / 2) + 4 do
        for y=config.base_radius, config.deconstruction_radius do
            table.insert(tiles_to_make, {name=config.base_tile, position={x=location.x+x, y=location.y+y}})
        end
    end

    -- Remove entities then set the tiles
    local entities_to_remove = player.surface.find_entities_filtered{position=location, radius=config.deconstruction_radius, name='character', invert=true}

    for _, entity in pairs(entities_to_remove) do
        entity.destroy()
    end

    player.surface.set_tiles(tiles_to_make)

    if config.resource_tiles.enabled then
        for _, v in ipairs(config.resource_tiles.resources) do
            if v.enabled then
                local pos_x = location.x + v.offset[1]
                local pos_y = location.y + v.offset[2]

                for x=pos_x, pos_x + v.size[1] do
                    for y=pos_y, pos_y + v.size[2] do
                        player.surface.create_entity({name=v.name, amount=v.amount, position={x=x, y=y}})
                    end
                end
            end
        end
    end

    if config.resource_patches.enabled then
        for _, v in ipairs(config.resource_patches.resources) do
            if v.enabled then
                local pos_x = location.x + v.offset[1] - math.floor(v.offset_next[1] / 2)
                local pos_y = location.y + v.offset[2] - math.floor(v.offset_next[2] / 2)

                for i=1, v.num_patches do
                    player.surface.create_entity({name=v.name, amount=v.amount, position={x=pos_x + v.offset_next[1] * (i - 1), y=pos_y + v.offset_next[2] * (i - 1)}})
                end
            end
        end
    end

    
end

Commands.new_command('create-base-individual-spawn', 'Create a individual spawn for the shared base')
:register(function(player)
    shared_spawn.base_create(player, {x=-176, y=-176})
end)

return shared_spawn
