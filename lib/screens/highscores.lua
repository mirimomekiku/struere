local StateMgr = require("lib.state_mgr")
local Themes = require("lib.themes")
local Save = require("lib.save")
local Fonts = require("lib.fonts")

local HighScores = {}

function HighScores:enter(previous)
end

function HighScores:update(dt)
end

function HighScores:draw()
    local theme = Themes.get_ui_theme()
    love.graphics.setColor(0, 0, 0, 0.88)
    love.graphics.rectangle("fill", 50, 40, 520, 530, 16, 16)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.8)
    love.graphics.rectangle("line", 50, 40, 520, 530, 16, 16)

    love.graphics.setFont(Fonts.get(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("HIGH SCORES & RECORDS", 50, 60, 520, "center")

    local y = 120

    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print("MARATHON", 90, y)
    y = y + 28
    local marathon = Save.get("high_scores", "marathon")
    love.graphics.setFont(Fonts.get(14))
    if marathon and marathon.score > 0 then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print("Score: " .. marathon.score, 110, y)
        love.graphics.print("Level: " .. (marathon.level or 0), 110, y + 22)
        love.graphics.print("Lines: " .. (marathon.lines or 0), 110, y + 44)
    else
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("No score recorded yet", 110, y)
    end
    y = y + 80

    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print("BLITZ (2 MIN)", 90, y)
    y = y + 28
    local blitz = Save.get("high_scores", "blitz")
    love.graphics.setFont(Fonts.get(14))
    if blitz and blitz.score > 0 then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print("Score: " .. blitz.score, 110, y)
        love.graphics.print("Pieces Placed: " .. (blitz.pieces or 0), 110, y + 22)
    else
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("No score recorded yet", 110, y)
    end
    y = y + 75

    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print("SPRINT (40 LINES)", 90, y)
    y = y + 28
    local sprint = Save.get("high_scores", "sprint")
    love.graphics.setFont(Fonts.get(14))
    if sprint and sprint.time > 0 then
        love.graphics.setColor(0.9, 0.9, 0.9)
        local mins = math.floor(sprint.time / 60)
        local secs = sprint.time % 60
        love.graphics.print(string.format("Best Time: %d:%05.2f", mins, secs), 110, y)
    else
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("No time recorded yet", 110, y)
    end

    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.printf("Press ESC or ENTER to return", 50, 530, 520, "center")
end

function HighScores:keypressed(key)
    if key == "escape" or key == "return" or key == "space" then
        StateMgr.pop()
    end
end

return HighScores
