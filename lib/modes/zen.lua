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
    local W = love.graphics.getWidth()
    local w = W - x - 16
    local teal = {0.15, 0.85, 0.75}

    self:drawStatRow("SCORE", state.score, x, y, w)
    self:drawStatRow("LINES", state.lines, x, y + 46, w)

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, y + 92, w, 38, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.25, 0.75, 0.65, 0.85)
    love.graphics.printf("TIME", x, y + 96, w, "center")
    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(0.15, 0.95, 0.80)
    love.graphics.printf(self:getTimeFormatted(), x, y + 110, w, "center")

    -- Undo indicator
    local undo_y = y + 140
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", x, undo_y, w, 30, 6, 6)
    love.graphics.setFont(Fonts.get(10))
    if self.undo_available then
        local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.15, 0.85, 0.60, pulse)
        love.graphics.printf("U — UNDO AVAILABLE", x, undo_y + 8, w, "center")
    else
        love.graphics.setColor(0.30, 0.35, 0.45, 0.6)
        love.graphics.printf("U — Undo (lock piece first)", x, undo_y + 8, w, "center")
    end

    -- Gravity level
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.12, 0.65, 0.58, 0.75)
    love.graphics.printf(string.format("Gravity Lv.%d  ← Customise in Settings", state.level), x, undo_y + 38, w, "center")

    -- Mode tag
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.08, 0.55, 0.50, 0.8)
    love.graphics.printf("ZEN  ∞ INFINITE", x, undo_y + 52, w, "center")
end

return Zen
