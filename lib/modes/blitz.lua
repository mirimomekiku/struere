local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")
local Scoring  = require("lib.scoring")

local Blitz = {}
Blitz.__index = Blitz
setmetatable(Blitz, { __index = BaseMode })

function Blitz.new(config)
    config = config or {}
    config.name          = "Blitz"
    config.time_limit    = config.time_limit or 120
    config.fixed_gravity = true
    config.start_level   = config.start_level or 5
    local self = BaseMode.new(config)
    self.combo_multiplier = 1.0
    return self
end

function Blitz:onLineClear(state, lines_cleared, rows)
    if lines_cleared > 0 then
        self.combo = self.combo + 1
        if self.combo > self.max_combo then self.max_combo = self.combo end

        self.combo_multiplier = 1 + (self.combo - 1) * 0.5
        self.lines_cleared = self.lines_cleared + lines_cleared
        state.lines = state.lines + lines_cleared

        -- Back-to-back Tetris bonus
        local is_tetris = (lines_cleared == 4)
        if is_tetris and self.back_to_back then
            local btb_bonus = math.floor(Scoring.BACK_TO_BACK_BONUS * self.combo_multiplier)
            state.score = state.score + btb_bonus
            self.back_to_back_count = (self.back_to_back_count or 0) + 1
        end
        self.back_to_back = is_tetris

        -- All-clear bonus
        local Board = require("lib.board")
        if Board.is_empty(state.board) then
            self.all_clears = (self.all_clears or 0) + 1
            state.score = state.score + math.floor(Scoring.ALL_CLEAR_BONUS * self.combo_multiplier)
        end
    else
        self.combo = 0
        self.combo_multiplier = 1.0
    end
end

function Blitz:getScoringMultiplier()
    return self.combo_multiplier
end

function Blitz:drawHUD(state, x, y)
    local constants = require("lib.constants")
    local cs = constants.CELL_SIZE
    local w = math.min(love.graphics.getWidth() - x - 16, math.floor(cs * 3.4))

    local time_left = math.max(0, self.time_limit - self.timer)
    local minutes = math.floor(time_left / 60)
    local seconds = time_left % 60

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, w, 44, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.80, 0.55, 0.20, 0.85)
    love.graphics.printf("TIME LEFT", x, y + 3, w, "center")

    local urgency = 1 - (time_left / self.time_limit)
    local tr = math.min(1, urgency * 2)
    local tg = math.max(0, 1 - (urgency - 0.5) * 2)

    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(tr, tg, 0.1)
    if time_left < 10 then
        local pulse = math.sin(love.timer.getTime() * 8) * 0.3 + 0.7
        love.graphics.setColor(1, 0, 0, pulse)
    end
    love.graphics.printf(string.format("%02d:%05.2f", minutes, seconds), x, y + 17, w, "center")

    local row_y = y + 48

    -- Combo
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, row_y, w, 36, 6, 6)
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.55, 0.65, 0.75)
    love.graphics.printf("COMBO", x, row_y + 3, w, "center")
    love.graphics.setFont(Fonts.get(13))
    if self.combo > 1 then
        love.graphics.setColor(1, 0.75, 0)
        love.graphics.printf(string.format("×%.1f (x%d)", self.combo_multiplier, self.combo),
            x, row_y + 17, w, "center")
    else
        love.graphics.setColor(0.45, 0.50, 0.60)
        love.graphics.printf("—", x, row_y + 17, w, "center")
    end

    row_y = row_y + 42
    self:drawStatRow("LINES", self.lines_cleared, x, row_y, w)
end

return Blitz
