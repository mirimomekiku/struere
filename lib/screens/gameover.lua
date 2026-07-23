local State = require("lib.state")
local Themes = require("lib.themes")
local Gameplay = require("lib.screens.gameplay")

local GameOver = {}

GameOver.selected = 1
GameOver.options = {"Restart", "Main Menu"}

function GameOver.load(params)
    GameOver.selected = 1
end

function GameOver.update(dt)
end

function GameOver.draw()
    local theme = Themes.get_ui_theme()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 100, 150, 400, 300)

    if Gameplay.victory then
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("VICTORY!", 100, 170, 400, "center")
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER", 100, 170, 400, "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score: " .. Gameplay.score, 100, 220, 400, "center")
    love.graphics.printf("Lines: " .. Gameplay.lines, 100, 250, 400, "center")
    love.graphics.printf("Level: " .. Gameplay.level, 100, 280, 400, "center")

    for i, opt in ipairs(GameOver.options) do
        local y = 340 + (i - 1) * 40
        if i == GameOver.selected then
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill", 150, y - 5, 300, 30)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.printf(opt, 150, y, 300, "center")
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Up/Down: Select  Enter: Confirm", 100, 440, 400, "center")
end

function GameOver.keypressed(key)
    if key == "up" then
        GameOver.selected = GameOver.selected - 1
        if GameOver.selected < 1 then GameOver.selected = #GameOver.options end
    elseif key == "down" then
        GameOver.selected = GameOver.selected + 1
        if GameOver.selected > #GameOver.options then GameOver.selected = 1 end
    elseif key == "return" then
        if GameOver.selected == 1 then
            State.switch("gameplay")
        else
            State.switch("title")
        end
    elseif key == "escape" then
        State.switch("title")
    end
end

function GameOver.keyreleased(key)
end

return GameOver
