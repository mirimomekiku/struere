local BaseMode = require("lib.modes.base")

local Blitz = {}
Blitz.__index = Blitz
setmetatable(Blitz, { __index = BaseMode })

function Blitz.new(config)
    config = config or {}
    config.name = config.name or "Blitz"
    config.time_limit = config.time_limit or 120
    config.fixed_gravity = true
    config.start_level = config.start_level or 5
    local self = BaseMode.new(config)
    self.combo_multiplier = 1
    return self
end

function Blitz:onLineClear(state, lines_cleared, rows)
    if lines_cleared > 0 then
        self.combo = self.combo + 1
        if self.combo > self.max_combo then
            self.max_combo = self.combo
        end
        self.combo_multiplier = 1 + (self.combo - 1) * 0.5
        self.lines_cleared = self.lines_cleared + lines_cleared
        state.lines = state.lines + lines_cleared
    else
        self.combo = 0
        self.combo_multiplier = 1
    end
end

function Blitz:getScoringMultiplier()
    return self.combo_multiplier
end

function Blitz:drawHUD(state, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE", x, y)
    love.graphics.print(tostring(state.score), x, y + 20)

    local time_left = math.max(0, self.time_limit - self.timer)
    local minutes = math.floor(time_left / 60)
    local seconds = time_left % 60
    love.graphics.print("TIME LEFT", x, y + 60)
    if time_left < 10 then
        love.graphics.setColor(1, 0, 0)
    else
        love.graphics.setColor(1, 1, 0)
    end
    love.graphics.print(string.format("%d:%05.2f", minutes, seconds), x, y + 80)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("COMBO", x, y + 130)
    if self.combo > 1 then
        love.graphics.setColor(1, 0.8, 0)
        love.graphics.print("x" .. string.format("%.1f", self.combo_multiplier), x, y + 150)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("---", x, y + 150)
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Mode: Blitz", x, y + 210)
end

return Blitz
