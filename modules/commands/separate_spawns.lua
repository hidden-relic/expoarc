--[[-- Commands Module - Separate Spawns
@commands Separate Spawns
]]

local Commands = require 'expcore.commands' --- @dep expcore.commands
local format_chat_player_name = _C.format_chat_player_name --- @dep expcore.common
local spawns = require 'modules.addons.spawns'
require 'config.expcore.command_general_parse'

--- Return information regarding a player's spawn
-- @command info
-- @tparam LuaPlayer player the player that you info on
Commands.new_command('info', 'Sends you info about a player')
:add_alias('whois')
:add_param('player', false, 'player')
:register(function(_, action_player)
    local spawn = spawns.get_spawn(action_player.name)
    local action_player_name_color = format_chat_player_name(action_player)
    if spawn then
        return Commands.success{'expcom-info.response', action_player_name_color, string.format('%.1f', spawn.position.x), string.format('%.1f', spawn.position.y)}
    else
        return Commands.error{'expcom-info.error', action_player_name_color}
    end
end)

--- Input parse for items by name
local function item_parse(input, _, reject)
    if input == nil then return end
    local lower_input = input:lower():gsub(' ', '-')
    
    -- Simple Case - internal name is given
    local item = game.item_prototypes[lower_input]
    if item then return item end
    
    -- Second Case - rich text is given
    local item_name = input:match('%[item=([0-9a-z-]+)%]')
    item = game.item_prototypes[item_name]
    if item then return item end
    
    -- No item found, we do not attempt to search all prototypes as this will be expensive
    return reject{'expcom-inv-search.reject-item', lower_input}
end

Commands.new_command('get', 'Get items')
:add_param('item', false, item_parse)
:add_param('count', true, 'number')
-- :enable_auto_concat()
:register(function(player, item, count)
    local count = count or item.stack_size
    player.insert{name=item.name, count=count}
end)