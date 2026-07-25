local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")
local Board    = require("lib.board")
local Queue    = require("lib.queue")
local Piece    = require("lib.piece")
local Effects  = require("lib.effects")
local Audio    = require("lib.audio")
local constants = require("lib.constants")

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
    self.undo_stack = {}
    self.redo_stack = {}
    return self
end

function Zen:checkGameOver(state)
    return false
end

-- Save state snapshot before locking
function Zen:beforeLock(state)
    BaseMode.beforeLock(self, state)
    if state.board then
        table.insert(self.undo_stack, {
            board = Board.deep_copy(state.board),
            lines = state.lines,
            score = state.score,
            piece_type = state.current_piece and state.current_piece.type or "I"
        })
        if #self.undo_stack > 50 then table.remove(self.undo_stack, 1) end
        self.redo_stack = {} -- Clear redo history on new action
    end
end

-- Undo board & piece state
function Zen:tryUndo(state)
    if #self.undo_stack > 0 then
        -- Save current state to redo_stack before undoing
        if state.board then
            table.insert(self.redo_stack, {
                board = Board.deep_copy(state.board),
                lines = state.lines,
                score = state.score,
                piece_type = state.current_piece and state.current_piece.type or "I"
            })
        end
        local snapshot = table.remove(self.undo_stack)
        state.board = snapshot.board
        state.lines = snapshot.lines
        state.score = snapshot.score
        state.displayed_score = snapshot.score
        state.spawn_piece(snapshot.piece_type)
        Effects.spawn_popup("UNDO", constants.BOARD_X + 5 * constants.CELL_SIZE, constants.BOARD_Y + 10 * constants.CELL_SIZE, {0.2, 0.8, 1.0})
        Audio.play("hold")
        return true
    end
    return false
end

-- Redo board & piece state
function Zen:tryRedo(state)
    if #self.redo_stack > 0 then
        if state.board then
            table.insert(self.undo_stack, {
                board = Board.deep_copy(state.board),
                lines = state.lines,
                score = state.score,
                piece_type = state.current_piece and state.current_piece.type or "I"
            })
        end
        local snapshot = table.remove(self.redo_stack)
        state.board = snapshot.board
        state.lines = snapshot.lines
        state.score = snapshot.score
        state.displayed_score = snapshot.score
        state.spawn_piece(snapshot.piece_type)
        Effects.spawn_popup("REDO", constants.BOARD_X + 5 * constants.CELL_SIZE, constants.BOARD_Y + 10 * constants.CELL_SIZE, {0.2, 0.9, 0.4})
        Audio.play("move")
        return true
    end
    return false
end

-- Force next piece to be an I-piece
function Zen:injectPiece(state, ptype)
    ptype = ptype or "I"
    state.spawn_piece(ptype)
    Effects.spawn_popup("I-PIECE INJECTED", constants.BOARD_X + 5 * constants.CELL_SIZE, constants.BOARD_Y + 10 * constants.CELL_SIZE, {0.0, 0.9, 0.9})
    Audio.play("hold")
end

-- Clear board grid
function Zen:clearBoard(state)
    if state.board then
        table.insert(self.undo_stack, {
            board = Board.deep_copy(state.board),
            lines = state.lines,
            score = state.score,
            piece_type = state.current_piece and state.current_piece.type or "I"
        })
    end
    state.board = Board.new()
    Effects.spawn_popup("GRID CLEARED", constants.BOARD_X + 5 * constants.CELL_SIZE, constants.BOARD_Y + 10 * constants.CELL_SIZE, {1.0, 0.4, 0.4})
    Audio.play("all_clear")
end

function Zen:onStart(state)
    state.level = self.start_level
end

function Zen:drawHUD(state, x, y)
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

    -- Real-time HUD Metrics Card
    local pps = self:getPPS()
    local inputs = state.total_inputs or 0
    local pieces = math.max(1, self.pieces_placed)
    local kpp = inputs / pieces
    local time_mins = math.max(0.1, self.timer) / 60
    local attacks = (self.garbage_sent or 0) + (self.lines_cleared or 0)
    local apm = attacks / time_mins

    local my = y + 126
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x, my, w, 50, 6, 6)
    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.55, 0.65, 0.75, 0.85)
    love.graphics.printf("REAL-TIME METRICS", x, my + 3, w, "center")

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.2, 0.9, 0.9)
    love.graphics.printf(string.format("PPS: %.2f", pps), x + 8, my + 15, w - 16, "left")
    love.graphics.setColor(0.9, 0.8, 0.2)
    love.graphics.printf(string.format("KPP: %.2f", kpp), x + 8, my + 26, w - 16, "left")
    love.graphics.setColor(1.0, 0.4, 0.6)
    love.graphics.printf(string.format("APM: %.1f", apm), x + 8, my + 37, w - 16, "left")

    -- Sandbox Tools Card
    local sy = y + 182
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", x, sy, w, 78, 6, 6)
    love.graphics.setColor(0.25, 0.75, 0.65, 0.7)
    love.graphics.rectangle("line", x, sy, w, 78, 6, 6)

    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.25, 0.85, 0.65)
    love.graphics.printf("SANDBOX TOOLS", x, sy + 4, w, "center")

    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.85, 0.9, 1.0)
    love.graphics.printf("U / CTRL+Z : Undo (" .. #self.undo_stack .. ")", x + 6, sy + 18, w - 12, "left")
    love.graphics.printf("R / CTRL+Y : Redo (" .. #self.redo_stack .. ")", x + 6, sy + 32, w - 12, "left")
    love.graphics.printf("I : Inject I-Piece", x + 6, sy + 46, w - 12, "left")
    love.graphics.printf("C / DEL : Clear Grid", x + 6, sy + 60, w - 12, "left")
end

return Zen
