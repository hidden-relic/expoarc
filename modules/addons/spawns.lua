local Event = require 'utils.event'
local config = require 'config.oarc'
local Global = require 'utils.global'
local vlayer = require 'modules.control.vlayer'
local crash_site = require 'crash-site'
local advanced_start = require 'modules.addons.advanced-start'

local player_spawns = {}
Global.register(player_spawns, function(tbl)
    player_spawns = tbl
end)

local spawns = {}

local function create_crash_site(position)
    crash_site.create_crash_site(game.surfaces['oarc'], {
        x = position.x + 15,
        y = position.y - 25
    }, {
        ["gun-turret"] = 2,
        ["electronic-circuit"] = math.random(100, 200),
        ["iron-gear-wheel"] = math.random(50, 100),
        ["copper-cable"] = math.random(100, 200),
        ["steel-plate"] = math.random(50, 100)
    }, {["iron-plate"] = math.random(50, 100)})
end

local function get_distance(pos1, pos2)
    local pos1 = {x = pos1.x or pos1[1], y = pos1.y or pos1[2]}
    local pos2 = {x = pos2.x or pos2[1], y = pos2.y or pos2[2]}
    local a = math.abs(pos1.x - pos2.x)
    local b = math.abs(pos1.y - pos2.y)
    local c = math.sqrt(a ^ 2 + b ^ 2)
    return c
end

local function tp(player, position, surface)
    local surface = surface or player.surface
    player.teleport(surface.find_non_colliding_position('character', position, 32, 1), surface.name)
end

local function get_near_spawn_position()
    local distance = 0
    local near_distance = config.near_distance
    local min, max = near_distance.min, near_distance.max
    local t = {}
    while (distance < min or distance > max) do
        t.x, t.y = math.random(-max, max), math.random(-max, max)
        distance = get_distance({x=0, y=0}, t)
    end
    return t
end

local function get_far_spawn_position()
    local distance = 0
    local far_distance = config.far_distance
    local min, max = far_distance.min, far_distance.max
    local t = {}
    while (distance < min or distance > max) do
        t.x, t.y = math.random(-max, max), math.random(-max, max)
        distance = get_distance({x=0, y=0}, t)
    end
    return t
end

local function check_distance_from_players(position)
    for name, spawn in pairs(player_spawns) do
        if get_distance(position, spawn) <= config.distance_from_another_player then
            return false
        end
    end
    return true
end

local function downgrade_area(position)
    
    local bug_table = {
        ["small-biter"] = false,
        ["medium-biter"] = "small-biter",
        ["big-biter"] = "medium-biter",
        ["behemoth-biter"] = "big-biter",
        ["small-spitter"] = false,
        ["medium-spitter"] = "small-spitter",
        ["big-spitter"] = "medium-spitter",
        ["behemoth-spitter"] = "big-spitter",
        ["medium-worm-turret"] = "small-worm-turret",
        ["big-worm-turret"] = "medium-worm-turret",
        ["behemoth-worm-turret"] = "big-worm-turret",
        ["biter-spawner"] = false,
        ["spitter-spawner"] = false
    }
    local instant_bug_table = {
        ["small-biter"] = false,
        ["medium-biter"] = "small-biter",
        ["big-biter"] = "small-biter",
        ["behemoth-biter"] = "small-biter",
        ["small-spitter"] = false,
        ["medium-spitter"] = "small-spitter",
        ["big-spitter"] = "small-spitter",
        ["behemoth-spitter"] = "small-spitter",
        ["medium-worm-turret"] = "small-worm-turret",
        ["big-worm-turret"] = "small-worm-turret",
        ["behemoth-worm-turret"] = "small-worm-turret",
        ["biter-spawner"] = false,
        ["spitter-spawner"] = false
    }
    local surface = game.surfaces['oarc']
    
    for name, zone in pairs(config.zones) do
        if zone.full_downgrade then
            for current, downgrade in pairs(instant_bug_table) do
                for i, bug in pairs(surface.find_entities_filtered{name=current, force="enemy", position=position, radius=zone.radius}) do
                    if bug and bug.valid then
                        if downgrade then
                            surface.create_entity{name=downgrade, position=bug.position, force="enemy"}
                        end
                        bug.destroy()
                    end
                end
            end
        else
            for current, downgrade in pairs(bug_table) do
                for i, bug in pairs(surface.find_entities_filtered{name=current, force="enemy", position=position, radius=zone.radius}) do
                    if math.random(1, 10) <= zone.probability then
                        if bug and bug.valid then
                            if not zone.instant_death then
                                if downgrade then
                                    surface.create_entity{name=downgrade, position=bug.position, force="enemy"}
                                end
                            end
                            bug.destroy()
                        end
                    end
                end
            end
        end
    end
end

local function fy_shuffle(tInput)
    local tReturn = {}
    for i = #tInput, 1, -1 do
        local j = math.random(i)
        tInput[i], tInput[j] = tInput[j], tInput[i]
        table.insert(tReturn, tInput[i])
    end
    return tReturn
end

local function create_water_strip(surface, leftPos, length)
    local waterTiles = {}
    for i = 0, length, 1 do
        table.insert(waterTiles,
        {name = "water", position = {leftPos.x + i, leftPos.y}})
    end
    surface.set_tiles(waterTiles)
end

local function generate_resource_patch(surface, resourceName, diameter, pos, amount)
    local midPoint = math.floor(diameter / 2)
    if (diameter == 0) then return end
    for y = -midPoint, midPoint do
        for x = -midPoint, midPoint do
            surface.create_entity({
                name = resourceName,
                amount = amount,
                position = {pos.x + x, pos.y + y}
            })
        end
    end
end

local function generate_starting_resources(surface, pos)
    local rand_settings = config.resources.ore.random
    local tiles = config.resources.ore.tiles
    local r_list = {}
    for k, _ in pairs(tiles) do
        if (k ~= "") then table.insert(r_list, k) end
    end
    local shuffled_list = fy_shuffle(r_list)
    local angle_offset = rand_settings.angle_offset
    local num_resources = table_size(tiles)
    local theta = ((rand_settings.angle_final - rand_settings.angle_offset) /
    num_resources);
    local count = 0
    
    for _, k_name in pairs(shuffled_list) do
        local angle = (theta * count) + angle_offset;
        
        local tx = (rand_settings.radius * math.cos(angle)) + pos.x
        local ty = (rand_settings.radius * math.sin(angle)) + pos.y
        
        local pos = {x = math.floor(tx), y = math.floor(ty)}
        generate_resource_patch(surface, k_name, config.resources.ore.size, pos, tiles[k_name].amount)
        count = count + 1
    end
    
    local crude = config.resources["crude-oil"]
    local oil_patch_x = pos.x + crude.x_offset_start
    local oil_patch_y = pos.y + crude.y_offset_start
    for i = 1, crude.num_patches do
        surface.create_entity({
            name = "crude-oil",
            amount = crude.amount,
            position = {oil_patch_x, oil_patch_y}
        })
        oil_patch_x = oil_patch_x + crude.x_offset_next
        oil_patch_y = oil_patch_y + crude.y_offset_next
    end
    
    local water_data = config.resources.water
    create_water_strip(surface, {
        x = pos.x + water_data.offset.x,
        y = pos.y + water_data.offset.y
    }, water_data.length)
    create_water_strip(surface, {
        x = pos.x + water_data.offset.x,
        y = pos.y + water_data.offset.y + 1
    }, water_data.length)
end

local function create_shared_entities(player, center)
    local vlayer_entities = {
        input_chest = {x=center.x + config.resources.ore.random.radius, y = center.y - 8},
        output_chest = {x=center.x + config.resources.ore.random.radius, y = center.y + 7},
        combinator = {x=center.x + config.resources.ore.random.radius + 1, y = center.y},
        output_power = {x=center.x + config.resources.ore.random.radius, y = center.y}
    }
    vlayer.create_input_interface(game.surfaces['oarc'], vlayer_entities.input_chest, player.name)
    vlayer.create_output_interface(game.surfaces['oarc'], vlayer_entities.output_chest, player.name)
    vlayer.create_energy_interface(game.surfaces['oarc'], vlayer_entities.output_power, player.name)
    vlayer.create_circuit_interface(game.surfaces['oarc'], vlayer_entities.combinator, player.name)
    
    local tiles = {}
    for x=(vlayer_entities.input_chest.x-2), (vlayer_entities.output_chest.x+2), 1 do
        for y=(vlayer_entities.input_chest.y-2), (vlayer_entities.output_chest.y+2), 1 do
            table.insert(tiles, {name = "tutorial-grid", position = {x,y}})
        end
    end
    game.surfaces['oarc'].set_tiles(tiles)
end


local function create_new_spawn(player, center)    
    local results = {}
    local radius = config.spawn_radius
    local rad_sq = radius ^ 2
    local border = radius*math.pi
    local surface = game.surfaces['oarc']
    
    downgrade_area(center)
    
    local area = {top_left={x=center.x-radius, y=center.y-radius}, bottom_right={x=center.x+radius, y=center.y+radius}}
    
    for _, entity in pairs(surface.find_entities_filtered{position=center, radius=radius}) do
        if entity.type ~= 'character' then
            entity.destroy()
        end
    end
    
    for i = area.top_left.x, area.bottom_right.x, 1 do
        for j = area.top_left.y, area.bottom_right.y, 1 do
            
            local dist = math.floor((center.x - i) ^ 2 + (center.y - j) ^ 2)
            
            if (dist < rad_sq) then
                table.insert(results, {name = "landfill", position ={i,j}})
                
                if ((dist < rad_sq) and
                (dist > rad_sq-border)) then
                    surface.create_entity({name="tree-02", force=player.force, position={i, j}})
                end
            end
        end
    end
    
    surface.set_tiles(results)
    generate_starting_resources(surface, center)
    create_crash_site(center)
    create_shared_entities(player, center)
    
    player.force.chart(surface, area)
    tp(player, center, surface)
    advanced_start(player)
end

function spawns.distance_chosen(player, choice)
    local surface = game.surfaces['oarc']
    local get_position = choice == 'near' and get_near_spawn_position or get_far_spawn_position
    local spawn_position = get_position()
    while not check_distance_from_players(spawn_position) do
        spawn_position = get_position()
    end
    player_spawns[player.name] = {
        position = spawn_position
    }
    surface.request_to_generate_chunks(spawn_position, config.zones.yellow_zone.radius/32)
    surface.force_generate_chunk_requests()
    local chunk_generated = surface.is_chunk_generated({x=spawn_position.x/32, y=spawn_position.y/32})
    while not chunk_generated do
        chunk_generated = surface.is_chunk_generated({x=spawn_position.x/32, y=spawn_position.y/32})
    end
    create_new_spawn(player, spawn_position)
end

function spawns.get_spawn(player_name)
    if player_spawns[player_name] then
        return player_spawns[player_name]
    else
        return false
    end
end

function spawns.clear_spawn(player_name)
    if player_spawns[player_name] then
        player_spawns[player_name] = nil
    end
end

local function get_surrounding_positions(position, n)
    local t = {}
    for x=position.x-n, position.x+n do
        for y=position.y-n, position.y+n do
            table.insert(t, {x=x, y=y})
        end
    end
    return t
end

function spawns.reset_player(player)
    if not player.opened then
        player.gui.center.clear()
    end
    local center = spawns.get_spawn(player.name)
    if center then
        local center_chunk = {x=center.position.x/32, y=center.position.y/32}
        local area = get_surrounding_positions(center_chunk, math.ceil((config.zones.green_zone.radius/32)/2))
        spawns.clear_spawn(player.name)
        player.get_inventory(defines.inventory.character_main).clear()
        player.get_inventory(defines.inventory.character_guns).clear()
        player.get_inventory(defines.inventory.character_ammo).clear()
        player.get_inventory(defines.inventory.character_armor).clear()
        player.get_inventory(defines.inventory.character_trash).clear()
        tp(player, {x=0, y=0}, game.surfaces['oarc'])
        for _, chunk in pairs(area) do
            player.surface.delete_chunk(chunk)
        end
    end
end

local function adjust_map_gen(settings)
    settings.terrain_segmentation = 1
    settings.water = 1
    settings.starting_area = 1
    
    local r_freq = 1.50
    local r_rich = 2.00
    local r_size = 1.00
    
    settings.autoplace_controls["coal"].frequency = r_freq
    settings.autoplace_controls["coal"].richness = r_rich
    settings.autoplace_controls["coal"].size = r_size
    settings.autoplace_controls["copper-ore"].frequency = r_freq
    settings.autoplace_controls["copper-ore"].richness = r_rich
    settings.autoplace_controls["copper-ore"].size = r_size
    settings.autoplace_controls["crude-oil"].frequency = r_freq
    settings.autoplace_controls["crude-oil"].richness = r_rich
    settings.autoplace_controls["crude-oil"].size = r_size
    settings.autoplace_controls["iron-ore"].frequency = r_freq
    settings.autoplace_controls["iron-ore"].richness = r_rich
    settings.autoplace_controls["iron-ore"].size = r_size
    settings.autoplace_controls["stone"].frequency = r_freq
    settings.autoplace_controls["stone"].richness = r_rich
    settings.autoplace_controls["stone"].size = r_size
    settings.autoplace_controls["uranium-ore"].frequency = r_freq * 0.5
    settings.autoplace_controls["uranium-ore"].richness = r_rich
    settings.autoplace_controls["uranium-ore"].size = r_size
    
    settings.autoplace_controls["enemy-base"].frequency = 1
    settings.autoplace_controls["enemy-base"].richness = 1
    settings.autoplace_controls["enemy-base"].size = 1
    
    settings.autoplace_controls["trees"].frequency = 1.00
    settings.autoplace_controls["trees"].richness = 1.00
    settings.autoplace_controls["trees"].size = 1.00
    
    settings.cliff_settings.cliff_elevation_0 = 3
    settings.cliff_settings.cliff_elevation_interval = 200
    settings.cliff_settings.richness = 1
    
    settings.property_expression_names["control-setting:aux:bias"] = "0.00"
    settings.property_expression_names["control-setting:aux:frequency:multiplier"] =
    "5.00"
    settings.property_expression_names["control-setting:moisture:bias"] = "0.40"
    settings.property_expression_names["control-setting:moisture:frequency:multiplier"] =
    "50"
    
    return settings
end

Event.add(defines.events.on_player_created, function (event)
    local player = game.players[event.player_index]
    if event.player_index == 1 then
        
        game.difficulty_settings.technology_price_multiplier = config.technology_price_multiplier or 1
        
        local surface = game.create_surface('oarc', adjust_map_gen(game.surfaces[1].map_gen_settings))
        surface.request_to_generate_chunks({x=0, y=0}, 2)
        surface.force_generate_chunk_requests()
        local chunk_generated = surface.is_chunk_generated({x=1, y=1})
        while not chunk_generated do
            chunk_generated = surface.is_chunk_generated({x=1, y=1})
        end
        local center_tiles = {}
        local area = {top_left={x=-64, y=-64}, bottom_right={x=64, y=64}}
        
        for _, entity in pairs(surface.find_entities(area)) do
            if entity.type ~= 'character' then
                entity.destroy()
            end
        end
        
        for i = area.top_left.x, area.bottom_right.x, 1 do
            for j = area.top_left.y, area.bottom_right.y, 1 do
                
                local dist = math.floor((0 - i) ^ 2 + (0 - j) ^ 2)
                
                if (dist < (64 ^ 2)) then
                    if (dist < (4 ^ 2)) then
                        table.insert(center_tiles, {name = "black-refined-concrete", position ={i,j}})
                    else
                        table.insert(center_tiles, {name = "out-of-map", position ={i,j}})
                    end
                end
            end
        end
        surface.set_tiles(center_tiles)
    end
    player.get_inventory(defines.inventory.character_main).clear()
    player.get_inventory(defines.inventory.character_guns).clear()
    player.get_inventory(defines.inventory.character_ammo).clear()
    player.get_inventory(defines.inventory.character_armor).clear()
    player.get_inventory(defines.inventory.character_trash).clear()
    tp(player, {x=0, y=0}, game.surfaces['oarc'])
end)

return spawns