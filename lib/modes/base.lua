local Scoring = require("lib.scoring")

local BaseMode = {}
BaseMode.__index = BaseMode

function BaseMode.new(config)
    local self = setmetatable({}, BaseMode)
    self.name              = config.name or "Base"
    self.start_level       = config.start_level or 1
    self.lines_per_level   = config.lines_per_level or 10
    self.max_level         = config.max_level or 20
    self.line_goal         = config.line_goal or nil
    self.time_limit        = config.time_limit or nil
    self.lock_delay        = config.lock_delay or 0.5
    self.fixed_gravity     = config.fixed_gravity or false
    self.can_lose          = config.can_lose ~= false
    self.timer             = 0
    self.combo             = 0
    self.max_combo         = 0
    self.pieces_placed     = 0
    self.lines_cleared     = 0
    self.all_clears        = 0
    self.back_to_back      = false   -- previous clear was Tetris (4 lines)
    self.back_to_back_count = 0
    self.last_was_rotation = false   -- for T-spin detection
    self.t_spins           = 0
    self.undo_board        = nil     -- single-step undo snapshot
    self.undo_piece        = nil
    self.undo_lines        = 0
    self.undo_score        = 0
    return self
end

function BaseMode:onStart(state)
    state.level = self.start_level
end

function BaseMode:onTick(state, dt)
    self.timer = self.timer + dt
    if self.time_limit and self.timer >= self.time_limit then
        state.game_over = true
    end
end

-- Called just before a piece locks so we can save undo snapshot
function BaseMode:beforeLock(state)
    if state.board then
        local Board = require("lib.board")
        self.undo_board  = Board.deep_copy(state.board)
        self.undo_lines  = state.lines
        self.undo_score  = state.score
    end
end

function BaseMode:tryUndo(state)
    if self.undo_board then
        local Board = require("lib.board")
        local Queue = require("lib.queue")
        local Gameplay = state  -- state IS gameplay
        Gameplay.board  = self.undo_board
        Gameplay.lines  = self.undo_lines
        Gameplay.score  = self.undo_score
        self.undo_board = nil
        -- Respawn a piece
        local Piece = require("lib.piece")
        local Randomizer = require("lib.randomizer")
        local ptype = Queue.pop(Gameplay.randomizer)
        Gameplay.current_piece = Piece.new(ptype, 21, 4)
        Gameplay.is_grounded  = false
        Gameplay.lock_timer   = 0
        return true
    end
    return false
end

function BaseMode:onLineClear(state, lines_cleared, rows)
    self.lines_cleared = self.lines_cleared + lines_cleared
    if lines_cleared > 0 then
        self.combo = self.combo + 1
        if self.combo > self.max_combo then
            self.max_combo = self.combo end

        -- Back-to-Back bonus
        local is_tetris = (lines_cleared == 4)
        local btb_bonus = 0
        if is_tetris then
            if self.back_to_back then
                btb_bonus = Scoring.BACK_TO_BACK_BONUS * state.level
                self.back_to_back_count = self.back_to_back_count + 1
            end
            self.back_to_back = true
        else
            self.back_to_back = false
        end

        -- All-clear bonus
        local Board = require("lib.board")
        local ac_bonus = 0
        if Board.is_empty(state.board) then
            self.all_clears = self.all_clears + 1
            ac_bonus = Scoring.ALL_CLEAR_BONUS * state.level
        end

        if not self.fixed_gravity then
            state.lines = state.lines + lines_cleared
            state.level = math.min(
                math.floor(state.lines / self.lines_per_level) + 1,
                self.max_level
            )
        else
            state.lines = state.lines + lines_cleared
        end

        -- Add special bonuses on top of base score
        state.score = state.score + btb_bonus + ac_bonus

        if self.line_goal and self.lines_cleared >= self.line_goal then
            state.game_over = true
            state.victory = true
        end
    else
        self.combo = 0
    end
end

function BaseMode:onPieceLock(state)
    self.pieces_placed = self.pieces_placed + 1
end

function BaseMode:onGameOver(state)
end

function BaseMode:checkGameOver(state)
    return state.game_over
end

function BaseMode:getDropInterval(state)
    if self.fixed_gravity then
        return Scoring.drop_interval(self.start_level)
    end
    return Scoring.drop_interval(state.level)
end

function BaseMode:getScoringMultiplier()
    return 1
end

function BaseMode:getTimeFormatted(ms)
    local t = self.timer
    local minutes = math.floor(t / 60)
    local seconds = t % 60
    if ms then
        return string.format("%02d:%06.3f", minutes, seconds)
    end
    return string.format("%d:%05.2f", minutes, seconds)
end

function BaseMode:getPPS()
    if self.timer < 0.1 then return 0 end
    return self.pieces_placed / self.timer
end

-- ─── HUD helpers ──────────────────────────────────────────────────────────────

function BaseMode:drawStatRow(label, val, x, y, w, label_color, val_color, theme)
    label_color = label_color or {0.55, 0.65, 0.75}
    val_color   = val_color   or {1, 0.90, 0.25}

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, y, w, 38, 6, 6)

    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(label_color[1], label_color[2], label_color[3])
    love.graphics.printf(label, x, y + 4, w, "center")

    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(val_color[1], val_color[2], val_color[3])
    love.graphics.printf(tostring(val), x, y + 18, w, "center")
end

function BaseMode:drawProgressBar(cur, total, x, y, w, h, color)
    local pct = total and math.min(1, cur / total) or 0
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    if pct > 0 then
        love.graphics.setColor(color[1], color[2], color[3], 0.85)
        love.graphics.rectangle("fill", x, y, w * pct, h, 3, 3)
    end
    -- Track label
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(0.8, 0.8, 0.9, 0.7)
    if total then
        love.graphics.printf(string.format("%d / %d", cur, total), x, y - 1, w, "center")
    else
        love.graphics.printf(string.format("%d lines", cur), x, y - 1, w, "center")
    end
end

function BaseMode:drawHUD(state, x, y)
    local w = love.graphics.getWidth() - x - 16
    self:drawStatRow("SCORE",  state.score, x, y,      w)
    self:drawStatRow("LEVEL",  state.level, x, y + 46, w)
    self:drawStatRow("LINES",  state.lines, x, y + 92, w)
    self:drawStatRow("TIME",   self:getTimeFormatted(), x, y + 138, w)
end

return BaseMode
