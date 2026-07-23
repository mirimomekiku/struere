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

local Gameplay = {}

Gameplay.board = nil
Gameplay.current_piece = nil
Gameplay.randomizer = nil
Gameplay.score = 0
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

function Gameplay.spawn_piece(piece_type)
    local ptype = piece_type or Queue.pop(Gameplay.randomizer)
    Gameplay.current_piece = Piece.new(ptype, 21, 4)

    if Collision.any_overlap(Gameplay.board, Gameplay.current_piece.type,
                             Gameplay.current_piece.rotation,
                             Gameplay.current_piece.row, Gameplay.current_piece.col) then
        if Gameplay.mode and not Gameplay.mode.can_lose then
            Gameplay.board = Board.new()
            Queue.init(Gameplay.randomizer, constants.NEXT_QUEUE_SIZE)
            Gameplay.current_piece = Piece.new(Queue.pop(Gameplay.randomizer), 21, 4)
        else
            Gameplay.game_over = true
            if Gameplay.mode then Gameplay.mode:onGameOver(Gameplay) end
            Audio.play("game_over")
            Gameplay.saveScore()
            Save.clearActiveRun()
        end
    end
    Gameplay.is_grounded = false
    Gameplay.lock_timer = 0
    Gameplay.lock_moves = 0
    Gameplay.drop_timer = 0
end

function Gameplay.lock_piece()
    -- Save undo snapshot before locking
    if Gameplay.mode and Gameplay.mode.beforeLock then
        Gameplay.mode:beforeLock(Gameplay)
    end
    Board.place_piece(Gameplay.board, Gameplay.current_piece)

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

        if cleared == 1 then Audio.play("clear1")
        elseif cleared == 2 then Audio.play("clear2")
        elseif cleared == 3 then Audio.play("clear3")
        else Audio.play("tetris")
        end
        Board.clear_lines(Gameplay.board)
    else
        Audio.play("lock")
    end

    if Gameplay.mode then
        Gameplay.mode:onLineClear(Gameplay, cleared, clear_rows)
        Gameplay.mode:onPieceLock(Gameplay)
    else
        Gameplay.lines = Gameplay.lines + cleared
        Gameplay.score = Gameplay.score + Scoring.calculate(cleared, Gameplay.level)
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
    hermes:emit("hard_drop")
    Gameplay.lock_piece()
end

function Gameplay.hold_piece()
    if not GameplayOpts.hold_enabled then return end
    if not Queue.can_hold() then return end
    local held = Queue.hold_piece(Gameplay.current_piece.type)
    Audio.play("hold")
    if held then
        Gameplay.spawn_piece(held)
    else
        Gameplay.spawn_piece()
    end
end

function Gameplay.saveScore()
    if not Gameplay.mode then return end
    local mode_name = Gameplay.mode.name:lower()
    if mode_name == "marathon" then
        Save.updateHighScore("marathon", {
            score = Gameplay.score,
            level = Gameplay.level,
            lines = Gameplay.lines,
            date = os.date("%Y-%m-%d"),
        })
    elseif mode_name == "blitz" then
        Save.updateHighScore("blitz", {
            score = Gameplay.score,
            pieces = Gameplay.mode.pieces_placed or 0,
            date = os.date("%Y-%m-%d"),
        })
    elseif mode_name == "sprint" then
        Save.updateHighScore("sprint", {
            score = Gameplay.score,
            time = Gameplay.mode.timer or 0,
            date = os.date("%Y-%m-%d"),
        })
        if Gameplay.victory then
            Save.updateSprintBest(Gameplay.mode.line_goal or 40, Gameplay.mode.timer or 0)
        end
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
    Gameplay.lines = 0
    Gameplay.level = 1
    Gameplay.game_over = false
    Gameplay.victory = false
    Gameplay.soft_drop_active = false
    Gameplay.drop_timer = 0
    Gameplay.lock_timer = 0
    Gameplay.lock_moves = 0
    Gameplay.is_grounded = false
    Effects.clear()
    Queue.init(Gameplay.randomizer, math.max(1, GameplayOpts.next_queue_size))

    Gameplay.mode = mode_override or Menu.createMode()
    if Gameplay.mode then
        Gameplay.mode:onStart(Gameplay)
    end

    Gameplay.theme_name = Themes.get().name
    Gameplay.spawn_piece()
end

function Gameplay:update(dt)
    if Gameplay.game_over then
        Effects.update(dt)
        return
    end

    tick.update(dt)
    flux.update(dt)

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
-- Left panel: HOLD
-- Center: Board + grid
-- Right panel: NEXT queue + stats
-- ─────────────────────────────────────────────────────────────────────────────
function Gameplay:draw()
    local theme = Themes.get_board_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(theme.background[1], theme.background[2], theme.background[3])

    local cs = constants.CELL_SIZE
    local bx = constants.BOARD_X
    local by = constants.BOARD_Y
    local board_w = constants.GRID_COLS * cs
    local board_h = constants.GRID_ROWS * cs

    local panel_w = math.max(cs * 5, 120)
    local panel_margin = math.floor(cs * 0.6)

    -- Left panel x (HOLD)
    local left_x = bx - panel_w - panel_margin
    -- Right panel x (NEXT + stats)
    local right_x = bx + board_w + panel_margin

    love.graphics.push()
    Effects.apply_shake()

    -- ── Background glow behind board ──
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", bx - 2, by - 2, board_w + 4, board_h + 4, 4, 4)

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

    -- ── LEFT PANEL: HOLD ──────────────────────────────────────────────────
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("HOLD", left_x, by, panel_w, "center")

    local hold_box_h = math.floor(cs * 3.5)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", left_x, by + 18, panel_w, hold_box_h, 6, 6)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.8)
    love.graphics.rectangle("line", left_x, by + 18, panel_w, hold_box_h, 6, 6)

    if Queue.hold then
        local alpha = Queue.hold_used and 0.35 or 1.0
        love.graphics.setColor(1, 1, 1, alpha)
        Renderer.draw_mini_piece(Queue.hold, left_x + 4, by + 22, math.floor(cs * 0.7), theme)
    end

    -- ── RIGHT PANEL: NEXT + STATS ─────────────────────────────────────────
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("NEXT", right_x, by, panel_w, "center")

    local mini = math.floor(cs * 0.65)
    local show_next = math.max(1, math.min(GameplayOpts.next_queue_size, #Queue.next_queue))
    for i = 1, show_next do
        local y_off = by + 18 + (i - 1) * (mini * 3 + 8)
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", right_x, y_off, panel_w, mini * 3, 6, 6)
        love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3], 0.7)
        love.graphics.rectangle("line", right_x, y_off, panel_w, mini * 3, 6, 6)
        Renderer.draw_mini_piece(Queue.next_queue[i], right_x + 4, y_off + 4, mini, theme)
    end

    -- ── STATS ─────────────────────────────────────────────────────────────
    local stats_y = by + 18 + 5 * (mini * 3 + 8) + 10

    local function stat_row(label, val, y)
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", right_x, y, panel_w, 38, 6, 6)
        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.setFont(love.graphics.newFont(9))
        love.graphics.printf(label, right_x, y + 4, panel_w, "center")
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(tostring(val), right_x, y + 18, panel_w, "center")
    end

    if Gameplay.mode then
        Gameplay.mode:drawHUD(Gameplay, right_x, stats_y)
    else
        stat_row("SCORE", Gameplay.score, stats_y)
        stat_row("LEVEL", Gameplay.level, stats_y + 46)
        stat_row("LINES", Gameplay.lines, stats_y + 92)
    end

    -- ── BOTTOM HINT ──────────────────────────────────────────────────────
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.printf("P: Pause  ESC: Menu", 0, H - 18, W, "center")

    love.graphics.pop()

    -- ── GAME OVER OVERLAY ─────────────────────────────────────────────────
    if Gameplay.game_over then
        local ox = bx + math.floor(board_w * 0.1)
        local oy = by + math.floor(board_h * 0.35)
        local ow = math.floor(board_w * 0.8)
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", ox, oy, ow, 110, 10, 10)
        love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.7)
        love.graphics.rectangle("line", ox, oy, ow, 110, 10, 10)

        love.graphics.setFont(love.graphics.newFont(22))
        if Gameplay.victory then
            love.graphics.setColor(0.2, 1, 0.4)
            love.graphics.printf("VICTORY!", ox, oy + 12, ow, "center")
        else
            love.graphics.setColor(1, 0.25, 0.25)
            love.graphics.printf("GAME OVER", ox, oy + 12, ow, "center")
        end
        love.graphics.setFont(love.graphics.newFont(13))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Score: " .. Gameplay.score, ox, oy + 52, ow, "center")
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("R: Restart    ESC: Menu", ox, oy + 80, ow, "center")
    end
end

function Gameplay:keypressed(key)
    local state_mgr = require("lib.state_mgr")
    local action = Input.keypressed(key)

    if action == "QUIT" or key == "escape" then
        state_mgr.switch("title")
    elseif action == "RESTART" and Gameplay.game_over then
        self:enter(nil, Gameplay.mode)
    elseif action == "MOVE_LEFT" then
        Gameplay.try_move(0, -1)
    elseif action == "MOVE_RIGHT" then
        Gameplay.try_move(0, 1)
    elseif action == "SOFT_DROP" then
        Gameplay.soft_drop_active = true
    elseif action == "HARD_DROP" then
        Gameplay.hard_drop()
    elseif action == "ROTATE_CW" then
        if Piece.try_rotate(Gameplay.board, Gameplay.current_piece, 1) then
            Gameplay.check_post_move()
            Audio.play("rotate")
        end
    elseif action == "ROTATE_CCW" then
        if Piece.try_rotate(Gameplay.board, Gameplay.current_piece, -1) then
            Gameplay.check_post_move()
            Audio.play("rotate")
        end
    elseif action == "HOLD" then
        Gameplay.hold_piece()
    elseif key == "u" then
        -- Undo (Zen mode or any mode that supports it)
        if Gameplay.mode and Gameplay.mode.tryUndo then
            if Gameplay.mode:tryUndo(Gameplay) then
                Audio.play("hold")
            end
        end
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

return Gameplay
