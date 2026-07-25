local Scoring = require("lib.scoring")

local Fonts = require("lib.fonts")

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
        if state.current_piece then
            self.undo_piece_type = state.current_piece.type
        end
    end
end

function BaseMode:tryUndo(state)
    if self.undo_board then
        local Board = require("lib.board")
        local Piece = require("lib.piece")
        local Queue = require("lib.queue")
        local Gameplay = state  -- state IS gameplay
        Gameplay.board  = self.undo_board
        Gameplay.lines  = self.undo_lines
        Gameplay.score  = self.undo_score
        self.undo_board = nil
        -- Respawn piece
        local ptype = self.undo_piece_type or Queue.pop(Gameplay.randomizer)
        Gameplay.current_piece = Piece.new(ptype, 21, 4)
        Gameplay.is_grounded  = false
        Gameplay.lock_timer   = 0
        Gameplay.lock_moves   = 0
        Gameplay.drop_timer   = 0
        return true
    end
    return false
end

function BaseMode:onLineClear(state, lines_cleared, rows, t_spin_type)
    self.lines_cleared = self.lines_cleared + lines_cleared
    local is_t_spin = (t_spin_type == "full" or t_spin_type == "mini")
    if is_t_spin then
        self.t_spins = self.t_spins + 1
    end

    if lines_cleared > 0 or is_t_spin then
        local Save = require("lib.save")
        if lines_cleared > 0 then
            Save.record_line_clear(lines_cleared)
        end

        if lines_cleared > 0 then
            self.combo = self.combo + 1
            if self.combo > self.max_combo then
                self.max_combo = self.combo
            end
        end

        -- Back-to-Back & T-Spin Scoring
        local is_tetris = (lines_cleared == 4)
        local b2b_eligible = is_tetris or (is_t_spin and lines_cleared > 0)

        local line_score = Scoring.calculate(lines_cleared, state.level, t_spin_type, self.back_to_back)

        -- ─── Dynamic Juiced Popup Engine Triggers ────────────────────────────
        local constants = require("lib.constants")
        local Effects = require("lib.effects")
        local cx = constants.BOARD_X + 5 * constants.CELL_SIZE
        local cy = constants.BOARD_Y + 8 * constants.CELL_SIZE

        if is_t_spin then
            local label = "T-SPIN"
            if t_spin_type == "full" then
                if lines_cleared == 1 then label = "T-SPIN SINGLE"
                elseif lines_cleared == 2 then label = "T-SPIN DOUBLE"
                elseif lines_cleared == 3 then label = "T-SPIN TRIPLE"
                end
            elseif t_spin_type == "mini" then
                if lines_cleared == 0 then label = "MINI T-SPIN"
                elseif lines_cleared == 1 then label = "MINI T-SPIN SINGLE"
                elseif lines_cleared == 2 then label = "MINI T-SPIN DOUBLE"
                end
            end
            if self.back_to_back and b2b_eligible then
                label = "B2B " .. label
            end
            Effects.spawn_popup(label, cx, cy, {0.95, 0.35, 0.95}, 1.4, 22)
        elseif lines_cleared == 4 then
            local label = self.back_to_back and "B2B TETRIS!" or "TETRIS!"
            Effects.spawn_popup(label, cx, cy, {0.15, 0.95, 1.0}, 1.4, 24)
        elseif lines_cleared == 3 then
            Effects.spawn_popup("TRIPLE!", cx, cy, {0.3, 0.95, 0.4}, 1.2, 22)
        elseif lines_cleared == 2 then
            Effects.spawn_popup("DOUBLE!", cx, cy, {0.4, 0.8, 1.0}, 1.2, 20)
        elseif lines_cleared == 1 then
            Effects.spawn_popup("SINGLE!", cx, cy, {0.85, 0.85, 0.85}, 1.0, 18)
        end

        if lines_cleared > 0 and self.combo >= 1 then
            local combo_str = string.format("%d COMBO%s!", self.combo, self.combo > 1 and "S" or "")
            local pop_y = cy + (lines_cleared > 0 and 26 or 0)
            Effects.spawn_popup(combo_str, cx, pop_y, {1.0, 0.55, 0.15}, 1.2, 20)
        end

        if b2b_eligible then
            if self.back_to_back then
                self.back_to_back_count = self.back_to_back_count + 1
            end
            self.back_to_back = true
        elseif lines_cleared > 0 then
            self.back_to_back = false
        end

        -- All-clear bonus
        local Board = require("lib.board")
        local Audio = require("lib.audio")
        local ac_bonus = 0
        if Board.is_empty(state.board) then
            self.all_clears = self.all_clears + 1
            ac_bonus = Scoring.ALL_CLEAR_BONUS * state.level
            if Save.data and Save.data.stats then
                Save.data.stats.all_clears = (Save.data.stats.all_clears or 0) + 1
            end
            Effects.all_clear_burst(constants.BOARD_X, constants.BOARD_Y, constants.CELL_SIZE)
            Audio.play("all_clear")
        end

        if lines_cleared > 0 then
            if not self.fixed_gravity then
                state.lines = state.lines + lines_cleared
                state.level = math.min(
                    math.floor(state.lines / self.lines_per_level) + 1,
                    self.max_level
                )
            else
                state.lines = state.lines + lines_cleared
            end
        end

        -- Add score
        state.score = state.score + line_score + ac_bonus

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
    local Save = require("lib.save")
    Save.record_piece_place(false, false)
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

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(label_color[1], label_color[2], label_color[3])
    love.graphics.printf(label, x, y + 4, w, "center")

    love.graphics.setFont(Fonts.get(14))
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
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.8, 0.8, 0.9, 0.7)
    if total then
        love.graphics.printf(string.format("%d / %d", cur, total), x, y - 1, w, "center")
    else
        love.graphics.printf(string.format("%d lines", cur), x, y - 1, w, "center")
    end
end

function BaseMode:drawHUD(state, x, y)
    local constants = require("lib.constants")
    local cs = constants.CELL_SIZE
    local w = math.min(love.graphics.getWidth() - x - 16, math.floor(cs * 3.4))
    self:drawStatRow("LEVEL",  state.level, x, y,      w)
    self:drawStatRow("LINES",  state.lines, x, y + 42, w)
    self:drawStatRow("TIME",   self:getTimeFormatted(), x, y + 84, w)

    -- Real-time HUD Metrics Card (PPS, KPP, APM)
    local pps = self:getPPS()
    local inputs = state.total_inputs or 0
    local pieces = math.max(1, self.pieces_placed)
    local kpp = inputs / pieces
    local time_mins = math.max(0.1, self.timer) / 60
    local attacks = (self.garbage_sent or 0) + (self.lines_cleared or 0)
    local apm = attacks / time_mins

    local my = y + 126
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, my, w, 52, 6, 6)
    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.55, 0.65, 0.75, 0.85)
    love.graphics.printf("METRICS", x, my + 3, w, "center")

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.2, 0.9, 0.9)
    love.graphics.printf(string.format("PPS: %.2f", pps), x + 8, my + 16, w - 16, "left")
    love.graphics.setColor(0.9, 0.8, 0.2)
    love.graphics.printf(string.format("KPP: %.2f", kpp), x + 8, my + 28, w - 16, "left")
    love.graphics.setColor(1.0, 0.4, 0.6)
    love.graphics.printf(string.format("APM: %.1f", apm), x + 8, my + 38, w - 16, "left")
end

return BaseMode
