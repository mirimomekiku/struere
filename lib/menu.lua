local Modes = require("lib.modes")
local Themes = require("lib.themes")

local Menu = {}

Menu.selected = 1
Menu.show_custom_menu = false
Menu.custom_settings = {
    start_level = 1,
    line_goal = 40,
    lock_delay = 0.5,
    time_limit = 0,
    fixed_gravity = false,
}
Menu.custom_selected = 1
Menu.custom_options = {
    {key = "start_level", label = "Start Level", min = 1, max = 20, step = 1},
    {key = "line_goal", label = "Line Goal (0=infinite)", min = 0, max = 100, step = 10},
    {key = "lock_delay", label = "Lock Delay", min = 0.1, max = 2.0, step = 0.1},
    {key = "time_limit", label = "Time Limit (0=none)", min = 0, max = 600, step = 30},
    {key = "fixed_gravity", label = "Fixed Gravity", min = 0, max = 1, step = 1, is_bool = true},
}

function Menu.reset()
    Menu.selected = 1
    Menu.show_custom_menu = false
    Menu.custom_selected = 1
end

function Menu.createMode()
    local name = Modes.order[Menu.selected]
    if name == "custom" then
        local config = {
            start_level = Menu.custom_settings.start_level,
            line_goal = Menu.custom_settings.line_goal > 0 and Menu.custom_settings.line_goal or nil,
            lock_delay = Menu.custom_settings.lock_delay,
            time_limit = Menu.custom_settings.time_limit > 0 and Menu.custom_settings.time_limit or nil,
            fixed_gravity = Menu.custom_settings.fixed_gravity,
        }
        return Modes.create("custom", config)
    end
    return Modes.create(name)
end

function Menu.draw()
    local theme = Themes.get_ui_theme()
    love.graphics.clear(theme.background[1], theme.background[2], theme.background[3])

    if Menu.show_custom_menu then
        Menu.drawCustomMenu()
    else
        Menu.drawMainMenu()
    end
end

function Menu.drawMainMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TetriX", 250, 50)
    love.graphics.print("Select Game Mode", 220, 100)

    local modes = Modes.getNames()
    for i, name in ipairs(modes) do
        local y = 160 + (i - 1) * 50
        if i == Menu.selected then
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill", 100, y - 5, 400, 35)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.print(Modes.getLabel(name), 120, y)
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Up/Down: Select", 200, 450)
    love.graphics.print("Enter: Start", 200, 470)
    love.graphics.print("Escape: Quit", 200, 490)
end

function Menu.drawCustomMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Custom Mode Settings", 200, 50)

    for i, opt in ipairs(Menu.custom_options) do
        local y = 120 + (i - 1) * 50
        if i == Menu.custom_selected then
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill", 100, y - 5, 400, 35)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end

        local value = Menu.custom_settings[opt.key]
        if opt.is_bool then
            value = value and "ON" or "OFF"
        else
            value = tostring(value)
        end
        love.graphics.print(opt.label .. ": " .. value, 120, y)
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Up/Down: Select Option", 150, 430)
    love.graphics.print("Left/Right: Change Value", 150, 450)
    love.graphics.print("Enter: Start Game", 150, 470)
    love.graphics.print("Escape: Back", 150, 490)
end

function Menu.keypressed(key)
    if Menu.show_custom_menu then
        return Menu.handleCustomInput(key)
    end
    return Menu.handleMainInput(key)
end

function Menu.handleMainInput(key)
    local modes = Modes.getNames()
    if key == "up" then
        Menu.selected = Menu.selected - 1
        if Menu.selected < 1 then Menu.selected = #modes end
    elseif key == "down" then
        Menu.selected = Menu.selected + 1
        if Menu.selected > #modes then Menu.selected = 1 end
    elseif key == "return" then
        local name = Modes.order[Menu.selected]
        if name == "custom" then
            Menu.show_custom_menu = true
            Menu.custom_selected = 1
            return false
        end
        return true
    elseif key == "escape" then
        love.event.quit()
    end
    return false
end

function Menu.handleCustomInput(key)
    local opt = Menu.custom_options[Menu.custom_selected]
    if key == "up" then
        Menu.custom_selected = Menu.custom_selected - 1
        if Menu.custom_selected < 1 then Menu.custom_selected = #Menu.custom_options end
    elseif key == "down" then
        Menu.custom_selected = Menu.custom_selected + 1
        if Menu.custom_selected > #Menu.custom_options then Menu.custom_selected = 1 end
    elseif key == "left" then
        Menu.adjustCustomValue(opt, -1)
    elseif key == "right" then
        Menu.adjustCustomValue(opt, 1)
    elseif key == "return" then
        return true
    elseif key == "escape" then
        Menu.show_custom_menu = false
    end
    return false
end

function Menu.adjustCustomValue(opt, dir)
    if opt.is_bool then
        Menu.custom_settings[opt.key] = not Menu.custom_settings[opt.key]
    else
        local val = Menu.custom_settings[opt.key] + dir * opt.step
        val = math.max(opt.min, math.min(opt.max, val))
        Menu.custom_settings[opt.key] = val
    end
end

return Menu
