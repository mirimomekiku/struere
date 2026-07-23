local BaseMode = require("lib.modes.base")

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
    local W = love.graphics.getWidth()
    local w = W - x - 16
    local theme_accent = {0.75, 0.25, 1.0}

    -- Score
    self:drawStatRow("SCORE", state.score, x, y, w)
    -- Level with bar
    self:drawStatRow("LEVEL", state.level, x, y + 46, w)

    -- Lines progress bar
    local bar_y = y + 92
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, bar_y, w, 38, 6, 6)
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(0.55, 0.65, 0.75)
    love.graphics.printf("LINES", x, bar_y + 4, w, "center")
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 0.90, 0.25)
    local lines_str = self.line_goal
        and string.format("%d / %d", self.lines_cleared, self.line_goal)
        or tostring(self.lines_cleared)
    love.graphics.printf(lines_str, x, bar_y + 18, w, "center")

    -- Progress bar
    if self.line_goal then
        self:drawProgressBar(self.lines_cleared, self.line_goal,
            x, bar_y + 36, w, 6, theme_accent)
    end

    -- Time
    self:drawStatRow("TIME", self:getTimeFormatted(), x, y + 138, w)

    -- Lines to next level
    local ltnl = self.lines_per_level - (state.lines % self.lines_per_level)
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(0.45, 0.55, 0.65, 0.8)
    love.graphics.printf(string.format("Next level in %d lines", ltnl), x, y + 184, w, "center")

    -- Mode tag
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(0.55, 0.20, 0.75, 0.8)
    local goal_str = self.line_goal and (self.line_goal .. "L") or "ENDLESS"
    love.graphics.printf("MARATHON  " .. goal_str, x, y + 198, w, "center")
end

return Marathon
