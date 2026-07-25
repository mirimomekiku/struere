-- lib/screens/unlockables.lua
-- Visual & Audio Customization Screen: Split UI with interactive Live 10x20 Grid Preview

local Themes       = require("lib.themes")
local Audio        = require("lib.audio")
local Save         = require("lib.save")
local Fonts        = require("lib.fonts")
local Renderer     = require("lib.renderer")
local Piece        = require("lib.piece")
local GameplayOpts = require("lib.gameplay_opts")
local InputPrompts = require("lib.input_prompts")
local Effects      = require("lib.effects")

local Unlockables = {}

Unlockables.selected = 1

-- Available options
Unlockables.themes_order  = Themes.order
Unlockables.bgm_keys      = {"chiptune", "synthwave", "classical"}
Unlockables.bgm_labels    = {"Chiptune (8-bit)", "Synthwave (80s)", "Classical (Baroque)"}

Unlockables.ghost_keys    = {"tint", "outline", "solid", "disabled"}
Unlockables.ghost_labels  = {"Colored Tint", "Outline Only", "Solid Translucent", "Disabled"}

Unlockables.opacity_vals  = {0.0, 0.2, 0.4, 0.6, 0.8, 1.0}
Unlockables.opacity_labels= {"0% (Off)", "20%", "40%", "60%", "80%", "100%"}

Unlockables.pattern_keys  = {"lines", "check", "dots"}
Unlockables.pattern_labels= {"Grid Lines", "Checkerboard", "Subtle Dots"}

-- Active indexes
Unlockables.theme_idx   = 1
Unlockables.bgm_idx     = 1
Unlockables.ghost_idx   = 1
Unlockables.opacity_idx = 4
Unlockables.pattern_idx = 1

-- Sample preview board stack
Unlockables.preview_board = nil
Unlockables.preview_piece = { type = "T", rotation = 0, row = 28, col = 4 }
Unlockables.preview_ghost_row = 37

function Unlockables.init_preview_board()
    local Board = require("lib.board")
    local b = Board.new()
    -- Create sample landed blocks for visually attractive preview stack
    -- Row 40 (bottom)
    Board.set_cell(b, 40, 1, "I"); Board.set_cell(b, 40, 2, "I"); Board.set_cell(b, 40, 3, "I"); Board.set_cell(b, 40, 4, "I")
    Board.set_cell(b, 40, 5, "Z"); Board.set_cell(b, 40, 6, "Z"); Board.set_cell(b, 40, 7, "L"); Board.set_cell(b, 40, 8, "L"); Board.set_cell(b, 40, 9, "L")
    -- Row 39
    Board.set_cell(b, 39, 1, "J"); Board.set_cell(b, 39, 2, "O"); Board.set_cell(b, 39, 3, "O"); Board.set_cell(b, 39, 5, "Z")
    Board.set_cell(b, 39, 6, "S"); Board.set_cell(b, 39, 7, "S"); Board.set_cell(b, 39, 9, "L")
    -- Row 38
    Board.set_cell(b, 38, 1, "J"); Board.set_cell(b, 38, 2, "O"); Board.set_cell(b, 38, 3, "O"); Board.set_cell(b, 38, 6, "S"); Board.set_cell(b, 38, 7, "S")
    Unlockables.preview_board = b
end

function Unlockables:enter(previous)
    Unlockables.selected = 1
    Unlockables.init_preview_board()

    -- Load current settings into indexes
    local cur_theme = Themes.current_name or "retro"
    Unlockables.theme_idx = 1
    for i, k in ipairs(Unlockables.themes_order) do
        if k == cur_theme then Unlockables.theme_idx = i; break end
    end

    local cur_bgm = GameplayOpts.bgm_pack or "chiptune"
    Unlockables.bgm_idx = 1
    for i, k in ipairs(Unlockables.bgm_keys) do
        if k == cur_bgm then Unlockables.bgm_idx = i; break end
    end

    local cur_ghost = GameplayOpts.ghost_style or "tint"
    Unlockables.ghost_idx = 1
    for i, k in ipairs(Unlockables.ghost_keys) do
        if k == cur_ghost then Unlockables.ghost_idx = i; break end
    end

    local cur_opacity = GameplayOpts.grid_opacity or 0.6
    Unlockables.opacity_idx = 4
    for i, v in ipairs(Unlockables.opacity_vals) do
        if math.abs(v - cur_opacity) < 0.05 then Unlockables.opacity_idx = i; break end
    end

    local cur_pattern = GameplayOpts.grid_pattern or "lines"
    Unlockables.pattern_idx = 1
    for i, k in ipairs(Unlockables.pattern_keys) do
        if k == cur_pattern then Unlockables.pattern_idx = i; break end
    end
end

function Unlockables:update(dt)
    Effects.update_background_particles(dt)
end

function Unlockables:draw()
    local ui_theme = Themes.get_ui_theme()
    local board_theme = Themes.get_board_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(0.02, 0.03, 0.08)

    local px = math.floor(W * 0.04)
    local py = math.floor(H * 0.04)
    local pw = W - px * 2
    local ph = H - py * 2

    -- Main Container Box
    love.graphics.setColor(0.04, 0.04, 0.10, 0.95)
    love.graphics.rectangle("fill", px, py, pw, ph, 16, 16)
    love.graphics.setColor(board_theme.accent[1], board_theme.accent[2], board_theme.accent[3], 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 16, 16)
    love.graphics.setLineWidth(1)

    -- Header Title
    love.graphics.setFont(Fonts.get(22))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("VISUAL & AUDIO CUSTOMIZATION", px, py + 14, pw, "center")

    -- Horizontal Divider
    love.graphics.setColor(0.3, 0.3, 0.45, 0.5)
    love.graphics.line(px + 16, py + 48, px + pw - 16, py + 48)

    local body_y = py + 58
    local body_h = ph - 96

    -- Split UI Layout: Left panel = 55% width, Right panel = 45% width
    local left_w = math.floor(pw * 0.55) - 16
    local right_x = px + left_w + 24
    local right_w = pw - left_w - 32

    -- ── LEFT PANEL: CUSTOMIZATION CONTROLS ──────────────────────────────────────
    local options = {
        {
            name = "Visual Theme",
            val = Themes.list[Unlockables.themes_order[Unlockables.theme_idx]].name,
            desc = "Change the visual styling, block colors, and HUD theme"
        },
        {
            name = "BGM Music Pack",
            val = Unlockables.bgm_labels[Unlockables.bgm_idx],
            desc = "Select active background music soundtrack genre"
        },
        {
            name = "Ghost Piece Style",
            val = Unlockables.ghost_labels[Unlockables.ghost_idx],
            desc = "Shadow projection style: Colored Tint, Outline, Solid, or Off"
        },
        {
            name = "Grid Line Opacity",
            val = Unlockables.opacity_labels[Unlockables.opacity_idx],
            desc = "Transparency intensity of matrix background grid"
        },
        {
            name = "Grid Pattern Style",
            val = Unlockables.pattern_labels[Unlockables.pattern_idx],
            desc = "Matrix grid layout: Standard Lines, Checkerboard, or Dots"
        },
    }

    local card_h = math.floor((body_h - 20) / #options) - 6

    for i, opt in ipairs(options) do
        local cy = body_y + (i - 1) * (card_h + 6)
        local is_sel = (i == Unlockables.selected)

        if is_sel then
            love.graphics.setColor(board_theme.accent[1], board_theme.accent[2], board_theme.accent[3], 0.85)
            love.graphics.rectangle("fill", px + 12, cy, left_w, card_h, 8, 8)
            love.graphics.setColor(0.05, 0.05, 0.1)
        else
            love.graphics.setColor(0.08, 0.09, 0.16, 0.8)
            love.graphics.rectangle("fill", px + 12, cy, left_w, card_h, 8, 8)
            love.graphics.setColor(0.85, 0.88, 0.95)
        end

        love.graphics.setFont(Fonts.get(13))
        love.graphics.print(opt.name, px + 24, cy + 8)

        -- Value text with navigation indicator arrows
        love.graphics.setFont(Fonts.get(12))
        local val_str = "<  " .. opt.val .. "  >"
        love.graphics.printf(val_str, px + 12, cy + 8, left_w - 20, "right")

        -- Subtitle Description
        if is_sel then
            love.graphics.setColor(0.1, 0.1, 0.15, 0.85)
        else
            love.graphics.setColor(0.5, 0.55, 0.65)
        end
        love.graphics.setFont(Fonts.get(10))
        love.graphics.printf(opt.desc, px + 24, cy + 28, left_w - 32, "left")
    end

    -- ── RIGHT PANEL: LIVE 10x20 MATRIX PREVIEW GRID ─────────────────────────────
    love.graphics.setColor(0.06, 0.07, 0.14, 0.9)
    love.graphics.rectangle("fill", right_x, body_y, right_w, body_h, 12, 12)
    love.graphics.setColor(board_theme.accent[1], board_theme.accent[2], board_theme.accent[3], 0.4)
    love.graphics.rectangle("line", right_x, body_y, right_w, body_h, 12, 12)

    -- Live Preview Section Title
    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf("LIVE MATRIX PREVIEW", right_x, body_y + 10, right_w, "center")

    -- Calculate cell size for 10x20 grid preview
    local grid_cols, grid_rows = 10, 20
    local max_gh = body_h - 90
    local cell_size = math.min(18, math.floor(max_gh / grid_rows))
    local grid_w = grid_cols * cell_size
    local grid_h = grid_rows * cell_size

    local grid_x = right_x + math.floor((right_w - grid_w) / 2)
    local grid_y = body_y + 36

    -- Draw theme background frame for matrix preview
    love.graphics.setColor(board_theme.background[1], board_theme.background[2], board_theme.background[3], 0.9)
    love.graphics.rectangle("fill", grid_x, grid_y, grid_w, grid_h)

    -- Draw background particles in preview window
    love.graphics.setScissor(grid_x, grid_y, grid_w, grid_h)
    Effects.draw_background_particles()
    love.graphics.setScissor()

    -- Render Grid lines with active opacity and pattern
    local active_opacity = Unlockables.opacity_vals[Unlockables.opacity_idx]
    local active_pattern = Unlockables.pattern_keys[Unlockables.pattern_idx]
    Renderer.draw_grid(grid_x, grid_y, grid_cols, grid_rows, cell_size, board_theme, active_opacity, active_pattern)

    -- Render Sample Landed Board Stack
    if Unlockables.preview_board then
        Renderer.draw_board(Unlockables.preview_board, grid_x, grid_y, cell_size, board_theme)
    end

    -- Render Active Ghost Piece in preview grid
    local active_ghost = Unlockables.ghost_keys[Unlockables.ghost_idx]
    Renderer.draw_ghost(Unlockables.preview_piece, Unlockables.preview_ghost_row, grid_x, grid_y, cell_size, board_theme, active_ghost)

    -- Render Active Falling Piece in preview grid
    Renderer.draw_piece(Unlockables.preview_piece, grid_x, grid_y, cell_size, board_theme)

    -- Color Palette Swatches Bar below grid
    local palette_y = grid_y + grid_h + 12
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Theme Palette:", right_x + 12, palette_y, 90, "left")

    local sw = 15
    local sh = 14
    local p_keys = {"I", "O", "T", "S", "Z", "J", "L"}
    local sw_start_x = right_x + 105
    for pi, pk in ipairs(p_keys) do
        local c = board_theme.colors[pk]
        if c then
            love.graphics.setColor(c[1]/255, c[2]/255, c[3]/255, 0.95)
            love.graphics.rectangle("fill", sw_start_x + (pi - 1) * (sw + 3), palette_y, sw, sh, 3, 3)
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("line", sw_start_x + (pi - 1) * (sw + 3), palette_y, sw, sh, 3, 3)
        end
    end

    -- Bottom instructions footer with gamepad prompt badges
    local foot_y = py + ph - 24
    local prompt_size = 14
    local f_font = Fonts.get(10)
    love.graphics.setFont(f_font)
    love.graphics.setColor(0.5, 0.55, 0.65)

    local legend_x = px + 20
    InputPrompts.draw_action_badge("MOVE_LEFT", "Select Row", legend_x, foot_y, prompt_size, f_font)
    InputPrompts.draw_action_badge("ROTATE_CW", "Change Value", legend_x + 180, foot_y, prompt_size, f_font)
    InputPrompts.draw_action_badge("HARD_DROP", "Save & Exit", legend_x + 360, foot_y, prompt_size, f_font)
end

function Unlockables:change_option(dir)
    if Unlockables.selected == 1 then
        Unlockables.theme_idx = Unlockables.theme_idx + dir
        if Unlockables.theme_idx < 1 then Unlockables.theme_idx = #Unlockables.themes_order end
        if Unlockables.theme_idx > #Unlockables.themes_order then Unlockables.theme_idx = 1 end
        local t_key = Unlockables.themes_order[Unlockables.theme_idx]
        Themes.set(t_key)
        Save.set("settings", "theme", t_key)

    elseif Unlockables.selected == 2 then
        Unlockables.bgm_idx = Unlockables.bgm_idx + dir
        if Unlockables.bgm_idx < 1 then Unlockables.bgm_idx = #Unlockables.bgm_keys end
        if Unlockables.bgm_idx > #Unlockables.bgm_keys then Unlockables.bgm_idx = 1 end
        local bgm_key = Unlockables.bgm_keys[Unlockables.bgm_idx]
        GameplayOpts.bgm_pack = bgm_key
        Audio.playBGM(bgm_key)

    elseif Unlockables.selected == 3 then
        Unlockables.ghost_idx = Unlockables.ghost_idx + dir
        if Unlockables.ghost_idx < 1 then Unlockables.ghost_idx = #Unlockables.ghost_keys end
        if Unlockables.ghost_idx > #Unlockables.ghost_keys then Unlockables.ghost_idx = 1 end
        GameplayOpts.ghost_style = Unlockables.ghost_keys[Unlockables.ghost_idx]

    elseif Unlockables.selected == 4 then
        Unlockables.opacity_idx = Unlockables.opacity_idx + dir
        if Unlockables.opacity_idx < 1 then Unlockables.opacity_idx = #Unlockables.opacity_vals end
        if Unlockables.opacity_idx > #Unlockables.opacity_vals then Unlockables.opacity_idx = 1 end
        GameplayOpts.grid_opacity = Unlockables.opacity_vals[Unlockables.opacity_idx]

    elseif Unlockables.selected == 5 then
        Unlockables.pattern_idx = Unlockables.pattern_idx + dir
        if Unlockables.pattern_idx < 1 then Unlockables.pattern_idx = #Unlockables.pattern_keys end
        if Unlockables.pattern_idx > #Unlockables.pattern_keys then Unlockables.pattern_idx = 1 end
        GameplayOpts.grid_pattern = Unlockables.pattern_keys[Unlockables.pattern_idx]
    end

    GameplayOpts.save()
    Save.save()
    Audio.play("rotate")
end

function Unlockables:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "up" then
        Unlockables.selected = Unlockables.selected - 1
        if Unlockables.selected < 1 then Unlockables.selected = 5 end
        Audio.play("move")
    elseif key == "down" then
        Unlockables.selected = Unlockables.selected + 1
        if Unlockables.selected > 5 then Unlockables.selected = 1 end
        Audio.play("move")
    elseif key == "left" then
        Unlockables:change_option(-1)
    elseif key == "right" or key == "return" or key == "space" then
        Unlockables:change_option(1)
    elseif key == "escape" then
        GameplayOpts.save()
        Save.save()
        state_mgr.pop()
    end
end

return Unlockables
