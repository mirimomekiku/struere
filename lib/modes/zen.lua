local BaseMode = require("lib.modes.base")
local Fonts    = require("lib.fonts")
local Board    = require("lib.board")
local Queue    = require("lib.queue")
local Piece    = require("lib.piece")
local Effects  = require("lib.effects")
local Audio    = require("lib.audio")
local constants = require("lib.constants")
local Presets  = require("lib.presets")

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
    self.show_preset_overlay = false
    self.selected_category_idx = 1
    self.selected_item_idx = 1
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

-- ─── Preset Library Practice Loader ──────────────────────────────────────────
function Zen:loadPreset(state, preset_item)
    if not preset_item then return end
    if state.board then
        table.insert(self.undo_stack, {
            board = Board.deep_copy(state.board),
            lines = state.lines,
            score = state.score,
            piece_type = state.current_piece and state.current_piece.type or "I"
        })
    end

    state.board = Presets.build_board(preset_item)
    if preset_item.queue and #preset_item.queue > 0 then
        Queue.next_queue = {}
        for _, ptype in ipairs(preset_item.queue) do
            table.insert(Queue.next_queue, ptype)
        end
    end

    state.spawn_piece()
    self.show_preset_overlay = false

    local cx = constants.BOARD_X + 5 * constants.CELL_SIZE
    local cy = constants.BOARD_Y + 8 * constants.CELL_SIZE
    Effects.spawn_popup("LOADED: " .. preset_item.name, cx, cy, {0.2, 0.95, 0.5}, 1.8, 22)
    Audio.play("hold")
end

function Zen:togglePresetOverlay()
    self.show_preset_overlay = not self.show_preset_overlay
    Audio.play("move")
end

function Zen:handlePresetInput(key, state)
    if not self.show_preset_overlay then return false end

    local current_cat = Presets.categories[self.selected_category_idx]
    local items = Presets.getByCategory(current_cat.id)

    if key == "escape" or key == "p" or key == "f2" then
        self.show_preset_overlay = false
        Audio.play("move")
        return true
    elseif key == "up" then
        self.selected_item_idx = self.selected_item_idx - 1
        if self.selected_item_idx < 1 then self.selected_item_idx = math.max(1, #items) end
        Audio.play("move")
        return true
    elseif key == "down" then
        self.selected_item_idx = self.selected_item_idx + 1
        if self.selected_item_idx > #items then self.selected_item_idx = 1 end
        Audio.play("move")
        return true
    elseif key == "left" or key == "tab" then
        self.selected_category_idx = self.selected_category_idx - 1
        if self.selected_category_idx < 1 then self.selected_category_idx = #Presets.categories end
        self.selected_item_idx = 1
        Audio.play("move")
        return true
    elseif key == "right" then
        self.selected_category_idx = self.selected_category_idx + 1
        if self.selected_category_idx > #Presets.categories then self.selected_category_idx = 1 end
        self.selected_item_idx = 1
        Audio.play("move")
        return true
    elseif key == "return" or key == "space" then
        local selected = items[self.selected_item_idx]
        if selected then
            self:loadPreset(state, selected)
        end
        return true
    end

    -- Quick number keys 1..9
    local num = tonumber(key)
    if num and items[num] then
        self:loadPreset(state, items[num])
        return true
    end

    return true -- Consume all inputs while preset overlay is active
end

function Zen:onStart(state)
    state.level = self.start_level
    self.show_preset_overlay = true
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
    love.graphics.rectangle("fill", x, sy, w, 92, 6, 6)
    love.graphics.setColor(0.25, 0.75, 0.65, 0.7)
    love.graphics.rectangle("line", x, sy, w, 92, 6, 6)

    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.25, 0.85, 0.65)
    love.graphics.printf("SANDBOX & PRESETS", x, sy + 4, w, "center")

    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.85, 0.9, 1.0)
    love.graphics.printf("P / F2 : Preset Library", x + 6, sy + 18, w - 12, "left")
    love.graphics.printf("U / CTRL+Z : Undo (" .. #self.undo_stack .. ")", x + 6, sy + 32, w - 12, "left")
    love.graphics.printf("R / CTRL+Y : Redo (" .. #self.redo_stack .. ")", x + 6, sy + 46, w - 12, "left")
    love.graphics.printf("I : Inject I-Piece", x + 6, sy + 60, w - 12, "left")
    love.graphics.printf("C / DEL : Clear Grid", x + 6, sy + 74, w - 12, "left")
end

-- ─── Preset Selection UI Overlay ──────────────────────────────────────────────
function Zen:drawPresetOverlay()
    if not self.show_preset_overlay then return end

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    -- Dark backdrop blur overlay
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local pw, ph = 520, 360
    local px = math.floor((W - pw) / 2)
    local py = math.floor((H - ph) / 2)

    -- Modal panel card
    love.graphics.setColor(0.08, 0.11, 0.18, 0.95)
    love.graphics.rectangle("fill", px, py, pw, ph, 10, 10)
    love.graphics.setColor(0.2, 0.8, 0.9, 0.85)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 10, 10)
    love.graphics.setLineWidth(1)

    -- Title header
    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(0.2, 0.95, 0.95)
    love.graphics.printf("TRAINING TOOLS: SETUP PRACTICE LOADER", px, py + 12, pw, "center")

    -- Category Tabs
    local tab_y = py + 42
    local tab_w = math.floor((pw - 30) / #Presets.categories)
    for c_idx, cat in ipairs(Presets.categories) do
        local tx = px + 15 + (c_idx - 1) * tab_w
        local is_sel = (c_idx == self.selected_category_idx)
        if is_sel then
            love.graphics.setColor(0.18, 0.45, 0.65, 0.9)
            love.graphics.rectangle("fill", tx, tab_y, tab_w - 6, 26, 6, 6)
            love.graphics.setColor(0.3, 0.9, 1.0)
            love.graphics.rectangle("line", tx, tab_y, tab_w - 6, 26, 6, 6)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.05, 0.08, 0.14, 0.7)
            love.graphics.rectangle("fill", tx, tab_y, tab_w - 6, 26, 6, 6)
            love.graphics.setColor(0.5, 0.6, 0.7)
        end
        love.graphics.setFont(Fonts.get(9))
        love.graphics.printf(cat.name, tx, tab_y + 6, tab_w - 6, "center")
    end

    -- Preset Items List in active category
    local current_cat = Presets.categories[self.selected_category_idx]
    local items = Presets.getByCategory(current_cat.id)

    local list_y = tab_y + 36
    for i, item in ipairs(items) do
        local iy = list_y + (i - 1) * 44
        local is_item_sel = (i == self.selected_item_idx)
        if is_item_sel then
            love.graphics.setColor(0.15, 0.35, 0.45, 0.85)
            love.graphics.rectangle("fill", px + 20, iy, pw - 40, 38, 6, 6)
            love.graphics.setColor(1, 0.85, 0.25)
            love.graphics.rectangle("line", px + 20, iy, pw - 40, 38, 6, 6)
            love.graphics.setColor(1, 0.95, 0.3)
        else
            love.graphics.setColor(0.06, 0.09, 0.15, 0.6)
            love.graphics.rectangle("fill", px + 20, iy, pw - 40, 38, 6, 6)
            love.graphics.setColor(0.75, 0.8, 0.9)
        end

        love.graphics.setFont(Fonts.get(11))
        love.graphics.print(string.format("[%d] %s", i, item.name), px + 32, iy + 4)

        love.graphics.setFont(Fonts.get(8))
        love.graphics.setColor(0.65, 0.75, 0.85, 0.85)
        love.graphics.print(item.subtitle or item.description, px + 32, iy + 21)
    end

    -- Description Box for selected item
    local selected_item = items[self.selected_item_idx]
    if selected_item then
        local dy = py + ph - 70
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", px + 20, dy, pw - 40, 38, 6, 6)
        love.graphics.setFont(Fonts.get(8))
        love.graphics.setColor(0.2, 0.9, 0.8)
        love.graphics.printf(selected_item.description, px + 26, dy + 4, pw - 52, "left")
        if selected_item.queue then
            love.graphics.setColor(1, 0.85, 0.3)
            love.graphics.printf("Next Queue: " .. table.concat(selected_item.queue, " "), px + 26, dy + 21, pw - 52, "left")
        end
    end

    -- Control instructions hint
    love.graphics.setFont(Fonts.get(8))
    love.graphics.setColor(0.55, 0.65, 0.75)
    love.graphics.printf("↑/↓ Select Item    ←/→ Switch Category    ENTER Load Setup    ESC Close",
        px, py + ph - 22, pw, "center")
end

return Zen
