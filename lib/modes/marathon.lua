local BaseMode = require("lib.modes.base")

local Marathon = {}
Marathon.__index = Marathon
setmetatable(Marathon, { __index = BaseMode })

function Marathon.new(config)
    config = config or {}
    config.name = config.name or "Marathon"
    config.lines_per_level = config.lines_per_level or 10
    config.max_level = config.max_level or 20
    return BaseMode.new(config)
end

function Marathon:drawHUD(state, x, y)
    BaseMode.drawHUD(self, state, x, y)
    local y2 = y + 260
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Mode: Marathon", x, y2)
    love.graphics.print("Lines to next level:", x, y2 + 20)
    local lines_to_next = self.lines_per_level - (state.lines % self.lines_per_level)
    love.graphics.print(tostring(lines_to_next), x, y2 + 40)
end

return Marathon
