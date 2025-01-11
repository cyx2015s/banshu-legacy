local char_set = require("char_set")
local materials = require("materials")
local sizes = {"1x1", "1x2", "2x2"}

require("util")

local function start_with(a, b) return string.sub(a, 1, string.len(b)) == b end

local function get_code(utf8char)
    local l = 1
    local r = #char_set
    local mid = 1
    while l <= r do
        mid = math.floor((l + r) / 2)
        if char_set[mid] == utf8char then
            break
        elseif char_set[mid] < utf8char then
            l = mid + 1
        else
            r = mid - 1
        end
    end
    if char_set[mid] == utf8char then
        return utf8_char_to_code(utf8char)
    else
        return -1
    end
end

local function get_data_from_base_name(name)
    for _, material in pairs(materials) do
        for _, size in pairs(sizes) do
            if start_with(name, "banshu-" .. material.name .. "-" .. size) then
                return material, size
            end
        end
    end
    return nil, nil
end

local function show_gui(player, item_name)
    local player_id = player.index
    storage.banshu_cur_item[player_id] = get_data_from_base_name(item_name)
    if player.gui.left.banshu_frame then return end

    local frame = player.gui.left.add {
        type = "frame",
        name = 'banshu_frame',
        caption = {"banshu-ui.title"},
        direction = "vertical"
    }
    frame.style.width = 400
    local label = frame.add {
        type = "label",
        name = "banshu_label",
        caption = {"banshu-ui.label"}
    }
    label.style.height = 64
    label.style.maximal_width = 376
    label.style.single_line = false
    local flow = frame.add {
        type = "flow",
        name = "banshu_flow",
        direction = "horizontal"
    }
    local field = flow.add {type = "textfield", name = "banshu_textfield"}
    field.style.width = 308
    field.text = storage.banshu_gui_text[player_id] or ""
    local button
    button = flow.add {
        type = "sprite-button",
        name = "banshu_confirm",
        tooltip = {"banshu-ui.confirm"},
        sprite = "utility/confirm_slot"
    }
    button.style.width = 28
    button.style.height = 28
    button = flow.add {
        type = "sprite-button",
        name = "banshu_delete",
        tooltip = {"banshu-ui.delete"},
        sprite = "utility/trash"
    }
    button.style.width = 28
    button.style.height = 28
end

local function hide_gui(player)
    if player.gui.left.banshu_frame then
        player.gui.left.banshu_frame.destroy()
    end
end

local function prepare_next_char(player_id, remove_first)
    remove_first = remove_first or false
    local player = game.players[player_id]
    local gui = player.gui.left.banshu_frame
    local item_name = storage.banshu_cur_item[player_id]
    local text = gui.banshu_flow.banshu_textfield.text
    storage.banshu_next_char[player_id] =
        storage.banshu_next_char[player_id] or -1
    if text == "" then
        -- game.print("空字符串")
    else
        if remove_first then
            local _, len = utf8_char_to_code(text)
            text = string.sub(text, len + 1)
            gui.banshu_flow.banshu_textfield.text = text
            storage.banshu_gui_text[player_id] = text
        end
        if text == "" then
            -- game.print("空字符串")
            return
        end
        local code = utf8_char_to_code(text)
        local utf8char = code_to_utf8(code)
        storage.banshu_next_char[player_id] = get_code(utf8char)
        -- game.print("代码: " .. tostring(code) .. "; 字符: " .. utf8char)
    end
    -- game.print("准备下一个字符编号: " .. tostring(storage.banshu_next_char[player_id]))
end

local function on_gui_text_changed(event)
    if event.element.name == "banshu_textfield" then
        storage.banshu_gui_text[event.player_index] = event.element.text
        prepare_next_char(event.player_index)
    end
end

local function on_gui_click(event)
    if event.element.name == "banshu_delete" then
        local player_id = event.player_index
        local gui = game.players[player_id].gui.left.banshu_frame
        gui.banshu_flow.banshu_textfield.text = ""
        gui.banshu_flow.banshu_textfield.focus()
        storage.banshu_gui_text[player_id] = ""
        prepare_next_char(player_id)
    end
end

local function on_player_cursor_stack_changed(event)
    local player = game.players[event.player_index]
    if player.cursor_stack and player.cursor_stack.valid and
        player.cursor_stack.valid_for_read and
        start_with(player.cursor_stack.name, "banshu") then
        show_gui(player, player.cursor_stack.name)
    elseif player.cursor_ghost and player.cursor_ghost.valid and
        player.cursor_ghost and start_with(player.cursor_ghost.name, "banshu") then
        show_gui(player, player.cursor_ghost.name)
    else
        hide_gui(player)
    end
end

local function on_player_pipette(event)
    if storage.banshu_gui_text[event.player_index] ~= "" then return end
    local player = game.players[event.player_index]
    local name
    if player and player.connected then
        if player.selected and player.selected.type ==
            "simple-entity-with-owner" and
            start_with(player.selected.name, "banshu") then
            name = player.selected.name
        elseif player.selected and player.selected.type == "entity-ghost" and
            start_with(player.selected.ghost_name, "banshu") and
            ((player.cursor_stack and player.cursor_stack.valid) or
                (player.cursor_ghost and player.cursor_ghost.valid)) then
            name = player.selected.ghost_name
        else
            return
        end
        local i, j = name:find("[0-9]+$")
        if i and j then
            local batch_id = tonumber(name:sub(i))
            local variant = player.selected.graphics_variation - 1
            storage.banshu_next_char[event.player_index] = batch_id * 255 +
                                                               variant
        end
    end
end

local function replace_entity(entity, new_batch_id)
    local material, size = get_data_from_base_name(entity.name)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force
    entity.destroy()
    return surface.create_entity {
        name = "banshu-" .. material.name .. "-" .. size .. "-" ..
            tostring(new_batch_id),
        position = position,
        force = force
    }
end

local function replace_entity_ghost(entity, new_batch_id)
    local material, size = get_data_from_base_name(entity.ghost_name)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force
    local time_to_live = entity.time_to_live
    entity.destroy()
    return surface.create_entity {
        name = "entity-ghost",
        ghost_name = "banshu-" .. material.name .. "-" .. size .. "-" ..
            tostring(new_batch_id),
        position = position,
        force = force,
        time_to_live = time_to_live
    }
end

local function on_built_entity(event)
    local player_id = event.player_index
    if not game.players[player_id].gui.left.banshu_frame then return end
    local entity = event.entity
    if not (player_id and entity and entity.valid) then return end

    local material, size = get_data_from_base_name(entity.name)
    if entity.name == "entity-ghost" then
        material, size = get_data_from_base_name(entity.ghost_name)
    end
    if not (material and size) then return end
    code = storage.banshu_next_char[player_id] or -1
    if code == -1 then code = 0 end

    if entity.name == "entity-ghost" then
        entity = replace_entity_ghost(entity, math.floor(code / 255))
    else
        entity = replace_entity(entity, math.floor(code / 255))
    end
    entity.graphics_variation = mod(code, 255) + 1
    prepare_next_char(player_id, true)
    return entity
end

script.on_init(function()
    storage.banshu_next_char = {}
    storage.banshu_cur_item = {}
    storage.banshu_gui_text = {}
end)

script.on_configuration_changed(function()
    storage.banshu_next_char = storage.banshu_next_char or {}
    storage.banshu_cur_item = storage.banshu_cur_item or {}
    storage.banshu_gui_text = storage.banshu_gui_text or {}
end)
script.on_event(defines.events.on_player_cursor_stack_changed,
                on_player_cursor_stack_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_player_pipette, on_player_pipette)
