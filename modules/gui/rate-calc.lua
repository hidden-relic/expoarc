--- research milestone gui
-- @gui Research

local Gui = require 'expcore.gui' --- @dep expcore.gui
local Roles = require 'expcore.roles' --- @dep expcore.roles
local format_time = _C.format_time --- @dep expcore.common


local clock_container =
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

Gui.left_toolbar_button('item/space-science-pack', {'expcom-res.main-tooltip'}, clock_container, function(player)
	return Roles.player_allowed(player, 'gui/research')
end)

