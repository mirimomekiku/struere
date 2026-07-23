local constants = require("lib.constants")
local baton = require("lib.vendor.baton")
local Save = require("lib.save")

local Input = {}

local ACTIONS = {
    "MOVE_LEFT", "MOVE_RIGHT", "SOFT_DROP", "HARD_DROP",
    "ROTATE_CW", "ROTATE_CCW", "HOLD", "THEME", "PAUSE", "QUIT", "RESTART",
}

local DEFAULT_BINDINGS = {
    MOVE_LEFT  = {"key:left", "button:dpleft"},
    MOVE_RIGHT = {"key:right", "button:dpright"},
    SOFT_DROP  = {"key:down", "button:dpdown"},
    HARD_DROP  = {"key:space", "button:y"},
    ROTATE_CW  = {"key:up", "key:x", "button:a"},
    ROTATE_CCW = {"key:z", "button:b"},
    HOLD       = {"key:c", "key:lshift", "key:rshift", "button:leftshoulder"},
    THEME      = {"key:t"},
    PAUSE      = {"key:p", "button:start"},
    QUIT       = {"key:escape", "button:back"},
    RESTART    = {"key:r"},
}

local ACTION_LABELS = {
    MOVE_LEFT  = "Move Left",
    MOVE_RIGHT = "Move Right",
    SOFT_DROP  = "Soft Drop",
    HARD_DROP  = "Hard Drop",
    ROTATE_CW  = "Rotate CW",
    ROTATE_CCW = "Rotate CCW",
    HOLD       = "Hold Piece",
    THEME      = "Theme",
    PAUSE      = "Pause",
    QUIT       = "Quit",
    RESTART    = "Restart",
}

Input.player = nil
Input.bindings = {}
Input.keys_held = {}
Input.das = { direction = 0, timer = 0, arr_timer = 0 }
Input.rebinding = nil
Input.rebind_selected = 1

function Input.get_actions()
    return ACTIONS
end

function Input.get_action_label(action)
    return ACTION_LABELS[action] or action
end

function Input.get_key_for_action(action)
    local key_map = {
        MOVE_LEFT = "Left Arrow",
        MOVE_RIGHT = "Right Arrow",
        SOFT_DROP = "Down Arrow",
        HARD_DROP = "Space",
        ROTATE_CW = "Up / X",
        ROTATE_CCW = "Z",
        HOLD = "Shift / C",
        THEME = "T",
        PAUSE = "P",
        QUIT = "Esc",
        RESTART = "R"
    }
    return key_map[action] or "Key/Button"
end

function Input.apply_up_button_mode(up_mode)
    up_mode = up_mode or Save.get("settings", "up_mode") or "rotate_cw"
    if up_mode == "rotate_cw" then
        Input.bindings["up"] = "ROTATE_CW"
    elseif up_mode == "hard_drop" then
        Input.bindings["up"] = "HARD_DROP"
    elseif up_mode == "rotate_ccw" then
        Input.bindings["up"] = "ROTATE_CCW"
    elseif up_mode == "off" then
        Input.bindings["up"] = nil
    end
end

function Input.load()
    Input.bindings = {
        ["left"]    = "MOVE_LEFT",
        ["right"]   = "MOVE_RIGHT",
        ["down"]    = "SOFT_DROP",
        ["space"]   = "HARD_DROP",
        ["up"]      = "ROTATE_CW",
        ["x"]       = "ROTATE_CW",
        ["z"]       = "ROTATE_CCW",
        ["c"]       = "HOLD",
        ["lshift"]  = "HOLD",
        ["rshift"]  = "HOLD",
        ["t"]       = "THEME",
        ["p"]       = "PAUSE",
        ["escape"]  = "QUIT",
        ["r"]       = "RESTART",
    }
    Input.apply_up_button_mode()
    Input.keys_held = {}
    Input.das = { direction = 0, timer = 0, arr_timer = 0 }
    Input.rebinding = nil

    Input.player = baton.new({
        controls = DEFAULT_BINDINGS
    })
end

function Input.get_action(key)
    return Input.bindings[key]
end

function Input.is_held(action)
    for key, act in pairs(Input.bindings) do
        if act == action and Input.keys_held[key] then
            return true
        end
    end
    return false
end

function Input.keypressed(key)
    if Input.rebinding then
        if key == "escape" then
            Input.rebinding = nil
            return nil
        end
        Input.bindings[key] = Input.rebinding.action
        Input.rebinding = nil
        return nil
    end

    Input.keys_held[key] = true

    local action = Input.bindings[key]
    if action == "MOVE_LEFT" then
        Input.das.direction = -1
        Input.das.timer = 0
        Input.das.arr_timer = 0
        return "MOVE_LEFT"
    elseif action == "MOVE_RIGHT" then
        Input.das.direction = 1
        Input.das.timer = 0
        Input.das.arr_timer = 0
        return "MOVE_RIGHT"
    end

    return action
end

function Input.keyreleased(key)
    Input.keys_held[key] = nil

    local action = Input.bindings[key]
    if action == "MOVE_LEFT" and Input.das.direction == -1 then
        if Input.is_held("MOVE_RIGHT") then
            Input.das.direction = 1
            Input.das.timer = 0
            Input.das.arr_timer = 0
        else
            Input.das.direction = 0
            Input.das.timer = 0
            Input.das.arr_timer = 0
        end
    elseif action == "MOVE_RIGHT" and Input.das.direction == 1 then
        if Input.is_held("MOVE_LEFT") then
            Input.das.direction = -1
            Input.das.timer = 0
            Input.das.arr_timer = 0
        else
            Input.das.direction = 0
            Input.das.timer = 0
            Input.das.arr_timer = 0
        end
    end

    if action == "SOFT_DROP" then
        return "SOFT_DROP_RELEASE"
    end
end

function Input.update(dt)
    if Input.player then Input.player:update() end
    local fired = {}

    -- Safety check: stop DAS if neither direction is currently held
    if Input.das.direction == -1 and not Input.is_held("MOVE_LEFT") then
        Input.das.direction = Input.is_held("MOVE_RIGHT") and 1 or 0
        Input.das.timer = 0
        Input.das.arr_timer = 0
    elseif Input.das.direction == 1 and not Input.is_held("MOVE_RIGHT") then
        Input.das.direction = Input.is_held("MOVE_LEFT") and -1 or 0
        Input.das.timer = 0
        Input.das.arr_timer = 0
    end

    if Input.das.direction ~= 0 then
        Input.das.timer = Input.das.timer + dt
        if Input.das.timer >= constants.DAS_DELAY then
            Input.das.arr_timer = Input.das.arr_timer + dt
            while Input.das.arr_timer >= constants.ARR_DELAY do
                Input.das.arr_timer = Input.das.arr_timer - constants.ARR_DELAY
                if Input.das.direction == -1 then
                    table.insert(fired, "MOVE_LEFT")
                elseif Input.das.direction == 1 then
                    table.insert(fired, "MOVE_RIGHT")
                end
            end
        end
    end

    return fired
end

function Input.start_rebind(action_index)
    Input.rebinding = { action = ACTIONS[action_index] }
    Input.rebind_selected = action_index
end

function Input.cancel_rebind()
    Input.rebinding = nil
end

function Input.reset_defaults()
    Input.load()
end

function Input.save_bindings()
    local parts = {}
    for key, action in pairs(Input.bindings) do
        table.insert(parts, key .. "=" .. action)
    end
    return table.concat(parts, ";")
end

function Input.load_bindings(str)
    if not str or str == "" then return end
    Input.bindings = {}
    for pair in str:gmatch("[^;]+") do
        local key, action = pair:match("([^=]+)=([^=]+)")
        if key and action then
            Input.bindings[key] = action
        end
    end
    Input.apply_up_button_mode()
end

return Input
