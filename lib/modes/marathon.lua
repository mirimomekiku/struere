local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")

local Marathon = {}
Marathon.__index = Marathon
setmetatable(Marathon, { __index = BaseMode })

function Marathon.new(config)
    config = config or {}
    config.name            = "Marathon"
    config.lines_per_level = 10
    config.max_level       = 20
    -- line_goal from config (150, 200, or nil=endless)
    return BaseMode.new(config)
end

function Marathon:onStart(state)
    BaseMode.onStart(self, state)
end

function Marathon:drawHUD(state, x, y)
    local constants = require("lib.constants")
    local cs = constants.CELL_SIZE
    local w = math.min(love.graphics.getWidth() - x - 16, math.floor(cs * 3.4))

    self:drawStatRow("LEVEL", state.level, x, y, w)

    local bar_y = y + 42
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, bar_y, w, 36, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.55, 0.65, 0.75)
    love.graphics.printf("LINES", x, bar_y + 3, w, "center")
    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(1, 0.90, 0.25)
    local lines_str = self.line_goal
        and string.format("%d/%d", self.lines_cleared, self.line_goal)
        or tostring(self.lines_cleared)
    love.graphics.printf(lines_str, x, bar_y + 17, w, "center")

    if self.line_goal then
        self:drawProgressBar(self.lines_cleared, self.line_goal,
            x, bar_y + 30, w, 4, {0.75, 0.25, 1.0})
    end

    self:drawStatRow("TIME", self:getTimeFormatted(), x, y + 84, w)
end

return Marathon
