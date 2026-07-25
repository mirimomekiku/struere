-- lib/input_prompts.lua
-- Preloads and renders hardware button prompt PNG icons for Xbox, PlayStation, Nintendo Switch, and Keyboard.

local InputPrompts = {}

local images = {}
local active_scheme = "keyboard" -- "keyboard", "xbox", "playstation", "switch"

-- Path mapping helper
local function load_img(path)
    if not images[path] then
        if love.filesystem.getInfo(path) then
            local img = love.graphics.newImage(path)
            img:setFilter("linear", "linear")
            images[path] = img
        else
            images[path] = false
        end
    end
    return images[path]
end

function InputPrompts.set_scheme(scheme)
    if scheme == "xbox" or scheme == "playstation" or scheme == "switch" or scheme == "keyboard" then
        active_scheme = scheme
    end
end

function InputPrompts.get_scheme()
    return active_scheme
end

-- Get image asset path for abstract action
local function get_action_path(action, scheme)
    scheme = scheme or active_scheme
    local base = "assets/controllers/"

    if scheme == "xbox" then
        local dir = base .. "xbox/Default/"
        if action == "MOVE_LEFT" then return dir .. "xbox_dpad_left.png"
        elseif action == "MOVE_RIGHT" then return dir .. "xbox_dpad_right.png"
        elseif action == "SOFT_DROP" then return dir .. "xbox_dpad_down.png"
        elseif action == "HARD_DROP" then return dir .. "xbox_button_y.png"
        elseif action == "ROTATE_CW" then return dir .. "xbox_button_a.png"
        elseif action == "ROTATE_CCW" then return dir .. "xbox_button_b.png"
        elseif action == "HOLD" then return dir .. "xbox_lb.png"
        elseif action == "PAUSE" then return dir .. "xbox_button_start.png"
        end
    elseif scheme == "playstation" then
        local dir = base .. "playstation/Default/"
        if action == "MOVE_LEFT" then return dir .. "playstation_dpad_left.png"
        elseif action == "MOVE_RIGHT" then return dir .. "playstation_dpad_right.png"
        elseif action == "SOFT_DROP" then return dir .. "playstation_dpad_down.png"
        elseif action == "HARD_DROP" then return dir .. "playstation_button_triangle.png"
        elseif action == "ROTATE_CW" then return dir .. "playstation_button_cross.png"
        elseif action == "ROTATE_CCW" then return dir .. "playstation_button_circle.png"
        elseif action == "HOLD" then return dir .. "playstation_trigger_l1.png"
        elseif action == "PAUSE" then return dir .. "playstation4_button_options.png"
        end
    elseif scheme == "switch" then
        local dir = base .. "nintendo_switch/Default/"
        if action == "MOVE_LEFT" then return dir .. "switch_dpad_left.png"
        elseif action == "MOVE_RIGHT" then return dir .. "switch_dpad_right.png"
        elseif action == "SOFT_DROP" then return dir .. "switch_dpad_down.png"
        elseif action == "HARD_DROP" then return dir .. "switch_button_x.png"
        elseif action == "ROTATE_CW" then return dir .. "switch_button_a.png"
        elseif action == "ROTATE_CCW" then return dir .. "switch_button_b.png"
        elseif action == "HOLD" then return dir .. "switch_button_l.png"
        elseif action == "PAUSE" then return dir .. "switch_button_plus.png"
        end
    end

    -- Fallback to Keyboard
    local dir = base .. "keyboard_mouse/Default/"
    if action == "MOVE_LEFT" then return dir .. "keyboard_arrow_left.png"
    elseif action == "MOVE_RIGHT" then return dir .. "keyboard_arrow_right.png"
    elseif action == "SOFT_DROP" then return dir .. "keyboard_arrow_down.png"
    elseif action == "HARD_DROP" then return dir .. "keyboard_space.png"
    elseif action == "ROTATE_CW" then return dir .. "keyboard_arrow_up.png"
    elseif action == "ROTATE_CCW" then return dir .. "keyboard_z.png"
    elseif action == "HOLD" then return dir .. "keyboard_shift.png"
    elseif action == "PAUSE" then return dir .. "keyboard_escape.png"
    end
    return dir .. "keyboard_any.png"
end

function InputPrompts.draw_action_icon(action, x, y, size, scheme_override)
    size = size or 24
    local path = get_action_path(action, scheme_override)
    local img = load_img(path)
    if img then
        local iw, ih = img:getDimensions()
        local sx = size / iw
        local sy = size / ih
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, x, y, 0, sx, sy)
        return size
    else
        -- Text fallback if image missing
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("[" .. tostring(action) .. "]", x, y)
        return size
    end
end

function InputPrompts.draw_action_badge(action, label, x, y, size, font)
    size = size or 22
    InputPrompts.draw_action_icon(action, x, y, size)
    if label and font then
        love.graphics.setFont(font)
        love.graphics.setColor(0.8, 0.9, 1.0, 0.9)
        love.graphics.print(label, x + size + 6, y + (size - font:getHeight()) / 2)
    end
end

return InputPrompts
