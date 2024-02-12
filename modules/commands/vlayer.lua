--- Adds a virtual layer to store power to save space.
-- @commands Vlayer

local Commands = require 'expcore.commands' --- @dep expcore.commands
require 'config.expcore.command_general_parse'
local vlayer = require 'modules.control.vlayer'

Commands.new_command('personal-battery-recharge', 'Recharge Player Battery upto a portion with vlayer')
:add_param('amount', 'number-range', 0.2, 1)
:register(function(player, amount)
    local armor = player.get_inventory(defines.inventory.character_armor)[1].grid
    local vlayer_power = vlayer.get_statistics()['energy_storage']

    for i=1, #armor.equipment do
        if armor.equipment[i].energy < (armor.equipment[i].max_energy * amount) then
            local energy_required = math.min((armor.equipment[i].max_energy * amount) - armor.equipment[i].energy, vlayer_power)
            armor.equipment[i].energy = armor.equipment[i].max_energy + energy_required
            vlayer.energy_changed(-energy_required)
        end
    end

    return Commands.success
end)
