local BaseMode = require("lib.modes.base")

local Sprint = {}
Sprint.__index = Sprint
setmetatable(Sprint, { __index = BaseMode })

function Sprint.new(config)
    config = config or {}
    config.name = config.name or "Sprint"
    config.line_goal = config.line_goal or 40
    config.fixed_gravity = true
    config.start_level = config.start_level or 1
    return BaseMode.new(config)
end

function Sprint:drawHUD(state, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE", x, y)
    love.graphics.print(tostring(state.score), x, y + 20)

    love.graphics.print("LINES", x, y + 60)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print(tostring(self.lines_cleared) .. "/" .. tostring(self.line_goal), x, y + 80)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TIME", x, y + 130)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(self:getTimeFormatted(), x, y + 150)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Mode: Sprint", x, y + 210)
end

return Sprint
