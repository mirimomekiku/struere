local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")

local Sprint = {}
Sprint.__index = Sprint
setmetatable(Sprint, { __index = BaseMode })

function Sprint.new(config)
    config = config or {}
    config.name          = "Sprint"
    config.line_goal     = config.line_goal or 40
    config.fixed_gravity = true
    config.start_level   = config.start_level or 1
    local self = BaseMode.new(config)
    self.best_time = nil  -- will be loaded from save on start
    return self
end

function Sprint:onStart(state)
    BaseMode.onStart(self, state)
    -- Load personal best from save
    local Save = require("lib.save")
    local rec = Save.get("high_scores", "sprint")
    self.best_time = rec and rec.time or nil
end

function Sprint:drawHUD(state, x, y)
    local constants = require("lib.constants")
    local cs = constants.CELL_SIZE
    local w = math.min(love.graphics.getWidth() - x - 16, math.floor(cs * 3.4))

    -- Big timer (ms precision)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, w, 44, 6, 6)

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.40, 0.70, 0.90, 0.85)
    love.graphics.printf("TIME", x, y + 3, w, "center")

    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(0.15, 0.90, 1.0)
    love.graphics.printf(self:getTimeFormatted(true), x, y + 16, w, "center")

    if self.best_time then
        love.graphics.setFont(Fonts.get(8))
        love.graphics.setColor(1, 0.85, 0.25, 0.7)
        local bt = self.best_time
        love.graphics.printf(string.format("PB: %02d:%05.2f", math.floor(bt/60), bt%60),
            x, y + 30, w, "center")
    end

    local row_y = y + 50

    -- Lines progress bar
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, row_y, w, 40, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.40, 0.70, 0.90, 0.85)
    love.graphics.printf("LINES", x, row_y + 3, w, "center")
    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(0, 1, 0.7)
    love.graphics.printf(string.format("%d / %d", self.lines_cleared, self.line_goal),
        x, row_y + 16, w, "center")
    self:drawProgressBar(self.lines_cleared, self.line_goal,
        x, row_y + 32, w, 4, {0.15, 0.80, 1.0})

    row_y = row_y + 46
    self:drawStatRow("PPS", string.format("%.2f", self:getPPS()), x, row_y, w)
    row_y = row_y + 42
    self:drawStatRow("PIECES", self.pieces_placed, x, row_y, w)
end

return Sprint
