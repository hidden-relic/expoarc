local Event = require 'utils.event' --- @dep utils.event
local Gui = require 'expcore.gui' --- @dep expcore.gui
local Roles = require 'expcore.roles' --- @dep expcore.roles
local Global = require 'utils.global' -- @dep utils.global
local config = require 'config.separate_spawns'
local spawning = require 'modules.addons.spawns'
local readme = require 'modules.gui.readme'
local vlayer = require 'modules.control.vlayer'

local separate_spawns = {}

local separate_spawns_player_settings = {}
Global.register(separate_spawns_player_settings, function(tbl)
    separate_spawns_player_settings = tbl
end)

function separate_spawns.get_player_settings(player)
    if separate_spawns_player_settings[player.name] then
        return separate_spawns_player_settings[player.name]
    else
        return false
    end
end

--[[-- Creates a frame containing a label
@tparam string parent The parent element
@tparam string caption The label caption
@tparam boolean add_alignment Adds an alignment
@tparam string name Name of the frame
@tparam string label_name Name of the label
@tparam string tooltip The tooltip over the caption
@treturn LuaGuiElement Either the label or the label's alignment if true

@usage-- Create a label
local my_label = label(parent, caption, add_alignment, name, label_name, tooltip)

]]
local label =
Gui.element(function(_, parent, caption, add_alignment, name, label_name, tooltip, style, alignment)
    
    local label =
    parent.add{
        name = name or 'frame',
        type = 'frame',
        style = 'window_content_frame_packed'
    }
    
    local label_style = label.style
    label_style.padding = {2, 2}
    label_style.use_header_filler = false
    label_style.horizontally_stretchable = true
    
    if caption then
        local cap =
        label.add{
            name = label_name or 'label',
            type = 'label',
            style = style or 'heading_1_label',
            caption = caption,
            tooltip = tooltip
        }
        if alignment then
            cap.style.horizontal_align = alignment
        end
    end
    
    -- Return either the header or the added alignment
    return add_alignment and Gui.alignment(label) or label
end)

--- Toggle entity section visibility
-- @element toggle_item_button
local toggle_section =
Gui.element{
    type = 'sprite-button',
    sprite = 'utility/expand_dark',
    hovered_sprite = 'utility/expand',
    tooltip = {'separate_spawns.toggle-section-tooltip'},
    name = Gui.unique_static_name
}
:style(Gui.sprite_style(20))
:on_click(function(_, element, _)
    local header_flow = element.parent
    local flow_name = header_flow.caption
    local flow = header_flow.parent.parent[flow_name]
    if Gui.toggle_visible_state(flow) then
        element.sprite = 'utility/collapse_dark'
        element.hovered_sprite = 'utility/collapse'
        element.tooltip = {'separate_spawns.toggle-section-collapse-tooltip'}
    else
        element.sprite = 'utility/expand_dark'
        element.hovered_sprite = 'utility/expand'
        element.tooltip = {'separate_spawns.toggle-section-tooltip'}
    end
end)

--- Draw a section header and main scroll
-- @element autofill_section_container
local section =
Gui.element(function(definition, parent, section_name, table_size)
    -- Draw the header for the section
    local header = Gui.header(
    parent,
    {'separate_spawns.toggle-section-caption', section_name},
    {'separate_spawns.toggle-section-tooltip'},
    true,
    section_name..'-header'
)

definition:triggers_events(header.parent.header_label)

-- Right aligned button to toggle the section
header.caption = section_name
toggle_section(header)

local section_table = parent.add{
    type = 'table',
    name = section_name,
    column_count = table_size
}

section_table.visible = false

return definition:no_events(section_table)
end)
:on_click(function(_, element, event)
    event.element = element.parent.alignment[toggle_section.name]
    toggle_section:raise_event(event)
end)
:on_click(function(_, element, event)
    event.element = element.parent.alignment[toggle_section.name]
    toggle_section:raise_custom_event(event)
end)

local toggle_option =
Gui.element(function(_, parent, option_name)
    return parent.add{
        type = 'sprite-button',
        sprite = 'utility/close_black',
        tooltip = {'separate_spawns.toggle-option-on-tooltip', option_name},
        style = 'shortcut_bar_button_red'
    }
end)
:style(Gui.sprite_style(22))
:on_click(function(player, element, _)
    local option_name = string.match(element.parent.parent.name,'(.*)%-option')
    if not separate_spawns_player_settings[player.name] then return end
    local setting = separate_spawns_player_settings[player.name][option_name]
    if not setting then return end
    if setting.enabled then
        setting.enabled = false
        element.sprite = 'utility/close_black'
        element.style = 'shortcut_bar_button_red'
        element.tooltip = {'separate_spawns.toggle-option-on-tooltip', option_name}
        game.player.print({'separate_spawns.toggle-option-off', option_name})
    else
        setting.enabled = true
        element.sprite = 'utility/confirm_slot'
        element.style = 'shortcut_bar_button_green'
        element.tooltip = {'separate_spawns.toggle-option-off-tooltip', option_name}
        game.player.print({'separate_spawns.toggle-option-on', option_name})
    end
    -- Correct the button size
    local style = element.style
    style.padding = -2
    style.height = 22
    style.width = 22
end)

local option =
Gui.element(function(definition, parent, option_name, caption, tooltip, table_size)
    -- Draw the header for the option
    local setting = label(
    parent,
    {'separate_spawns.toggle-option-caption', caption},
    true,
    option_name..'-option',
    nil,
    tooltip
)

definition:triggers_events(setting.parent.label)

-- Right aligned button to toggle the section
setting.caption = caption
toggle_option(setting, caption)

local section_table = parent.add{
    type = 'table',
    name = option_name,
    column_count = table_size
}

section_table.visible = false

return definition:no_events(section_table)
end)
:on_click(function(_, element, event)
    event.element = element.parent.alignment[toggle_section.name]
    toggle_option:raise_event(event)
end)
:on_click(function(_, element, event)
    event.element = element.parent.alignment[toggle_section.name]
    toggle_option:raise_custom_event(event)
end)

local flow =
Gui.element(function(_, parent, name, direction)
    return parent.add{
        type = 'flow',
        direction = direction or 'vertical',
        name = name or 'flow'
    }
end)

local content =
Gui.element(function(_, parent)
    return parent.add{
        type = 'frame',
        direction = 'vertical',
        style = 'inside_deep_frame'
    }
end)
:style{
    horizontally_stretchable = true,
    horizontal_align = 'center',
    padding = {2, 2},
    top_margin = 2
}


local near_button =
Gui.element{
    type = 'button',
    caption = 'Near'
}
:style{
    height = 40,
    width = 160
}
:on_click(function(player, element, _)
    spawning.distance_chosen(player, 'near')
    player.opened = nil
    player.gui.center.clear()
    local element = readme(player.gui.center)
    element.pane.selected_tab_index = 1
    player.opened = element
end)

local far_button =
Gui.element{
    type = 'button',
    caption = 'Far'
}
:style{
    height = 40,
    width = 160
}
:on_click(function(player, element, _)
    spawning.distance_chosen(player, 'far')
    player.opened = nil
    player.gui.center.clear()
    local element = readme(player.gui.center)
    element.pane.selected_tab_index = 1
    player.opened = element
end)

local spawn_buttons =
Gui.element(function(event_trigger, parent, ...)
    local alignment_flow = Gui.alignment(parent, 'vertical_spawn_button_flow', 'center', 'bottom')
    local vertical_flow =
    alignment_flow.add{
        name = 'vertical_flow',
        type = 'flow',
        direction = 'vertical'
    }
    vertical_flow.style.horizontal_align = 'center'
    vertical_flow.style.padding = {16, 8}
    local center_label = Gui.centered_label(vertical_flow, 380, 'How far from the center would you like your spawn?')
    center_label.style = 'heading_1_label'
    -- center_label.style.bottom_padding = 4
    local button_flow =
    vertical_flow.add{
        name = 'button_flow',
        type = 'flow'
    }
    -- button_flow.style.bottom_padding = 24
    near_button(button_flow)
    far_button(button_flow)
    
    local info_flow =
    vertical_flow.add{
        name = 'data_flow',
        type = 'flow',
        direction = 'vertical'
    }
    Gui.centered_label(info_flow, 380, 'Near is between [color=blue]' .. 32*50 .. '[/color] and [color=blue]' .. 32*100 .. '[/color] tiles away from center.')
    Gui.centered_label(info_flow, 380, 'Far is between [color=blue]' .. 32*150 .. '[/color] and [color=blue]' .. 32*300 .. '[/color] tiles away from center.')
    Gui.centered_label(info_flow, 380, 'There is a minimum of [color=blue]' .. 32*50 .. '[/color] tiles between player spawns')
    
    return button_flow
end)

spawn_choices =
Gui.element(function(definition, parent)
    local container = parent.add{
        name = definition.name,
        type = 'frame',
        style = 'invisible_frame'
    }
    
    -- Add the left hand side of the frame back, removed because of frame_tabbed_pane style
    local left_alignment = Gui.alignment(container, nil, nil, 'bottom')
    left_alignment.style.padding = {32, 0, 0, 0}
    
    local left_side =
    left_alignment.add{
        type = 'frame',
        style = 'frame_without_right_side'
    }
    left_side.style.vertically_stretchable = true
    left_side.style.padding = 0
    left_side.style.width = 5
    
    local content = content(container)    
    local buttons = spawn_buttons(content)
    
    return container
end)

local function rich_img(type, value)
    return '[img='..type..'/'..value..']'
end

local function format_item_name(item)
    return {'separate_spawns.item-name', rich_img('item', item), game.item_prototypes[item].localised_name}
end

local add_item_name =
Gui.element(function(_, parent, item_name) 
    local alignment = Gui.alignment(parent, item_name, 'left')
    local item_label = label(alignment, format_item_name(item_name), true, nil, nil, nil, 'caption_label')
    return alignment
end)

local function add_commas(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then break end
    end
    return formatted
end

local add_item_count =
Gui.element(function(_, parent, count, name)
    local alignment = Gui.alignment(parent, name .. '-count')
    local count_label = label(alignment, add_commas(count), true, nil, nil, nil, 'description_label', 'right')
    return alignment
end)

local add_row =
Gui.element(function(definition, parent, name, count)
    add_item_name(parent, name)
    add_item_count(parent, count, name)
end)

local reset_button =
Gui.element(function(_, parent)
    return parent.add{
        type = 'sprite-button',
        sprite = 'utility/danger_icon'
    }
end)
:style(Gui.sprite_style(32, nil, { right_margin = -3 }))
:on_click(function(player, element, event)
    spawning.reset_player(player)
    spawn_choices(player.gui.center)
end)

local reset_option =
Gui.element(function(definition, parent, option_name, caption, tooltip, table_size)
    -- Draw the header for the option
    local setting = label(
    parent,
    {'separate_spawns.toggle-option-caption', caption},
    true,
    option_name..'-option',
    nil,
    tooltip
)

-- Right aligned button to toggle the section
setting.caption = caption
reset_button(setting)

local section_table = parent.add{
    type = 'table',
    name = option_name,
    column_count = table_size
}

section_table.visible = false
end)


--- Main gui container for the left flow
-- @element autofill_container
local separate_spawns_container =
Gui.element(function(definition, parent)
    local container = Gui.container(parent, definition.name, 320)
    local scroll_table = Gui.scroll_table(container, 160, 1)
    scroll_table.parent.vertical_scroll_policy = 'always'
    scroll_table.parent.style.padding = 0
    scroll_table.style.vertical_spacing = 0
    scroll_table.style.column_alignments[1] = 'center'
    
    local shared_items_table = section(scroll_table, 'Shared', 2)
    shared_items_table.style.padding = 3
    shared_items_table.style.vertical_spacing = 1
    shared_items_table.style.horizontal_spacing = 1
    shared_items_table.style.column_alignments[1] = 'top-center'
    shared_items_table.style.column_alignments[2] = 'top-center'
    
    local options_table = section(scroll_table, 'Options', 1)
    options_table.style.padding = 3
    options_table.style.column_alignments[1] = 'top-center'
    options_table.style.column_alignments[2] = 'top-center'
    
    local shared_spawn = option(options_table, 'shared_spawn', 'Shared Spawn', 'Open your base to other players', 2)
    local reset_spawn = reset_option(options_table, 'reset_spawn', 'Reset Spawn', 'Reset your game', 2)
    
    
    -- Return the external container
    return container.parent
end)
:static_name(Gui.unique_static_name)
:add_to_left_flow()

Gui.left_toolbar_button('utility/show_recipe_icons_in_map_view', {'separate_spawns.main-tooltip'}, separate_spawns_container, function(player)
    return Roles.player_allowed(player, 'gui/separate_spawns')
end)

local function redraw_item_list()
    local item_list = vlayer.get_items()
    for _, player in pairs(game.connected_players) do
        local frame = Gui.get_left_element(player, separate_spawns_container)
        local shared_table = frame.container.scroll.table.Shared
        shared_table.clear()
        for item_name, item_count in pairs(item_list) do
            if game.item_prototypes[item_name] then
                if item_count > 0 then
                    add_row(shared_table, item_name, item_count)
                end
            end
        end
    end
end

Event.on_nth_tick(60, redraw_item_list)

Event.add(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    spawn_choices(player.gui.center)
    separate_spawns_player_settings[player.name] = config.player_settings
end)

Event.add(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if not player.opened then
        player.gui.center.clear()
    end
    if not spawning.get_spawn(player.name) then
        spawn_choices(player.gui.center)
    end
end)