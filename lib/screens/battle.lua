-- lib/screens/battle.lua
-- VS CPU split-screen battle screen

local Board      = require("lib.board")
local Piece      = require("lib.piece")
local Collision  = require("lib.collision")
local Randomizer = require("lib.randomizer")
local Scoring    = require("lib.scoring")
local Input      = require("lib.input")
local constants  = require("lib.constants")
local Themes     = require("lib.themes")
local Renderer   = require("lib.renderer")
local Effects    = require("lib.effects")
local Audio      = require("lib.audio")
local Save       = require("lib.save")
local flux       = require("lib.vendor.flux")
local CPUEngine  = require("lib.cpu_engine")
local GameplayOpts = require("lib.gameplay_opts")
local Fonts      = require("lib.fonts")

local Battle = {}

-- ─── Garbage table (lines sent per clear count) ───────────────────────────────
local GARBAGE_SENT = { [1] = 0, [2] = 1, [3] = 2, [4] = 4 }
local MAX_BATTLE_LEVEL = 8
local BOARD_MAX_LEVEL  = 8  -- gravity caps

-- ─── State ────────────────────────────────────────────────────────────────────

-- Player engine state
local P = {}   -- player state table (mirrors Gameplay fields)

Battle.cpu            = nil
Battle.difficulty     = "medium"
Battle.battle_level   = 1
Battle.total_lines    = 0
Battle.result         = nil   -- nil | "player_win" | "cpu_win"
Battle.result_timer   = 0
Battle.timer          = 0
Battle.alpha          = 0

-- Pending garbage queues (applied after next clear or timeout)
Battle.player_pending_garbage = 0
Battle.cpu_pending_garbage    = 0

-- Visual garbage arrows (center strip)
Battle.arrows = {}   -- {dir="right"|"left", count=n, life=1.0}

-- Layout (computed in enter)
Battle.cell      = 0
Battle.p_board_x = 0
Battle.p_board_y = 0
Battle.c_board_x = 0
Battle.c_board_y = 0
Battle.board_w   = 0
Battle.board_h   = 0
Battle.panel_w   = 0

-- ─── Player engine helpers ────────────────────────────────────────────────────

local function player_spawn()
    local ptype = table.remove(P.next_queue, 1)
    table.insert(P.next_queue, Randomizer.next(P.randomizer))
    P.hold_used = false
    P.current_piece = Piece.new(ptype, constants.BUFFER_ROWS + 1, 4)
    P.is_grounded  = false
    P.lock_timer   = 0
    P.lock_moves   = 0
    P.drop_timer   = 0

    if Collision.any_overlap(P.board, ptype, 0, P.current_piece.row, P.current_piece.col) then
        Battle.result       = "cpu_win"
        Battle.result_timer = 0
        Audio.play("game_over")
        Battle.save_result(false)
    end
end

local function player_lock()
    Board.place_piece(P.board, P.current_piece)
    P.pieces_placed = P.pieces_placed + 1

    -- Clear full lines
    local cleared = Board.clear_lines(P.board)
    P.lines_cleared = P.lines_cleared + cleared
    P.lines = P.lines + cleared
    P.score = P.score + Scoring.calculate(cleared, Battle.battle_level)

    -- Update shared battle level
    if cleared > 0 then
        Battle.total_lines = Battle.total_lines + cleared
        Battle.battle_level = math.min(MAX_BATTLE_LEVEL,
            math.floor(Battle.total_lines / 10) + 1)
        P.combo = P.combo + 1

        -- Garbage to send
        local sent = GARBAGE_SENT[cleared] or 0
        if P.back_to_back and cleared == 4 then sent = sent + 1 end
        P.back_to_back = (cleared == 4)
        if sent > 0 then
            Battle.cpu.pending_garbage = Battle.cpu.pending_garbage + sent
            table.insert(Battle.arrows, { dir = "right", count = sent, life = 1.2 })
            Audio.play("hard_drop")
        end

        -- Play line clear SFX
        local sfx_names = {"clear1","clear2","clear3","tetris"}
        Audio.play(sfx_names[math.min(cleared, 4)] or "clear1")

        Effects.shake_start(4 * cleared)
    else
        P.combo = 0
        P.back_to_back = false
    end

    -- Receive pending garbage
    if Battle.player_pending_garbage > 0 then
        player_apply_garbage(Battle.player_pending_garbage)
        Battle.player_pending_garbage = 0
    end

    P.current_piece = nil
    player_spawn()
end

function player_apply_garbage(n)
    for _ = 1, n do
        for r = constants.BUFFER_ROWS + 1, constants.TOTAL_ROWS - 1 do
            for c = 1, constants.GRID_COLS do
                Board.set_cell(P.board, r, c, Board.get_cell(P.board, r + 1, c))
            end
        end
        local hole = math.random(1, constants.GRID_COLS)
        for c = 1, constants.GRID_COLS do
            Board.set_cell(P.board, constants.TOTAL_ROWS, c, c ~= hole and "X" or nil)
        end
    end
end

-- ─── Save result ──────────────────────────────────────────────────────────────

function Battle.save_result(player_won)
    if player_won then
        local rec = Save.get("high_scores", "battle") or { wins = 0 }
        rec.wins = (rec.wins or 0) + 1
        Save.set("high_scores", "battle", rec)
        Save.save()
    end
end

-- ─── Layout calculation ───────────────────────────────────────────────────────

local function compute_layout()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    local top_bar  = 44
    local bot_bar  = 36
    local center_w = 60  -- center divider with arrows
    local panel_w  = 70  -- side panels (hold/next/score)
    local usable_w = (W - center_w) / 2 - panel_w * 2 - 12
    local usable_h = H - top_bar - bot_bar - 8

    local cell = math.floor(math.min(usable_w / constants.GRID_COLS,
                                     usable_h / constants.GRID_ROWS))
    Battle.cell    = cell
    Battle.board_w = cell * constants.GRID_COLS
    Battle.board_h = cell * constants.GRID_ROWS
    Battle.panel_w = panel_w

    -- Player board: left side
    Battle.p_board_x = math.floor(W / 2 - center_w / 2 - Battle.board_w - panel_w - 6)
    Battle.p_board_y = top_bar + math.floor((usable_h - Battle.board_h) / 2)

    -- CPU board: right side
    Battle.c_board_x = math.floor(W / 2 + center_w / 2 + panel_w + 6)
    Battle.c_board_y = Battle.p_board_y

    Battle.top_bar = top_bar
    Battle.bot_bar = bot_bar
    Battle.W = W
    Battle.H = H
    Battle.center_x = math.floor(W / 2 - center_w / 2)
    Battle.center_w = center_w
end

-- ─── Screen lifecycle ─────────────────────────────────────────────────────────

function Battle:enter(previous, difficulty)
    Battle.difficulty   = difficulty or Save.get("settings", "cpu_difficulty") or "medium"
    Battle.battle_level = 1
    Battle.total_lines  = 0
    Battle.result       = nil
    Battle.result_timer = 0
    Battle.timer        = 0
    Battle.alpha        = 0
    Battle.arrows       = {}
    Battle.player_pending_garbage = 0

    compute_layout()
    Effects.clear()
    GameplayOpts.load()

    -- Init player state
    P.board         = Board.new()
    P.randomizer    = Randomizer.new()
    P.next_queue    = {}
    P.hold          = nil
    P.hold_used     = false
    P.score         = 0
    P.lines         = 0
    P.lines_cleared = 0
    P.combo         = 0
    P.back_to_back  = false
    P.drop_timer    = 0
    P.lock_timer    = 0
    P.lock_moves    = 0
    P.is_grounded   = false
    P.soft_drop     = false
    P.pieces_placed = 0
    P.current_piece = nil

    for _ = 1, 5 do
        table.insert(P.next_queue, Randomizer.next(P.randomizer))
    end
    player_spawn()

    -- Init CPU
    Battle.cpu = CPUEngine.new(Battle.difficulty)
    Battle.cpu.on_line_clear = function(cleared)
        -- CPU cleared lines → send garbage to player
        Battle.total_lines = Battle.total_lines + cleared
        Battle.battle_level = math.min(MAX_BATTLE_LEVEL,
            math.floor(Battle.total_lines / 10) + 1)

        local sent = GARBAGE_SENT[cleared] or 0
        if sent > 0 then
            Battle.player_pending_garbage = Battle.player_pending_garbage + sent
            table.insert(Battle.arrows, { dir = "left", count = sent, life = 1.2 })
        end
    end
    Battle.cpu.on_game_over = function()
        if not Battle.result then
            Battle.result = "player_win"
            Battle.result_timer = 0
            Audio.play("victory")
            Battle.save_result(true)
        end
    end

    flux.to(Battle, 0.3, { alpha = 1 }):ease("quadout")
end

function Battle:update(dt)
    flux.update(dt)
    Effects.update(dt)
    Battle.timer = Battle.timer + dt

    -- Update garbage arrow lifetimes
    for i = #Battle.arrows, 1, -1 do
        Battle.arrows[i].life = Battle.arrows[i].life - dt
        if Battle.arrows[i].life <= 0 then table.remove(Battle.arrows, i) end
    end

    if Battle.result then
        Battle.result_timer = Battle.result_timer + dt
        return
    end

    if not P.current_piece then return end

    -- ── Player input ──────────────────────────────────────────────────────────
    local fired = Input.update(dt)
    for _, action in ipairs(fired) do
        if action == "MOVE_LEFT" then
            if Collision.can_move(P.board, P.current_piece, -1, 0) then
                P.current_piece.col = P.current_piece.col - 1
                P.lock_moves = P.lock_moves + 1
                Audio.play("move")
            end
        elseif action == "MOVE_RIGHT" then
            if Collision.can_move(P.board, P.current_piece, 1, 0) then
                P.current_piece.col = P.current_piece.col + 1
                P.lock_moves = P.lock_moves + 1
                Audio.play("move")
            end
        end
    end

    -- ── Player gravity ────────────────────────────────────────────────────────
    P.drop_timer = P.drop_timer + dt
    local drop_interval = Scoring.drop_interval(Battle.battle_level)
    local effective_interval = P.soft_drop and constants.SOFT_DROP_INTERVAL or drop_interval

    if P.drop_timer >= effective_interval then
        P.drop_timer = 0
        if not Collision.is_grounded(P.board, P.current_piece) then
            P.current_piece.row = P.current_piece.row + 1
            P.is_grounded = false
        else
            P.is_grounded = true
        end
    end

    -- ── Player lock delay ─────────────────────────────────────────────────────
    if Collision.is_grounded(P.board, P.current_piece) then
        P.is_grounded = true
        P.lock_timer = P.lock_timer + dt
        local lock_delay = constants.LOCK_DELAY
        if P.lock_timer >= lock_delay or P.lock_moves >= constants.LOCK_MOVES_MAX then
            player_lock()
        end
    else
        P.is_grounded = false
        if P.lock_moves < constants.LOCK_MOVES_MAX then P.lock_timer = 0 end
    end

    -- ── CPU update ────────────────────────────────────────────────────────────
    Battle.cpu:update(dt, Battle.battle_level)
end

-- ─── Drawing ──────────────────────────────────────────────────────────────────

local function rr(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r or 6, r or 6)
end

local function draw_board_grid(bx, by, cell, theme)
    -- Background
    love.graphics.setColor(theme.background[1] * 0.5,
                           theme.background[2] * 0.5,
                           theme.background[3] * 0.5, 0.95)
    rr(bx, by, cell * constants.GRID_COLS, cell * constants.GRID_ROWS, 4)

    -- Grid lines
    local gc = theme.grid_color or {0.2, 0.2, 0.3}
    love.graphics.setColor(gc[1], gc[2], gc[3], 0.25)
    for c = 0, constants.GRID_COLS do
        love.graphics.rectangle("fill", bx + c * cell, by, 1, cell * constants.GRID_ROWS)
    end
    for r = 0, constants.GRID_ROWS do
        love.graphics.rectangle("fill", bx, by + r * cell, cell * constants.GRID_COLS, 1)
    end
end

local function draw_placed_cells(board, bx, by, cell, theme)
    for r = constants.BUFFER_ROWS + 1, constants.TOTAL_ROWS do
        for c = 1, constants.GRID_COLS do
            local ptype = Board.get_cell(board, r, c)
            if ptype then
                local draw_r = r - constants.BUFFER_ROWS
                local px = bx + (c - 1) * cell
                local py = by + (draw_r - 1) * cell
                if ptype == "X" then
                    -- Garbage row style
                    love.graphics.setColor(0.35, 0.35, 0.38)
                    love.graphics.rectangle("fill", px + 1, py + 1, cell - 2, cell - 2, 2)
                    love.graphics.setColor(0.55, 0.55, 0.58)
                    love.graphics.rectangle("fill", px + 1, py + 1, cell - 2, 3)
                else
                    local color = theme.colors[ptype]
                    if color then
                        Renderer.draw_block(px, py, cell, color, theme.block_style)
                    end
                end
            end
        end
    end
end

local function draw_active_piece(piece, bx, by, cell, theme, is_player)
    if not piece then return end
    local board_for_ghost = is_player and P.board or Battle.cpu.board

    -- Ghost (only for player, and only when ghost_enabled)
    if is_player and GameplayOpts.ghost_enabled then
        local ghost_row = piece.row
        while not Collision.any_overlap(board_for_ghost, piece.type, piece.rotation, ghost_row + 1, piece.col) do
            ghost_row = ghost_row + 1
        end
        local gcells = Piece.get_abs_cells(piece.type, piece.rotation, ghost_row, piece.col)
        local color = theme.colors[piece.type]
        for _, cell_pos in ipairs(gcells) do
            local r, c2 = cell_pos[1], cell_pos[2]
            if r > constants.BUFFER_ROWS then
                local draw_r = r - constants.BUFFER_ROWS
                local px = bx + (c2 - 1) * cell
                local py = by + (draw_r - 1) * cell
                if color then
                    love.graphics.setColor(color[1]/255, color[2]/255, color[3]/255, 0.18)
                    love.graphics.rectangle("fill", px + 1, py + 1, cell - 2, cell - 2, 2)
                end
            end
        end
    end

    -- Active piece cells
    local cells = Piece.get_abs_cells(piece.type, piece.rotation, piece.row, piece.col)
    local color = theme.colors[piece.type]
    for _, cell_pos in ipairs(cells) do
        local r, c2 = cell_pos[1], cell_pos[2]
        if r > constants.BUFFER_ROWS then
            local draw_r = r - constants.BUFFER_ROWS
            local px = bx + (c2 - 1) * cell
            local py = by + (draw_r - 1) * cell
            if color then
                Renderer.draw_block(px, py, cell, color, theme.block_style)
            end
        end
    end
end

local function draw_mini_queue(queue, hold, hold_used, x, y, cell, theme, label_left)
    local mini = math.floor(cell * 0.55)
    local panel_w = Battle.panel_w

    love.graphics.setColor(0, 0, 0, 0.5)
    rr(x, y, panel_w, Battle.board_h, 6)

    local font_sm = Fonts.get(9)
    love.graphics.setFont(font_sm)

    -- HOLD
    local hold_y = y + 8
    love.graphics.setColor(0.50, 0.55, 0.65, 0.85)
    love.graphics.printf("HOLD", x, hold_y, panel_w, "center")
    hold_y = hold_y + 14
    love.graphics.setColor(0.12, 0.14, 0.22, 0.8)
    rr(x + 6, hold_y, panel_w - 12, mini * 3 + 4, 4)
    if hold then
        local alpha = hold_used and 0.35 or 1.0
        love.graphics.setColor(1, 1, 1, alpha)
        Renderer.draw_mini_piece(hold, x + 8, hold_y + 2, mini, theme)
    end

    -- NEXT
    local next_y = hold_y + mini * 3 + 14
    love.graphics.setColor(0.50, 0.55, 0.65, 0.85)
    love.graphics.printf("NEXT", x, next_y, panel_w, "center")
    next_y = next_y + 14
    for i = 1, math.min(4, #queue) do
        love.graphics.setColor(0.10, 0.12, 0.20, 0.7)
        rr(x + 6, next_y, panel_w - 12, mini * 3, 4)
        love.graphics.setColor(1, 1, 1)
        Renderer.draw_mini_piece(queue[i], x + 8, next_y + 2, mini, theme)
        next_y = next_y + mini * 3 + 4
    end
end

local function draw_stats_panel(score, lines, level, x, y, w, theme)
    love.graphics.setColor(0, 0, 0, 0.5)
    rr(x, y, w, 90, 6)

    local function stat(label, val, sy)
        love.graphics.setFont(Fonts.get(8))
        love.graphics.setColor(0.50, 0.60, 0.75)
        love.graphics.printf(label, x, sy, w, "center")
        love.graphics.setFont(Fonts.get(13))
        love.graphics.setColor(1, 0.90, 0.25)
        love.graphics.printf(tostring(val), x, sy + 11, w, "center")
    end

    stat("SCORE", score,  y + 4)
    stat("LINES", lines,  y + 34)
    stat("LEVEL", level,  y + 64)
end

local function draw_garbage_arrows(cx, cy, ch, arrows)
    local cw = Battle.center_w
    -- Background strip
    love.graphics.setColor(0.04, 0.05, 0.10, 0.8)
    rr(cx, cy, cw, ch)
    love.graphics.setColor(0.10, 0.15, 0.30, 0.5)
    love.graphics.rectangle("fill", cx + cw/2 - 1, cy, 2, ch)

    love.graphics.setFont(Fonts.get(13))
    for _, arr in ipairs(arrows) do
        local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
        if arr.dir == "right" then
            -- Player sent → CPU (arrows point right)
            love.graphics.setColor(0.20, 1.0, 0.40, arr.life * pulse)
            local ay = cy + ch * 0.35
            for i = 1, arr.count do
                love.graphics.printf("▶", cx + 4, ay + (i-1)*18, cw/2 - 6, "right")
            end
        else
            -- CPU sent → Player (arrows point left)
            love.graphics.setColor(1.0, 0.30, 0.20, arr.life * pulse)
            local ay = cy + ch * 0.55
            for i = 1, arr.count do
                love.graphics.printf("◀", cx + cw/2 + 4, ay + (i-1)*18, cw/2 - 6, "left")
            end
        end
    end

    -- Pending garbage indicators (static)
    if Battle.player_pending_garbage > 0 then
        love.graphics.setColor(1, 0.3, 0.1, 0.85)
        love.graphics.setFont(Fonts.get(10))
        love.graphics.printf("⚠ +" .. Battle.player_pending_garbage,
            cx, cy + ch - 30, cw, "center")
    end
end

local function draw_result_overlay(W, H)
    if not Battle.result then return end

    local t = math.min(1.0, Battle.result_timer / 0.4)
    love.graphics.setColor(0, 0, 0, t * 0.72)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local is_win = (Battle.result == "player_win")
    if is_win then
        love.graphics.setColor(0.15, 1.0, 0.50, t)
    else
        love.graphics.setColor(1.0, 0.20, 0.20, t)
    end

    love.graphics.setFont(Fonts.get(52))
    love.graphics.printf(is_win and "YOU WIN!" or "YOU LOSE", 0, H * 0.32, W, "center")

    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(1, 1, 1, t * 0.85)
    local subtitle = is_win
        and string.format("Score: %d   Lines: %d", P.score, P.lines)
        or  string.format("CPU Score: %d   CPU Lines: %d", Battle.cpu.score, Battle.cpu.lines)
    love.graphics.printf(subtitle, 0, H * 0.50, W, "center")

    if Battle.result_timer > 1.5 then
        local blink = math.sin(Battle.result_timer * 4) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, blink)
        love.graphics.setFont(Fonts.get(14))
        love.graphics.printf("ENTER — Play Again    ESC — Menu", 0, H * 0.62, W, "center")
    end
end

function Battle:draw()
    local theme = Themes.get_board_theme()
    local W, H  = Battle.W or love.graphics.getWidth(), Battle.H or love.graphics.getHeight()
    local a     = Battle.alpha
    local cell  = Battle.cell
    local bw    = Battle.board_w
    local bh    = Battle.board_h
    local pw    = Battle.panel_w
    local pbx, pby = Battle.p_board_x, Battle.p_board_y
    local cbx, cby = Battle.c_board_x, Battle.c_board_y

    -- Background
    love.graphics.clear(0.02, 0.04, 0.10)

    -- Subtle dot grid
    love.graphics.setColor(0.15, 0.28, 0.65, a * 0.12)
    for gx = 0, W, 22 do
        for gy = 0, H, 22 do
            love.graphics.circle("fill", gx, gy, 1.2)
        end
    end

    -- ── Top bar ───────────────────────────────────────────────────────────────
    local tb = Battle.top_bar
    love.graphics.setColor(0.04, 0.06, 0.14, a * 0.97)
    love.graphics.rectangle("fill", 0, 0, W, tb)
    love.graphics.setColor(0.12, 0.20, 0.40, a * 0.7)
    love.graphics.rectangle("fill", 0, tb - 2, W, 2)

    -- Title
    love.graphics.setFont(Fonts.get(18))
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.printf("VS CPU", 0, 12, W, "center")

    -- Difficulty badge
    local diff_colors = {
        easy = {0.20, 0.80, 0.30},
        medium = {1.0, 0.75, 0.10},
        hard = {1.0, 0.35, 0.10},
        boss = {0.85, 0.10, 0.85},
    }
    local dc = diff_colors[Battle.difficulty] or {1,1,1}
    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(dc[1], dc[2], dc[3], a * 0.9)
    local diff_labels = {easy="EASY", medium="MEDIUM", hard="HARD", boss="BOSS ★"}
    love.graphics.printf(diff_labels[Battle.difficulty] or "?", W - 100, 14, 90, "right")

    -- Battle level + timer
    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(0.55, 0.65, 0.80, a * 0.8)
    local mins = math.floor(Battle.timer / 60)
    local secs = Battle.timer % 60
    love.graphics.printf(string.format("Lv.%d  %02d:%04.1f", Battle.battle_level, mins, secs),
        10, 14, W * 0.3, "left")

    -- ── Player side ───────────────────────────────────────────────────────────
    -- Label
    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(0.40, 0.80, 1.0, a * 0.9)
    love.graphics.printf("PLAYER", pbx - pw, pby - 20, bw + pw * 2, "center")

    -- Hold/Next panel (left of player board)
    draw_mini_queue(P.next_queue, P.hold, P.hold_used,
        pbx - pw - 4, pby, cell, theme, true)

    -- Board
    draw_board_grid(pbx, pby, cell, theme)
    draw_placed_cells(P.board, pbx, pby, cell, theme)
    if P.current_piece and not Battle.result then
        draw_active_piece(P.current_piece, pbx, pby, cell, theme, true)
    end

    -- Board border
    love.graphics.setColor(0.25, 0.60, 1.0, a * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", pbx, pby, bw, bh, 4)
    love.graphics.setLineWidth(1)

    -- Stats panel (right of player board, left of center)
    draw_stats_panel(P.score, P.lines, Battle.battle_level,
        pbx + bw + 4, pby, pw, theme)

    -- ── Center strip (garbage arrows) ─────────────────────────────────────────
    draw_garbage_arrows(Battle.center_x, pby, bh, Battle.arrows)

    -- ── CPU side ──────────────────────────────────────────────────────────────
    love.graphics.setFont(Fonts.get(12))
    local cpu_diff_labels = {easy="CPU [Easy]", medium="CPU [Medium]",
                              hard="CPU [Hard]", boss="CPU [BOSS]"}
    love.graphics.setColor(1.0, 0.40, 0.40, a * 0.9)
    love.graphics.printf(cpu_diff_labels[Battle.difficulty] or "CPU",
        cbx - pw, cby - 20, bw + pw * 2, "center")

    -- Stats left of CPU board
    draw_stats_panel(Battle.cpu.score, Battle.cpu.lines, Battle.battle_level,
        cbx - pw - 4, cby, pw, theme)

    -- CPU Board
    draw_board_grid(cbx, cby, cell, theme)
    draw_placed_cells(Battle.cpu.board, cbx, cby, cell, theme)

    -- CPU active piece
    if Battle.cpu.current_piece and not Battle.result then
        draw_active_piece(Battle.cpu.current_piece, cbx, cby, cell, theme, false)
    end

    -- CPU board border
    love.graphics.setColor(1.0, 0.35, 0.35, a * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", cbx, cby, bw, bh, 4)
    love.graphics.setLineWidth(1)

    -- CPU next queue (right of CPU board)
    draw_mini_queue(Battle.cpu.next_queue, Battle.cpu.hold, Battle.cpu.hold_used,
        cbx + bw + 4, cby, cell, theme, false)

    -- ── Bottom bar ────────────────────────────────────────────────────────────
    local by2 = H - Battle.bot_bar
    love.graphics.setColor(0.04, 0.06, 0.14, a * 0.9)
    love.graphics.rectangle("fill", 0, by2, W, Battle.bot_bar)
    love.graphics.setColor(0.12, 0.20, 0.40, a * 0.6)
    love.graphics.rectangle("fill", 0, by2, W, 2)
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.40, 0.45, 0.58, a * 0.7)
    love.graphics.printf("← → Move    Z Rotate CCW    X/Up Rotate CW    Shift Hold    Down Soft Drop    Space Hard Drop    ESC Forfeit",
        0, by2 + 10, W, "center")

    -- ── Result overlay ────────────────────────────────────────────────────────
    draw_result_overlay(W, H)
end

-- ─── Input ────────────────────────────────────────────────────────────────────

function Battle:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if Battle.result and Battle.result_timer > 1.5 then
        if key == "return" then
            -- Replay with same difficulty
            state_mgr.switch("battle", Battle.difficulty)
        elseif key == "escape" then
            state_mgr.pop()
        end
        return
    end

    if key == "escape" then
        state_mgr.pop()
        return
    end

    if Battle.result or not P.current_piece then return end

    local p  = P.current_piece

    if key == "left" then
        if Collision.can_move(P.board, p, -1, 0) then
            p.col = p.col - 1
            P.lock_moves = P.lock_moves + 1
            Audio.play("move")
        end
    elseif key == "right" then
        if Collision.can_move(P.board, p, 1, 0) then
            p.col = p.col + 1
            P.lock_moves = P.lock_moves + 1
            Audio.play("move")
        end
    elseif key == "down" then
        P.soft_drop = true
    elseif key == "z" then
        if Piece.try_rotate(P.board, p, -1) then
            P.lock_moves = P.lock_moves + 1
            Audio.play("rotate")
        end
    elseif key == "x" or key == "up" then
        if Piece.try_rotate(P.board, p, 1) then
            P.lock_moves = P.lock_moves + 1
            Audio.play("rotate")
        end
    elseif key == "space" then
        -- Hard drop
        while not Collision.any_overlap(P.board, p.type, p.rotation, p.row + 1, p.col) do
            p.row = p.row + 1
        end
        player_lock()
        Audio.play("hard_drop")
    elseif key == "lshift" or key == "rshift" or key == "c" then
        -- Hold
        if GameplayOpts.hold_enabled and not P.hold_used then
            local prev_hold = P.hold
            P.hold = p.type
            P.hold_used = true
            P.current_piece = nil
            if prev_hold then
                P.current_piece = Piece.new(prev_hold, constants.BUFFER_ROWS + 1, 4)
                P.drop_timer = 0
                P.lock_timer = 0
            else
                player_spawn()
            end
            Audio.play("hold")
        end
    end
end

function Battle:keyreleased(key)
    if key == "down" then
        P.soft_drop = false
    end
end

return Battle
