local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")
local Board    = require("lib.board")
local Queue    = require("lib.queue")

local Zen = {}
Zen.__index = Zen
setmetatable(Zen, { __index = BaseMode })

function Zen.new(config)
    config = config or {}
    config.name          = "Zen"
    config.fixed_gravity = true
    config.start_level   = config.start_level or 1
    config.can_lose      = false
    local self = BaseMode.new(config)
    self.undo_available = false
    return self
end

function Zen:checkGameOver(state)
    return false
end

-- Override beforeLock to flag undo as available
function Zen:beforeLock(state)
    BaseMode.beforeLock(self, state)
    self.undo_available = true
end

-- Allow re-try with any key "u"
function Zen:tryUndo(state)
    if self.undo_board and self.undo_available then
        self.undo_available = false
        return BaseMode.tryUndo(self, state)
    end
    return false
end

function Zen:onStart(state)
    state.level = self.start_level
end

function Zen:drawHUD(state, x, y)
    local constants = require("lib.constants")
    local cs = constants.CELL_SIZE
    local w = math.min(love.graphics.getWidth() - x - 16, math.floor(cs * 3.4))

    self:drawStatRow("LEVEL", state.level, x, y, w)
    self:drawStatRow("LINES", state.lines, x, y + 42, w)

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, y + 84, w, 36, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.25, 0.75, 0.65, 0.85)
    love.graphics.printf("TIME", x, y + 87, w, "center")
    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(0.15, 0.95, 0.80)
    love.graphics.printf(self:getTimeFormatted(), x, y + 101, w, "center")

    -- Undo indicator
    local undo_y = y + 126
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, undo_y, w, 32, 6, 6)
    love.graphics.setFont(Fonts.get(8))
    if self.undo_available then
        local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.15, 0.85, 0.60, pulse)
        love.graphics.printf("CTRL+Z / U", x, undo_y + 3, w, "center")
        love.graphics.printf("UNDO READY", x, undo_y + 16, w, "center")
    else
        love.graphics.setColor(0.40, 0.45, 0.55, 0.6)
        love.graphics.printf("CTRL+Z / U", x, undo_y + 3, w, "center")
        love.graphics.printf("Undo", x, undo_y + 16, w, "center")
    end
end

return Zen
