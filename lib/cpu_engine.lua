-- lib/cpu_engine.lua
-- Self-contained CPU Tetris engine with heuristic AI
-- Runs as a separate board/piece state used by lib/screens/battle.lua

local Board      = require("lib.board")
local Piece      = require("lib.piece")
local Collision  = require("lib.collision")
local Randomizer = require("lib.randomizer")
local Scoring    = require("lib.scoring")
local constants  = require("lib.constants")

local CPUEngine = {}
CPUEngine.__index = CPUEngine

-- ─── AI weights per difficulty ────────────────────────────────────────────────
local WEIGHTS = {
    easy   = { lines = 3.5, height = -0.5, holes = -4.5, bumps = -0.2 },
    medium = { lines = 3.5, height = -0.6, holes = -6.0, bumps = -0.4 },
    hard   = { lines = 3.8, height = -0.7, holes = -7.5, bumps = -0.5 },
    boss   = { lines = 4.0, height = -0.8, holes = -9.0, bumps = -0.6 },
}

local THINK_INTERVALS = {
    easy = 0.6, medium = 0.35, hard = 0.18, boss = 0.08,
}

local ERROR_RATES = {
    easy = 0.25, medium = 0.10, hard = 0.03, boss = 0.00,
}

local LOOKAHEAD = {
    easy = false, medium = false, hard = true, boss = true,
}

-- ─── Board analysis helpers ───────────────────────────────────────────────────

-- Returns column heights (topmost filled row per column, measured from bottom)
local function get_col_heights(board)
    local heights = {}
    for c = 1, constants.GRID_COLS do
        local h = 0
        for r = constants.BUFFER_ROWS + 1, constants.TOTAL_ROWS do
            if Board.get_cell(board, r, c) then
                h = constants.TOTAL_ROWS - r + 1
                break
            end
        end
        heights[c] = h
    end
    return heights
end

local function aggregate_height(heights)
    local sum = 0
    for _, h in ipairs(heights) do sum = sum + h end
    return sum
end

local function count_holes(board, heights)
    local holes = 0
    for c = 1, constants.GRID_COLS do
        local top_row = constants.TOTAL_ROWS - heights[c] + 1
        for r = top_row + 1, constants.TOTAL_ROWS do
            if not Board.get_cell(board, r, c) then
                holes = holes + 1
            end
        end
    end
    return holes
end

local function bumpiness(heights)
    local sum = 0
    for c = 1, constants.GRID_COLS - 1 do
        sum = sum + math.abs(heights[c] - heights[c + 1])
    end
    return sum
end

-- ─── Find landing row for a piece at given col and rotation ──────────────────

local function find_landing_row(board, ptype, rot, start_col)
    local row = constants.BUFFER_ROWS + 1  -- start just above visible
    while true do
        local next_row = row + 1
        if Collision.any_overlap(board, ptype, rot, next_row, start_col) then
            break
        end
        row = next_row
    end
    return row
end

-- Place piece on scratch board and clear lines; returns lines_cleared
local function simulate_placement(scratch_board, ptype, rot, row, col)
    -- Place piece cells
    local cells = Piece.get_abs_cells(ptype, rot, row, col)
    for _, cell in ipairs(cells) do
        local r, c = cell[1], cell[2]
        if Board.in_bounds(r, c) then
            Board.set_cell(scratch_board, r, c, ptype)
        end
    end
    -- Count and clear full lines
    local cleared = 0
    for r = constants.TOTAL_ROWS, constants.BUFFER_ROWS + 1, -1 do
        local full = true
        for c = 1, constants.GRID_COLS do
            if not Board.get_cell(scratch_board, r, c) then
                full = false; break
            end
        end
        if full then
            cleared = cleared + 1
            for y = r, constants.BUFFER_ROWS + 2, -1 do
                for x = 1, constants.GRID_COLS do
                    Board.set_cell(scratch_board, y, x, Board.get_cell(scratch_board, y - 1, x))
                end
            end
            for x = 1, constants.GRID_COLS do
                Board.set_cell(scratch_board, constants.BUFFER_ROWS + 1, x, nil)
            end
        end
    end
    return cleared
end

-- ─── Evaluate a board state ───────────────────────────────────────────────────

local function evaluate(board, weights, lines_cleared)
    local heights = get_col_heights(board)
    local agg     = aggregate_height(heights)
    local holes   = count_holes(board, heights)
    local bumps   = bumpiness(heights)
    return weights.lines * lines_cleared
         + weights.height * agg
         + weights.holes  * holes
         + weights.bumps  * bumps
end

-- ─── Find best placement for a piece type ────────────────────────────────────

local function best_placement(board, ptype, weights, error_rate, lookahead_ptype)
    local best_score = -math.huge
    local best_rot, best_col = 0, 1

    for rot = 0, 3 do
        for col = 1, constants.GRID_COLS do
            -- Check piece fits at top in this rotation/col
            if not Collision.any_overlap(board, ptype, rot, constants.BUFFER_ROWS + 1, col) then
                local row = find_landing_row(board, ptype, rot, col)
                -- Only consider placements within visible area
                if row >= constants.BUFFER_ROWS + 1 then
                    local scratch = Board.deep_copy(board)
                    local cleared = simulate_placement(scratch, ptype, rot, row, col)
                    local score

                    if lookahead_ptype then
                        -- 2-ply: evaluate with next piece too
                        local next_best = -math.huge
                        for r2 = 0, 3 do
                            for c2 = 1, constants.GRID_COLS do
                                if not Collision.any_overlap(scratch, lookahead_ptype, r2, constants.BUFFER_ROWS + 1, c2) then
                                    local row2 = find_landing_row(scratch, lookahead_ptype, r2, c2)
                                    if row2 >= constants.BUFFER_ROWS + 1 then
                                        local scratch2 = Board.deep_copy(scratch)
                                        local cleared2 = simulate_placement(scratch2, lookahead_ptype, r2, row2, c2)
                                        local s2 = evaluate(scratch2, weights, cleared + cleared2)
                                        if s2 > next_best then next_best = s2 end
                                    end
                                end
                            end
                        end
                        score = next_best
                    else
                        score = evaluate(scratch, weights, cleared)
                    end

                    if score > best_score then
                        best_score = score
                        best_rot = rot
                        best_col = col
                    end
                end
            end
        end
    end

    -- Apply error rate: occasionally pick random valid placement
    if error_rate > 0 and math.random() < error_rate then
        local valid = {}
        for rot = 0, 3 do
            for col = 1, constants.GRID_COLS do
                if not Collision.any_overlap(board, ptype, rot, constants.BUFFER_ROWS + 1, col) then
                    table.insert(valid, {rot = rot, col = col})
                end
            end
        end
        if #valid > 0 then
            local pick = valid[math.random(#valid)]
            best_rot, best_col = pick.rot, pick.col
        end
    end

    return best_rot, best_col
end

-- ─── CPUEngine constructor ────────────────────────────────────────────────────

function CPUEngine.new(difficulty)
    local self = setmetatable({}, CPUEngine)
    self.difficulty    = difficulty or "medium"
    self.weights       = WEIGHTS[self.difficulty]
    self.think_interval = THINK_INTERVALS[self.difficulty]
    self.error_rate    = ERROR_RATES[self.difficulty]
    self.use_lookahead = LOOKAHEAD[self.difficulty]

    -- Board state
    self.board         = Board.new()
    self.randomizer    = Randomizer.new()
    self.next_queue    = {}
    self.hold          = nil
    self.hold_used     = false
    self.current_piece = nil

    -- Engine state
    self.drop_timer    = 0
    self.lock_timer    = 0
    self.is_grounded   = false
    self.score         = 0
    self.lines         = 0
    self.level         = 1     -- set externally by battle.lua (shared battle_level)
    self.game_over     = false
    self.pieces_placed = 0
    self.lines_cleared = 0
    self.combo         = 0

    -- AI planned move: target {rot, col} and move sequence
    self.think_timer   = 0
    self.target_rot    = 0
    self.target_col    = 5
    self.plan_done     = false

    -- Garbage queued (rows to add from bottom)
    self.pending_garbage = 0

    -- Callbacks (set by battle.lua)
    self.on_line_clear = nil   -- function(lines_cleared) — notifies battle to send garbage
    self.on_game_over  = nil   -- function() — notifies battle the CPU topped out

    -- Fill initial queue
    for _ = 1, 5 do
        table.insert(self.next_queue, Randomizer.next(self.randomizer))
    end

    self:spawn_piece()
    return self
end

function CPUEngine:pop_queue()
    local ptype = table.remove(self.next_queue, 1)
    table.insert(self.next_queue, Randomizer.next(self.randomizer))
    self.hold_used = false
    return ptype
end

function CPUEngine:spawn_piece()
    local ptype = self:pop_queue()
    self.current_piece = Piece.new(ptype, constants.BUFFER_ROWS + 1, 4)
    self.is_grounded   = false
    self.lock_timer    = 0
    self.drop_timer    = 0
    self.plan_done     = false

    -- Check top-out
    if Collision.any_overlap(self.board, ptype, 0,
                             self.current_piece.row, self.current_piece.col) then
        self.game_over = true
        if self.on_game_over then self.on_game_over() end
    end
end

function CPUEngine:plan_move()
    if not self.current_piece then return end
    local ptype = self.current_piece.type
    local next_ptype = self.use_lookahead and self.next_queue[1] or nil
    local target_rot, target_col = best_placement(
        self.board, ptype, self.weights, self.error_rate, next_ptype)
    self.target_rot = target_rot
    self.target_col = target_col
    self.plan_done  = true
end

function CPUEngine:execute_one_move()
    if not self.current_piece then return end
    local p = self.current_piece

    -- Rotate toward target
    if p.rotation ~= self.target_rot then
        local new_rot = (p.rotation + 1) % 4
        if not Collision.any_overlap(self.board, p.type, new_rot, p.row, p.col) then
            p.rotation = new_rot
        end
        return
    end

    -- Translate toward target column
    if p.col < self.target_col then
        if not Collision.any_overlap(self.board, p.type, p.rotation, p.row, p.col + 1) then
            p.col = p.col + 1
        else
            -- Blocked; drop down a bit and retry
            if not Collision.any_overlap(self.board, p.type, p.rotation, p.row + 1, p.col) then
                p.row = p.row + 1
            end
        end
        return
    elseif p.col > self.target_col then
        if not Collision.any_overlap(self.board, p.type, p.rotation, p.row, p.col - 1) then
            p.col = p.col - 1
        else
            if not Collision.any_overlap(self.board, p.type, p.rotation, p.row + 1, p.col) then
                p.row = p.row + 1
            end
        end
        return
    end

    -- Reached target col+rot → hard drop
    while not Collision.any_overlap(self.board, p.type, p.rotation, p.row + 1, p.col) do
        p.row = p.row + 1
    end
    self:lock_piece()
end

function CPUEngine:lock_piece()
    if not self.current_piece then return end
    local p = self.current_piece

    Board.place_piece(self.board, p)
    self.pieces_placed = self.pieces_placed + 1

    -- Count and clear full lines
    local cleared = Board.clear_lines(self.board)
    self.lines_cleared = self.lines_cleared + cleared
    self.lines         = self.lines + cleared
    self.score         = self.score + Scoring.calculate(cleared, self.level)

    if cleared > 0 then
        self.combo = self.combo + 1
        if self.on_line_clear then
            self.on_line_clear(cleared)
        end
    else
        self.combo = 0
    end

    -- Apply pending garbage AFTER clearing (so you can combo out of garbage)
    if self.pending_garbage > 0 then
        self:apply_garbage(self.pending_garbage)
        self.pending_garbage = 0
    end

    self.current_piece = nil
    self.plan_done = false
    self:spawn_piece()
end

function CPUEngine:receive_garbage(lines)
    self.pending_garbage = self.pending_garbage + lines
end

function CPUEngine:apply_garbage(n)
    -- Shift board up by n rows
    for _ = 1, n do
        -- Move all rows up 1
        for r = constants.BUFFER_ROWS + 1, constants.TOTAL_ROWS - 1 do
            for c = 1, constants.GRID_COLS do
                Board.set_cell(self.board, r, c, Board.get_cell(self.board, r + 1, c))
            end
        end
        -- Add garbage row at bottom with one random hole
        local hole = math.random(1, constants.GRID_COLS)
        for c = 1, constants.GRID_COLS do
            Board.set_cell(self.board, constants.TOTAL_ROWS, c, c ~= hole and "X" or nil)
        end
    end
end

function CPUEngine:update(dt, battle_level)
    if self.game_over or not self.current_piece then return end

    -- Use shared battle level for gravity
    self.level = battle_level or self.level

    -- Plan move once per piece
    if not self.plan_done then
        self:plan_move()
    end

    -- Execute one AI move per think_interval
    self.think_timer = self.think_timer + dt
    if self.think_timer >= self.think_interval then
        self.think_timer = 0
        self:execute_one_move()
    end

    -- Natural gravity (same as player, uses battle_level)
    self.drop_timer = self.drop_timer + dt
    local drop_interval = Scoring.drop_interval(battle_level or 1)
    if self.drop_timer >= drop_interval then
        self.drop_timer = 0
        local p = self.current_piece
        if not Collision.is_grounded(self.board, p) then
            p.row = p.row + 1
            self.is_grounded = false
        else
            self.is_grounded = true
        end
    end

    -- Lock delay
    if self.is_grounded then
        self.lock_timer = self.lock_timer + dt
        if self.lock_timer >= constants.LOCK_DELAY then
            self:lock_piece()
        end
    end
end

return CPUEngine
