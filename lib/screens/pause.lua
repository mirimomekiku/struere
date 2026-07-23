local StateMgr = require("lib.state_mgr")
local Themes = require("lib.themes")
local Audio = require("lib.audio")
local Fonts = require("lib.fonts")

local Pause = {}

Pause.selected = 1
Pause.options = {"Resume", "Settings", "Quit to Menu"}

function Pause:enter(previous)
    Pause.selected = 1
end

function Pause:update(dt)
end

function Pause:draw()
    local theme = Themes.get_ui_theme()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 100, 150, 420, 300, 12, 12)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.8)
    love.graphics.rectangle("line", 100, 150, 420, 300, 12, 12)

    love.graphics.setFont(Fonts.get(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 100, 175, 420, "center")

    for i, opt in ipairs(Pause.options) do
        local y = 230 + (i - 1) * 45
        if i == Pause.selected then
            love.graphics.setColor(1, 0.9, 0.2)
            love.graphics.rectangle("fill", 150, y - 5, 320, 35, 8, 8)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
            love.graphics.rectangle("fill", 150, y - 5, 320, 35, 8, 8)
            love.graphics.setColor(0.8, 0.8, 0.9)
        end
        love.graphics.setFont(Fonts.get(16))
        love.graphics.printf(opt, 150, y + 2, 320, "center")
    end

    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.printf("UP / DOWN: Select | ENTER: Confirm | ESC: Resume", 100, 415, 420, "center")
end

function Pause:keypressed(key)
    if key == "up" then
        Pause.selected = Pause.selected - 1
        if Pause.selected < 1 then Pause.selected = #Pause.options end
        Audio.play("move")
    elseif key == "down" then
        Pause.selected = Pause.selected + 1
        if Pause.selected > #Pause.options then Pause.selected = 1 end
        Audio.play("move")
    elseif key == "return" or key == "space" then
        Audio.play("rotate")
        if Pause.selected == 1 then
            StateMgr.pop()
        elseif Pause.selected == 2 then
            StateMgr.push("settings")
        elseif Pause.selected == 3 then
            StateMgr.switch("title")
        end
    elseif key == "escape" or key == "p" then
        StateMgr.pop()
    end
end

return Pause
