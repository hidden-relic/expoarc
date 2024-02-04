--- rate calc milestone gui
-- @gui rate-calc

local Gui = require 'expcore.gui' --- @dep expcore.gui
local Roles = require 'expcore.roles' --- @dep expcore.roles

local rate_container =
Gui.element(function(definition, parent)
    local container = Gui.container(parent, definition.name, 200)
	local scroll_table = Gui.scroll_table(container, 400, 4)

	scroll_table.add{
        name = 'clock_text',
        caption = 'Time:',
        type = 'label',
        style = 'heading_1_label'
    }

	scroll_table.add{
        name = 'clock_text_2',
        caption = '',
        type = 'label',
        style = 'heading_1_label'
    }

    return container.parent
end)
:static_name(Gui.unique_static_name)
:add_to_left_flow()

Gui.left_toolbar_button('item/arithmetic-combinator', {'expcom-rate.main-tooltip'}, rate_container, function(player)
	return Roles.player_allowed(player, 'gui/rate')
end)
