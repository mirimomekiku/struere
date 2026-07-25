local Board = require("lib.board")
local Piece = require("lib.piece")
local Collision = require("lib.collision")
local Randomizer = require("lib.randomizer")
local Scoring = require("lib.scoring")
local Input = require("lib.input")
local constants = require("lib.constants")
local Themes = require("lib.themes")
local Renderer = require("lib.renderer")
local Effects = require("lib.effects")
local Queue = require("lib.queue")
local Menu = require("lib.menu")
local Audio = require("lib.audio")
local Save = require("lib.save")
local tick = require("lib.vendor.tick")
local flux = require("lib.vendor.flux")
local hermes = require("lib.vendor.hermes")
local GameplayOpts = require("lib.gameplay_opts")
local Fonts = require("lib.fonts")
local Countdown = require("lib.countdown")

local Gameplay = {}

Gameplay.board = nil
Gameplay.current_piece = nil
Gameplay.randomizer = nil
Gameplay.score = 0
Gameplay.displayed_score = 0
Gameplay.lines = 0
Gameplay.level = 1
Gameplay.drop_timer = 0
Gameplay.lock_timer = 0
Gameplay.lock_moves = 0
Gameplay.is_grounded = false
Gameplay.game_over = false
Gameplay.victory = false
Gameplay.soft_drop_active = false
Gameplay.mode = nil
Gameplay.theme_name = "Retro Arcade"
Gameplay.countdown = nil

function Gameplay.spawn_piece(piece_type)
    local ptype = piece_type or Queue.pop(Gameplay.randomizer)
    Gameplay.current_piece = Piece.new(ptype, 21, 4)
    Gameplay.last_was_rotation = false
    Gameplay.last_kick_idx = 0

    if Collision.any_overlap(Gameplay.board, Gameplay.current_piece.type,
                             Gameplay.current_piece.rotation,
                             Gameplay.current_piece.row, Gameplay.current_piece.col) then
        Gameplay.game_over = true
        Gameplay.game_over_sel = 1
        if Gameplay.mode then Gameplay.mode:onGameOver(Gameplay) end
        Audio.play("game_over")
        Effects.set_danger_level(0)
        Gameplay.saveScore()
        Save.clearActiveRun()
    end
    Gameplay.is_grounded = false
    Gameplay.lock_timer = 0
    Gameplay.lock_moves = 0
    Gameplay.drop_timer = 0
end

function Gameplay.lock_piece()
    local t_spin_type = Piece.get_t_spin_status(Gameplay.board, Gameplay.current_piece, Gameplay.last_was_rotation, Gameplay.last_kick_idx)

    -- Save undo snapshot before locking
    if Gameplay.mode and Gameplay.mode.beforeLock then
        Gameplay.mode:beforeLock(Gameplay)
    end
    Board.place_piece(Gameplay.board, Gameplay.current_piece)
    Gameplay.last_was_rotation = false
    Gameplay.last_kick_idx = 0

    local clear_rows = {}
    for r = 21, 40 do
        local full = true
        for c = 1, constants.GRID_COLS do
            if not Board.get_cell(Gameplay.board, r, c) then
                full = false
                break
            end
        end
        if full then
            table.insert(clear_rows, r)
        end
    end

    local cleared = #clear_rows

    if cleared > 0 then
        local theme = Themes.get_board_theme()
        hermes:emit("line_clear", cleared, clear_rows)
        for _, row in ipairs(clear_rows) do
            local bx = constants.BOARD_X + 5 * constants.CELL_SIZE
            local by = constants.BOARD_Y + (row - 21) * constants.CELL_SIZE
            local color = theme.colors[Gameplay.current_piece.type] or {255, 255, 255}
            Effects.particles_spawn(bx, by, color, constants.PARTICLE_COUNT)
        end
        Effects.spawn_line_clear_upward_particles(constants.BOARD_X, constants.BOARD_Y, constants.CELL_SIZE, clear_rows, theme.colors[Gameplay.current_piece.type])

        if cleared == 1 then Audio.play("clear1")
        elseif cleared == 2 then Audio.play("clear2")
        elseif cleared == 3 then Audio.play("clear3")
        else Audio.play("tetris")
        end
        Board.clear_lines(Gameplay.board)
    else
        Audio.play("lock")
    end

    if t_spin_type then
        Audio.play("t_spin")
        local label = "T-SPIN"
        if t_spin_type == "full" then
            if cleared == 1 then label = "T-SPIN SINGLE"
            elseif cleared == 2 then label = "T-SPIN DOUBLE"
            elseif cleared == 3 then label = "T-SPIN TRIPLE"
            end
        elseif t_spin_type == "mini" then
            if cleared == 0 then label = "MINI T-SPIN"
            elseif cleared == 1 then label = "MINI T-SPIN SINGLE"
            elseif cleared == 2 then label = "MINI T-SPIN DOUBLE"
            end
        end
        Effects.spawn_popup(label, constants.BOARD_X + 5 * constants.CELL_SIZE, constants.BOARD_Y + 8 * constants.CELL_SIZE, {0.95, 0.35, 0.95})
    end

    if Gameplay.mode then
        Gameplay.mode:onLineClear(Gameplay, cleared, clear_rows, t_spin_type)
        Gameplay.mode:onPieceLock(Gameplay)
    else
        Gameplay.lines = Gameplay.lines + cleared
        Gameplay.score = Gameplay.score + Scoring.calculate(cleared, Gameplay.level, t_spin_type, false)
        Gameplay.level = math.floor(Gameplay.lines / constants.LINES_PER_LEVEL) + 1
    end

    Gameplay.spawn_piece()
end

function Gameplay.check_post_move()
    Gameplay.is_grounded = Collision.is_grounded(Gameplay.board, Gameplay.current_piece)
    if Gameplay.is_grounded then
        Gameplay.lock_timer = 0
        Gameplay.lock_moves = Gameplay.lock_moves + 1
    end
end

function Gameplay.try_move(drow, dcol)
    if Collision.can_move(Gameplay.board, Gameplay.current_piece, dcol, drow) then
        Piece.move(Gameplay.current_piece, drow, dcol)
        Gameplay.last_was_rotation = false
        Gameplay.last_kick_idx = 0
        Gameplay.check_post_move()
        Audio.play("move")
        return true
    end
    return false
end

function Gameplay.soft_drop()
    if Gameplay.try_move(1, 0) then
        Gameplay.score = Gameplay.score + 1
        Gameplay.drop_timer = 0
    end
end

function Gameplay.hard_drop()
    local distance = 0
    while Collision.can_move(Gameplay.board, Gameplay.current_piece, 0, 1) do
        Gameplay.current_piece.row = Gameplay.current_piece.row + 1
        distance = distance + 1
    end
    Gameplay.score = Gameplay.score + distance * 2
    hermes:emit("hard_drop", Gameplay.current_piece.col, distance)
    Save.record_piece_place(true, false)
    Gameplay.lock_piece()
end

function Gameplay.hold_piece()
    if not GameplayOpts.hold_enabled then return end
    if not Queue.can_hold() then return end
    local held = Queue.hold_piece(Gameplay.current_piece.type)
    Audio.play("hold")
    Save.record_piece_place(false, true)
    if held then
        Gameplay.spawn_piece(held)
    else
        Gameplay.spawn_piece()
    end
end

function Gameplay.saveScore()
    if not Gameplay.mode then return end
    local mode_name = Gameplay.mode.name:lower()
    local pps = Gameplay.mode.getPPS and Gameplay.mode:getPPS() or 0
    local pieces = Gameplay.mode.pieces_placed or 0
    local kpp = (Gameplay.total_inputs or 0) / math.max(1, pieces)
    local time_mins = math.max(0.1, Gameplay.mode.timer or 1) / 60
    local attacks = (Gameplay.mode.garbage_sent or 0) + (Gameplay.mode.lines_cleared or Gameplay.lines or 0)
    local apm = attacks / time_mins
    Save.record_game_end(mode_name, Gameplay.score, Gameplay.lines, Gameplay.level, Gameplay.mode.timer or 0, {
        victory = Gameplay.victory,
        pps = pps,
        kpp = kpp,
        apm = apm,
        pieces = pieces,
    })
end

function Gameplay.update_score_rolling(dt)
    if Gameplay.displayed_score < Gameplay.score then
        local diff = Gameplay.score - Gameplay.displayed_score
        local speed = math.max(1, math.ceil(diff * math.min(1, dt * 14)))
        Gameplay.displayed_score = math.min(Gameplay.score, Gameplay.displayed_score + speed)
    elseif Gameplay.displayed_score > Gameplay.score then
        Gameplay.displayed_score = Gameplay.score
    end
end

function Gameplay:enter(previous, mode_override)
    -- Recompute layout based on current window size
    constants.recompute_layout()

    -- Refresh gameplay options from save
    GameplayOpts.load()

    Gameplay.board = Board.new()
    Gameplay.randomizer = Randomizer.new()
    Gameplay.score = 0
    Gameplay.displayed_score = 0
    Gameplay.lines = 0
    Gameplay.level = 1
    Gameplay.game_over = false
    Gameplay.victory = false
    Gameplay.soft_drop_active = false
    Gameplay.drop_timer = 0
    Gameplay.lock_timer = 0
    Gameplay.lock_moves = 0
    Gameplay.is_grounded = false
    Gameplay.total_inputs = 0
    Gameplay.countdown = Countdown.new(3.2)
    Effects.clear()
    Queue.init(Gameplay.randomizer, math.max(1, GameplayOpts.next_queue_size))

    Gameplay.mode = mode_override or Menu.createMode()
    if Gameplay.mode then
        Gameplay.mode:onStart(Gameplay)
    end

    Gameplay.last_was_rotation = false
    Gameplay.last_kick_idx = 0
    Gameplay.spawn_piece()

    Audio.playBGM(GameplayOpts.bgm_pack)
end

function Gameplay:update(dt)
    Gameplay.update_score_rolling(dt)

    if GameplayOpts.pitch_scaling then
        local pitch = 1.0 + (Gameplay.level - 1) * 0.015
        Audio.setBGMPitch(pitch)
    else
        Audio.setBGMPitch(1.0)
    end

    Effects.update_background_particles(dt, Themes.current_name)

    if Gameplay.board and not Gameplay.game_over and not (Gameplay.mode and Gameplay.mode.show_preset_overlay) then
        local danger = Board.get_danger_level(Gameplay.board)
        Effects.set_danger_level(danger)
    else
        Effects.set_danger_level(0)
    end

    -- Freeze gameplay & countdown while Preset Loader overlay is active
    if Gameplay.mode and Gameplay.mode.show_preset_overlay then
        Effects.update(dt)
        return
    end

    if Gameplay.game_over then
        Effects.update(dt)
        return
    end

    tick.update(dt)
    flux.update(dt)

    if Gameplay.countdown and Gameplay.countdown.active then
        Gameplay.countdown:update(dt)
        Effects.update(dt)
        return
    end

    local fired_actions = Input.update(dt)
    for _, action in ipairs(fired_actions) do
        if action == "MOVE_LEFT" then
            Gameplay.try_move(0, -1)
        elseif action == "MOVE_RIGHT" then
            Gameplay.try_move(0, 1)
        end
    end

    Effects.update(dt)

    if Gameplay.mode then
        Gameplay.mode:onTick(Gameplay, dt)
    end

    Gameplay.drop_timer = Gameplay.drop_timer + dt

    local drop_interval = Gameplay.mode and Gameplay.mode:getDropInterval(Gameplay) or Scoring.drop_interval(Gameplay.level)

    if Gameplay.soft_drop_active then
        if Gameplay.drop_timer >= GameplayOpts.get_soft_drop_interval() then
            Gameplay.drop_timer = 0
            Gameplay.soft_drop()
        end
    else
        if Gameplay.drop_timer >= drop_interval then
            Gameplay.drop_timer = 0
            if not Collision.is_grounded(Gameplay.board, Gameplay.current_piece) then
                Gameplay.current_piece.row = Gameplay.current_piece.row + 1
                Gameplay.is_grounded = false
            else
                Gameplay.is_grounded = true
            end
        end
    end

    if Gameplay.is_grounded then
        Gameplay.lock_timer = Gameplay.lock_timer + dt
        local lock_time = Gameplay.mode and Gameplay.mode.lock_delay or constants.LOCK_DELAY
        if Gameplay.lock_timer >= lock_time then
            Gameplay.lock_piece()
        end
    end

    if Gameplay.mode and Gameplay.mode:checkGameOver(Gameplay) then
        Gameplay.game_over = true
        Gameplay.victory = Gameplay.victory or false
        Audio.play("game_over")
        Gameplay.saveScore()
        Save.clearActiveRun()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DRAW – centered layout
-- ─────────────────────────────────────────────────────────────────────────────
-- DRAW – compact Arcade / PPT style layout
-- Left panel: HOLD
-- Center: Board + grid
-- Below board: Score banner
-- Right panel: NEXT queue + stats
-- ─────────────────────────────────────────────────────────────────────────────
function Gameplay:draw()
    local theme = Themes.get_board_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(theme.background[1], theme.background[2], theme.background[3])
    Effects.draw_background_particles(Themes.current_name)

    local cs = constants.CELL_SIZE
    local bx = constants.BOARD_X
    local by = constants.BOARD_Y
    local board_w = constants.GRID_COLS * cs
    local board_h = constants.GRID_ROWS * cs

    -- Compact container dimensions (wraps pieces tightly with padding)
    local mini = math.floor(cs * 0.65)
    local card_w = math.floor(cs * 3.4)  -- tight fit (~100px at default resolution)
    local card_gap = 10

    -- Left panel x (HOLD)
    local left_x = bx - card_w - card_gap
    -- Right panel x (NEXT + stats)
    local right_x = bx + board_w + card_gap

    love.graphics.push()
    local board_cx = bx + board_w / 2
    local board_cy = by + board_h / 2
    Effects.apply_board_transform(board_cx, board_cy)

    -- ── Outer Playfield Bezel / Container Frame ──
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bx - 4, by - 4, board_w + 8, board_h + 8, 6, 6)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx - 4, by - 4, board_w + 8, board_h + 8, 6, 6)
    love.graphics.setLineWidth(1)

    Renderer.draw_grid(bx, by, constants.GRID_COLS, constants.GRID_ROWS, cs, theme)
    Renderer.draw_board(Gameplay.board, bx, by, cs, theme)

    if not Gameplay.game_over then
        if GameplayOpts.ghost_enabled then
            local ghost_row = Board.get_ghost_row(Gameplay.board, Gameplay.current_piece)
            Renderer.draw_ghost(Gameplay.current_piece, ghost_row, bx, by, cs, theme)
        end
        Renderer.draw_piece(Gameplay.current_piece, bx, by, cs, theme)
    end

    Effects.flash_draw(bx, by, cs)
    Effects.particles_draw()
    love.graphics.pop()

    Effects.draw_danger_indicator(bx, by, board_w, board_h, cs)

    -- ── LEFT PANEL: HOLD ──────────────────────────────────────────────────
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("HOLD", left_x, by, card_w, "center")

    local hold_box_h = math.floor(cs * 2.8)
    local hold_box_y = by + 16
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", left_x, hold_box_y, card_w, hold_box_h, 6, 6)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.7)
    love.graphics.rectangle("line", left_x, hold_box_y, card_w, hold_box_h, 6, 6)

    if Queue.hold then
        local alpha = Queue.hold_used and 0.35 or 1.0
        love.graphics.setColor(1, 1, 1, alpha)
        Renderer.draw_mini_piece(Queue.hold, left_x, hold_box_y, mini, theme, card_w, hold_box_h)
    end

    -- ── RIGHT PANEL: NEXT ─────────────────────────────────────────────────
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("NEXT", right_x, by, card_w, "center")

    local next_box_h = math.floor(cs * 2.3)
    local show_next = math.max(1, math.min(GameplayOpts.next_queue_size, #Queue.next_queue))
    for i = 1, show_next do
        local y_off = by + 16 + (i - 1) * (next_box_h + 6)
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", right_x, y_off, card_w, next_box_h, 6, 6)
        love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.7)
        love.graphics.rectangle("line", right_x, y_off, card_w, next_box_h, 6, 6)
        Renderer.draw_mini_piece(Queue.next_queue[i], right_x, y_off, mini, theme, card_w, next_box_h)
    end

    -- ── SCORE (JUST BELOW PLAYFIELD MATRIX) ───────────────────────────────
    local score_y = by + board_h + 10
    local score_h = 48
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", bx, score_y, board_w, score_h, 8, 8)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, score_y, board_w, score_h, 8, 8)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.65, 0.75, 0.88)
    love.graphics.printf("SCORE", bx, score_y + 4, board_w, "center")

    love.graphics.setFont(Fonts.get(22))
    love.graphics.setColor(1, 0.92, 0.3)
    local formatted_score = string.format("%08d", math.floor(Gameplay.displayed_score))
    love.graphics.printf(formatted_score, bx, score_y + 18, board_w, "center")

    -- ── COUNTDOWN OVERLAY ──────────────────────────────────────────────────
    if Gameplay.countdown then
        Gameplay.countdown:draw(bx + board_w / 2, by + board_h / 2)
    end

    -- ── STATS (RIGHT PANEL BELOW NEXT QUEUE) ──────────────────────────────
    local stats_y = by + 16 + show_next * (next_box_h + 6) + 8

    local function stat_row(label, val, y)
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", right_x, y, card_w, 36, 6, 6)
        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.setFont(Fonts.get(9))
        love.graphics.printf(label, right_x, y + 3, card_w, "center")
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.setFont(Fonts.get(13))
        love.graphics.printf(tostring(val), right_x, y + 17, card_w, "center")
    end

    if Gameplay.mode then
        Gameplay.mode:drawHUD(Gameplay, right_x, stats_y)
    else
        stat_row("LEVEL", Gameplay.level, stats_y)
        stat_row("LINES", Gameplay.lines, stats_y + 42)
    end

    -- ── BOTTOM HINT & PROMPTS ─────────────────────────────────────────────
    local InputPrompts = require("lib.input_prompts")
    local hy = H - 22
    local hx = math.floor((W - 320) / 2)
    InputPrompts.draw_action_icon("ROTATE_CW", hx, hy, 16)
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.6, 0.7, 0.85)
    love.graphics.print("Rotate", hx + 18, hy + 1)

    InputPrompts.draw_action_icon("HOLD", hx + 100, hy, 16)
    love.graphics.print("Hold", hx + 118, hy + 1)

    InputPrompts.draw_action_icon("PAUSE", hx + 190, hy, 16)
    love.graphics.print("Pause", hx + 208, hy + 1)

    -- ── GAME OVER / VICTORY PROMPT MODAL OVERLAY ──────────────────────────
    if Gameplay.game_over then
        local mw, mh = 380, 210
        local mx = math.floor((W - mw) / 2)
        local my = math.floor((H - mh) / 2)
        local sel = Gameplay.game_over_sel or 1

        -- Dark Backdrop Overlay
        love.graphics.setColor(0, 0, 0, 0.78)
        love.graphics.rectangle("fill", 0, 0, W, H)

        -- Modal Container Card
        love.graphics.setColor(0.06, 0.08, 0.15, 0.96)
        love.graphics.rectangle("fill", mx, my, mw, mh, 10, 10)

        local border_color = Gameplay.victory and {0.2, 0.95, 0.45} or {0.95, 0.25, 0.25}
        love.graphics.setColor(border_color[1], border_color[2], border_color[3], 0.85)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", mx, my, mw, mh, 10, 10)
        love.graphics.setLineWidth(1)

        -- Header Banner Title
        love.graphics.setFont(Fonts.get(20))
        if Gameplay.victory then
            love.graphics.setColor(0.2, 1.0, 0.45)
            love.graphics.printf("🏆 VICTORY!", mx, my + 16, mw, "center")
        else
            love.graphics.setColor(1.0, 0.25, 0.25)
            love.graphics.printf("💥 GAME OVER", mx, my + 16, mw, "center")
        end

        -- Final Score & Line Breakdown
        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(0.85, 0.90, 1.0, 0.9)
        love.graphics.printf(string.format("Final Score: %d   •   Lines: %d", Gameplay.score, Gameplay.lines), mx, my + 54, mw, "center")

        -- Interactive Prompt Buttons (1: RESTART, 2: MAIN MENU)
        local btn_w, btn_h = 160, 44
        local btn_y = my + 92

        -- Button 1: RESTART
        local b1_x = mx + 20
        local is_b1_sel = (sel == 1)
        if is_b1_sel then
            love.graphics.setColor(0.12, 0.48, 0.35, 0.92)
            love.graphics.rectangle("fill", b1_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(0.35, 0.95, 0.65)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", b1_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.08, 0.12, 0.20, 0.75)
            love.graphics.rectangle("fill", b1_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(0.3, 0.4, 0.55)
            love.graphics.rectangle("line", b1_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(0.70, 0.80, 0.90)
        end
        love.graphics.setFont(Fonts.get(12))
        love.graphics.printf("🔄 RESTART", b1_x, btn_y + 5, btn_w, "center")
        local icon_y1 = btn_y + 24
        InputPrompts.draw_key_icon("r", b1_x + 40, icon_y1, 16)
        love.graphics.setFont(Fonts.get(9))
        love.graphics.setColor(0.65, 0.85, 0.75)
        love.graphics.print("or", b1_x + 60, icon_y1 + 1)
        InputPrompts.draw_key_icon("space", b1_x + 74, icon_y1, 16)

        -- Button 2: MAIN MENU
        local b2_x = mx + mw - btn_w - 20
        local is_b2_sel = (sel == 2)
        if is_b2_sel then
            love.graphics.setColor(0.48, 0.16, 0.22, 0.92)
            love.graphics.rectangle("fill", b2_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(1.0, 0.42, 0.42)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", b2_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.08, 0.12, 0.20, 0.75)
            love.graphics.rectangle("fill", b2_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(0.3, 0.4, 0.55)
            love.graphics.rectangle("line", b2_x, btn_y, btn_w, btn_h, 6, 6)
            love.graphics.setColor(0.70, 0.80, 0.90)
        end
        love.graphics.setFont(Fonts.get(12))
        love.graphics.printf("🏠 MAIN MENU", b2_x, btn_y + 5, btn_w, "center")
        InputPrompts.draw_key_icon("escape", b2_x + 40, icon_y1, 16)
        love.graphics.setFont(Fonts.get(9))
        love.graphics.setColor(0.85, 0.65, 0.65)
        love.graphics.print("or", b2_x + 60, icon_y1 + 1)
        InputPrompts.draw_key_icon("m", b2_x + 74, icon_y1, 16)

        -- Footer Navigation Hint with Hardware Icons
        local fx = mx + 28
        local fy = my + mh - 22
        InputPrompts.draw_key_icon("left", fx, fy, 14)
        InputPrompts.draw_key_icon("right", fx + 16, fy, 14)
        love.graphics.setFont(Fonts.get(9))
        love.graphics.setColor(0.55, 0.65, 0.78)
        love.graphics.print("Select Option", fx + 34, fy + 1)

        InputPrompts.draw_key_icon("return", fx + 180, fy, 14)
        love.graphics.print("Confirm Action", fx + 198, fy + 1)
    end

    -- ── PRESET PRACTICE LOADER OVERLAY (ZEN MODE) ─────────────────────────
    if Gameplay.mode and Gameplay.mode.drawPresetOverlay then
        Gameplay.mode:drawPresetOverlay()
    end
end

function Gameplay:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    -- Intercept inputs when Game Over modal prompt is active
    if Gameplay.game_over then
        if key == "left" or key == "up" or key == "a" or key == "w" then
            Gameplay.game_over_sel = 1
            Audio.play("move")
            return
        elseif key == "right" or key == "down" or key == "d" or key == "s" then
            Gameplay.game_over_sel = 2
            Audio.play("move")
            return
        elseif key == "r" then
            Gameplay.game_over_sel = 1
            Audio.play("rotate")
            self:enter(nil, Gameplay.mode)
            return
        elseif key == "m" or key == "escape" then
            Gameplay.game_over_sel = 2
            Audio.play("rotate")
            state_mgr.switch_with_swoosh("title")
            return
        elseif key == "return" or key == "space" then
            Audio.play("rotate")
            if (Gameplay.game_over_sel or 1) == 1 then
                self:enter(nil, Gameplay.mode)
            else
                state_mgr.switch_with_swoosh("title")
            end
            return
        end
        return
    end

    -- Intercept input for Preset Loader Overlay in Zen Mode if active
    if Gameplay.mode and Gameplay.mode.handlePresetInput and Gameplay.mode.show_preset_overlay then
        if Gameplay.mode:handlePresetInput(key, Gameplay) then
            return
        end
    end

    -- Toggle Preset Loader Overlay with P or F2 in Zen Mode
    if (key == "p" or key == "f2") and Gameplay.mode and Gameplay.mode.togglePresetOverlay then
        Gameplay.mode:togglePresetOverlay()
        return
    end

    -- Block player inputs during countdown (allow ESC pause)
    if Gameplay.countdown and Gameplay.countdown.active then
        if key == "escape" then
            state_mgr.push("pause")
        end
        return
    end

    local ctrl = love.keyboard.isDown("lctrl", "rctrl", "lgui", "rgui")
    local shift = love.keyboard.isDown("lshift", "rshift")

    -- Check for Zen Sandbox Hotkeys (Undo, Redo, Piece Injection, Board Clear)
    if Gameplay.mode and Gameplay.mode.name == "Zen" then
        if (ctrl and key == "z") or key == "u" then
            if Gameplay.mode:tryUndo(Gameplay) then return end
        elseif (ctrl and key == "y") or (shift and key == "u") then
            if Gameplay.mode:tryRedo(Gameplay) then return end
        elseif key == "i" then
            Gameplay.mode:injectPiece(Gameplay, "I")
            return
        elseif key == "c" or key == "delete" or key == "backspace" then
            Gameplay.mode:clearBoard(Gameplay)
            return
        end
    elseif (ctrl and key == "z") or key == "u" then
        if Gameplay.mode and Gameplay.mode.tryUndo then
            if Gameplay.mode:tryUndo(Gameplay) then
                Audio.play("hold")
                return
            end
        end
    end

    local action = Input.keypressed(key)

    if action == "PAUSE" or key == "escape" then
        state_mgr.push("pause")
    elseif action == "RESTART" and Gameplay.game_over then
        self:enter(nil, Gameplay.mode)
    elseif action == "MOVE_LEFT" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        Gameplay.try_move(0, -1)
    elseif action == "MOVE_RIGHT" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        Gameplay.try_move(0, 1)
    elseif action == "SOFT_DROP" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        Gameplay.soft_drop_active = true
    elseif action == "HARD_DROP" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        Gameplay.hard_drop()
    elseif action == "ROTATE_CW" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        local ok, kick_idx = Piece.try_rotate(Gameplay.board, Gameplay.current_piece, 1)
        if ok then
            Gameplay.last_was_rotation = true
            Gameplay.last_kick_idx = kick_idx
            Gameplay.check_post_move()
            Audio.play("rotate")
        end
    elseif action == "ROTATE_CCW" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        local ok, kick_idx = Piece.try_rotate(Gameplay.board, Gameplay.current_piece, -1)
        if ok then
            Gameplay.last_was_rotation = true
            Gameplay.last_kick_idx = kick_idx
            Gameplay.check_post_move()
            Audio.play("rotate")
        end
    elseif action == "HOLD" then
        Gameplay.total_inputs = (Gameplay.total_inputs or 0) + 1
        Gameplay.hold_piece()
    elseif action == "PAUSE" then
        state_mgr.push("pause")
    end
end

function Gameplay:keyreleased(key)
    local action = Input.keyreleased(key)
    if action == "SOFT_DROP_RELEASE" then
        Gameplay.soft_drop_active = false
    end
end

function Gameplay:mousepressed(x, y, button)
    if button ~= 1 then return end
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    if Gameplay.game_over then
        local mw, mh = 380, 210
        local mx = math.floor((W - mw) / 2)
        local my = math.floor((H - mh) / 2)
        local btn_w, btn_h = 160, 44
        local btn_y = my + 92
        local b1_x = mx + 20
        local b2_x = mx + mw - btn_w - 20

        if x >= b1_x and x <= b1_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
            Gameplay.game_over_sel = 1
            Audio.play("rotate")
            self:enter(nil, Gameplay.mode)
        elseif x >= b2_x and x <= b2_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
            Gameplay.game_over_sel = 2
            Audio.play("rotate")
            local state_mgr = require("lib.state_mgr")
            state_mgr.switch_with_swoosh("title")
        end
    end
end

return Gameplay
