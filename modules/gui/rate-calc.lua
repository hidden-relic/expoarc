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

	scroll_table.add{
        name = 'clock_text_3',
        caption = '',
        type = 'label',
        style = 'heading_1_label'
    }

    scroll_table.add{
        name = 'clock_display',
        caption = empty_time,
        type = 'label',
        style = 'heading_1_label'
    }

	for i=1, 8 do
        scroll_table.add{
            name = 'research_display_n_' .. i,
            caption = '',
            type = 'label',
            style = 'heading_1_label'
        }

		scroll_table.add{
            name = 'research_display_d_' .. i,
            caption = empty_time,
            type = 'label',
            style = 'heading_1_label'
        }

		scroll_table.add{
            name = 'research_display_p_' .. i,
			caption = '',
            type = 'label',
            style = 'heading_1_label'
        }

		scroll_table.add{
            name = 'research_display_t_' .. i,
            caption = empty_time,
            type = 'label',
            style = 'heading_1_label'
        }
	end

	local res_n = research_res_n(res)

	for j=1, 8 do
		local res_j = res_n + j - 3

		if res[res_j] ~= nil then
			local res_r = res[res_j]
			scroll_table['research_display_n_' .. j].caption = res_r.name

			if research.time[res_j] < res[res_j].prev then
				scroll_table['research_display_d_' .. j].caption = '-' .. format_time(res[res_j].prev - research.time[res_j], research_time_format)

			else
				scroll_table['research_display_d_' .. j].caption = format_time(research.time[res_j] - res[res_j].prev, research_time_format)
			end

			scroll_table['research_display_p_' .. j].caption = res_r.prev_disp
			scroll_table['research_display_t_' .. j].caption = format_time(research.time[res_j], research_time_format)

		else
			scroll_table['research_display_n_' .. j].caption = ''
			scroll_table['research_display_d_' .. j].caption = ''
			scroll_table['research_display_p_' .. j].caption = ''
			scroll_table['research_display_t_' .. j].caption = ''
		end
	end

    return container.parent
end)
:static_name(Gui.unique_static_name)
:add_to_left_flow()

Gui.left_toolbar_button('item/space-science-pack', {'expcom-res.main-tooltip'}, clock_container, function(player)
	return Roles.player_allowed(player, 'gui/research')
end)

