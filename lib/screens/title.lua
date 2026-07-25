-- lib/screens/title.lua
-- TetriX Main Menu & Mode Selector — Refactored to match Tetris Ultimate aesthetics

local flux          = require("lib.vendor.flux")
local Themes        = require("lib.themes")
local Audio         = require("lib.audio")
local Save          = require("lib.save")
local constants     = require("lib.constants")
local Fonts         = require("lib.fonts")
local ShaderManager = require("lib.shaders.manager")

local Title = {}

-- ─── Tab Definitions ──────────────────────────────────────────────────────────
Title.TABS = {
    { id = "play",     label = "PLAY",     icon = "▶", color = {0.11, 0.40, 1.00}, underline = {0.11, 0.45, 1.00} },
    { id = "progress", label = "PROGRESS", icon = "★", color = {0.06, 0.72, 0.33}, underline = {0.10, 0.85, 0.40} },
    { id = "options",  label = "OPTIONS",  icon = "⚙", color = {0.90, 0.20, 0.20}, underline = {1.00, 0.30, 0.30} },
}

-- ─── Mode Cards Definition for PLAY Tab ───────────────────────────────────────
Title.MODE_CARDS = {
    {
        id        = "marathon",
        label     = "MARATHON",
        subtag    = "SOLO",
        has_r     = true,
        desc      = "Standard gravity climb. Reach your line target before speed overwhelms you.",
        goal_txt  = "Play to Level 15",
        color     = {0.48, 0.22, 0.85},
        dark      = {0.16, 0.08, 0.32},
        border    = {0.68, 0.40, 1.00},
        icon_type = "marathon",
        variants  = {
            { label = "150 Lines", config = { line_goal = 150 } },
            { label = "200 Lines", config = { line_goal = 200 } },
            { label = "Endless",   config = { line_goal = nil } },
        },
    },
    {
        id        = "battle",
        label     = "BATTLE",
        subtag    = "VS CPU",
        has_r     = true,
        desc      = "Face off against AI opponent. Clear 2+ lines to send garbage rows!",
        goal_txt  = "Defeat the CPU",
        color     = {0.15, 0.38, 0.88},
        dark      = {0.05, 0.14, 0.38},
        border    = {0.35, 0.65, 1.00},
        icon_type = "battle",
        variants  = {
            { label = "Easy",   config = { difficulty = "easy" } },
            { label = "Medium", config = { difficulty = "medium" } },
            { label = "Hard",   config = { difficulty = "hard" } },
            { label = "Boss ★", config = { difficulty = "boss" } },
        },
    },
    {
        id        = "sprint",
        label     = "SPRINT",
        subtag    = "40 LINES",
        has_r     = false,
        desc      = "Clear 40 lines as fast as humanly possible. Track your PPS and time.",
        goal_txt  = "Clear 40 Lines Fast",
        color     = {0.05, 0.62, 0.88},
        dark      = {0.02, 0.22, 0.38},
        border    = {0.20, 0.82, 1.00},
        icon_type = "sprint",
        variants  = {},
    },
    {
        id        = "blitz",
        label     = "TIME'S UP",
        subtag    = "BLITZ 2-MIN",
        has_r     = false,
        desc      = "120 seconds score attack. Maximize combos, T-Spins, and All Clears!",
        goal_txt  = "Score High in 2 Mins",
        color     = {0.85, 0.25, 0.75},
        dark      = {0.35, 0.08, 0.30},
        border    = {1.00, 0.45, 0.90},
        icon_type = "times_up",
        variants  = {},
    },
    {
        id        = "battle_ultimate",
        label     = "BATTLE ULTIMATE",
        subtag    = "BOSS VS",
        has_r     = false,
        desc      = "High-stakes battle against the Master Tetribot on maximum speed!",
        goal_txt  = "Survive the Boss AI",
        color     = {0.88, 0.15, 0.15},
        dark      = {0.35, 0.05, 0.05},
        border    = {1.00, 0.30, 0.30},
        icon_type = "bomb",
        variants  = {},
    },
    {
        id        = "zen",
        label     = "ZEN",
        subtag    = "ZEN PRACTICE",
        has_r     = false,
        desc      = "Infinite relaxed gameplay with misdrop undo (Press U) and no game over.",
        goal_txt  = "Endless Practice",
        color     = {0.08, 0.68, 0.52},
        dark      = {0.03, 0.25, 0.20},
        border    = {0.20, 0.92, 0.72},
        icon_type = "ultra",
        variants  = {},
    },
}

-- ─── Tetribot Party Play Roster ───────────────────────────────────────────────
Title.TETRIBOTS = {
    { name = "Apprentice Tetribot",  belt = "Orange Belt", color = {1.00, 0.55, 0.10}, diff = "easy" },
    { name = "Intermediate Tetribot", belt = "Blue Belt",   color = {0.20, 0.60, 1.00}, diff = "medium" },
    { name = "Advanced Tetribot",     belt = "Green Belt",  color = {0.20, 0.85, 0.40}, diff = "hard" },
    { name = "Master Tetribot",       belt = "Purple Belt", color = {0.75, 0.25, 0.95}, diff = "boss" },
}

-- ─── Rotating Tips for Bottom Ticker ─────────────────────────────────────────
Title.TIPS = {
    "60 SECOND SPRINT! For the ultimate in bragging rights, finish Sprint mode in 60 seconds or less.",
    "T-SPIN DOUBLE scores 2x in Blitz mode — set up T-Spin overhangs for massive points!",
    "VS CPU BATTLE: Clearing a 4-line Tetris sends 4 garbage lines directly to your opponent.",
    "ZEN PRACTICE: Press U to undo misdrops at any time and master your stacking technique.",
    "MARATHON: Gravity accelerates every 10 lines cleared. Can you survive to Level 15?",
    "BACK-TO-BACK Tetris and T-Spin clears gain a 1.5x multiplier on all line score awards.",
}

-- ─── Options Tab Cards ───────────────────────────────────────────────────────
Title.OPTION_CARDS = {
    { id = "settings",    label = "GAME SETTINGS",               icon = "⚙", desc = "Configure controls, display resolution, audio levels, and gameplay mechanics.", color = {0.18, 0.45, 0.85} },
    { id = "unlockables", label = "VISUAL & AUDIO CUSTOMIZATION", icon = "🎨", desc = "Customize visual themes, BGM music pack, ghost piece style, grid opacity & pattern with live matrix preview.", color = {0.60, 0.25, 0.85} },
    { id = "shaders",     label = "SHADERS",                     icon = "🖥", desc = "Configure CRT distortion, Chromatic aberration, Pixel matrix, Motion blur, Signal noise, VHS, and Phosphor decay shaders.", color = {0.10, 0.70, 0.60} },
    { id = "quit",        label = "QUIT GAME",                   icon = "✕", desc = "Close TetriX and safely exit back to your operating system desktop.", color = {0.85, 0.22, 0.28} },
}

-- ─── State ────────────────────────────────────────────────────────────────────
Title.current_tab       = 1  -- 1: PLAY, 2: PROGRESS, 3: OPTIONS
Title.selected_play     = 1  -- 1..6 (mode cards), 7..10 (party play bots)
Title.selected_options  = 1  -- 1..5
Title.variant_idx       = {} -- per mode card variant selection index
Title.tetris_live       = false
Title.time              = 0
Title.alpha             = 0
Title.tip_idx           = 1
Title.tip_scroll        = 0

Title.quit_modal        = false
Title.quit_sel          = 2  -- 1: Yes, Quit | 2: No, Stay
Title.card_scales       = {}
Title.focus_box         = { x = 0, y = 0, w = 0, h = 0, target_x = 0, target_y = 0, target_w = 0, target_h = 0, active = false }

Title.tab_trans = {
    active    = false,
    timer     = 0,
    duration  = 0.28,
    direction = 1,
    prev_tab  = 1,
    curr_tab  = 1,
}

function Title.switch_tab(target_tab)
    if target_tab == Title.current_tab then return end

    local dir = 1
    if target_tab < Title.current_tab then dir = -1 end
    if Title.current_tab == 1 and target_tab == #Title.TABS then dir = -1
    elseif Title.current_tab == #Title.TABS and target_tab == 1 then dir = 1 end

    Title.tab_trans.active    = true
    Title.tab_trans.timer     = 0
    Title.tab_trans.direction = dir
    Title.tab_trans.prev_tab  = Title.current_tab
    Title.tab_trans.curr_tab  = target_tab
    Title.current_tab         = target_tab

    if target_tab == 2 then
        Title.focus_box.active = false
    end

    Audio.play("move")
end

Title.piece_types = {"I", "O", "T", "S", "Z", "J", "L"}
local COLUMNS = {}

function Title:enter(previous)
    Title.current_tab = 1
    Title.tab_trans.active = false
    Title.selected_play = 1
    Title.selected_options = 1
    Title.time = 0
    Title.alpha = 0
    Title.tip_scroll = 0
    Title.tip_idx = 1
    Title.quit_modal = false
    Title.quit_sel = 2
    Title.card_scales = {}
    for i = 1, 15 do Title.card_scales[i] = 1.0 end
    Title.focus_box = { x = 0, y = 0, w = 0, h = 0, target_x = 0, target_y = 0, target_w = 0, target_h = 0, active = false }

    for i, card in ipairs(Title.MODE_CARDS) do
        if not Title.variant_idx[i] then
            Title.variant_idx[i] = 1
        end
    end

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    COLUMNS = {}
    local col_count = math.floor(W / 32)
    for i = 1, col_count do
        table.insert(COLUMNS, {
            x = (i - 0.5) * 32,
            y = math.random(-H, 0),
            speed = math.random(35, 110),
            type = Title.piece_types[math.random(#Title.piece_types)],
            size = 24,
            alpha = math.random(5, 20) / 100,
            trail_len = math.random(3, 7),
        })
    end

    flux.to(Title, 0.5, { alpha = 1 }):ease("quadout")
end

function Title:update(dt)
    Title.time = Title.time + dt
    flux.update(dt)

    if Title.focus_box and Title.focus_box.active then
        local spd = math.min(1, dt * 20)
        Title.focus_box.x = Title.focus_box.x + (Title.focus_box.target_x - Title.focus_box.x) * spd
        Title.focus_box.y = Title.focus_box.y + (Title.focus_box.target_y - Title.focus_box.y) * spd
        Title.focus_box.w = Title.focus_box.w + (Title.focus_box.target_w - Title.focus_box.w) * spd
        Title.focus_box.h = Title.focus_box.h + (Title.focus_box.target_h - Title.focus_box.h) * spd
    end

    if Title.tab_trans.active then
        Title.tab_trans.timer = Title.tab_trans.timer + dt
        if Title.tab_trans.timer >= Title.tab_trans.duration then
            Title.tab_trans.active = false
        end
    end

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    for _, col in ipairs(COLUMNS) do
        col.y = col.y + col.speed * dt
        if col.y > H + 50 then
            col.y = -50
            col.x = math.random(0, W)
            col.type = Title.piece_types[math.random(#Title.piece_types)]
            col.speed = math.random(35, 110)
        end
    end

    -- Scroll bottom tip text
    Title.tip_scroll = Title.tip_scroll + 45 * dt
    local tip = Title.TIPS[Title.tip_idx]
    local tip_width = #tip * 7.5
    if Title.tip_scroll > W + tip_width then
        Title.tip_scroll = -W * 0.1
        Title.tip_idx = (Title.tip_idx % #Title.TIPS) + 1
    end
end

-- ─── Drawing Helper Utilities ─────────────────────────────────────────────────
local function rr(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r or 6, r or 6)
end

local function rl(x, y, w, h, r)
    love.graphics.rectangle("line", x, y, w, h, r or 6, r or 6)
end

local function draw_dot_grid(W, H, alpha)
    love.graphics.setColor(0.15, 0.35, 0.75, alpha * 0.15)
    local step = 24
    for x = 0, W, step do
        for y = 0, H, step do
            love.graphics.circle("fill", x, y, 1.2)
        end
    end
end

-- ─── Vector Icon Drawer ────────────────────────────────────────────────────────
local function draw_vector_icon(icon_type, cx, cy, size, r, g, b, alpha)
    love.graphics.setColor(r, g, b, alpha * 0.22)
    love.graphics.circle("fill", cx, cy, size * 0.65)

    love.graphics.setColor(r, g, b, alpha)
    love.graphics.setLineWidth(2.5)

    if icon_type == "marathon" then
        -- Tetromino stack box icon
        local s = size * 0.45
        love.graphics.rectangle("line", cx - s, cy - s*0.6, s*2, s*1.3, 4, 4)
        love.graphics.rectangle("line", cx - s*0.6, cy - s*0.2, s*1.2, s*0.7, 2, 2)
        love.graphics.line(cx - s, cy, cx + s, cy)

    elseif icon_type == "battle" then
        -- Shield icon
        local s = size * 0.45
        local pts = {
            cx - s, cy - s,
            cx + s, cy - s,
            cx + s, cy,
            cx,     cy + s*1.1,
            cx - s, cy
        }
        love.graphics.polygon("line", pts)
        love.graphics.line(cx, cy - s, cx, cy + s * 0.9)

    elseif icon_type == "sprint" then
        -- Hourglass icon
        local s = size * 0.45
        local top_pts = { cx - s, cy - s, cx + s, cy - s, cx, cy }
        local bot_pts = { cx, cy, cx + s, cy + s, cx - s, cy + s }
        love.graphics.polygon("line", top_pts)
        love.graphics.polygon("line", bot_pts)
        love.graphics.circle("fill", cx, cy + s * 0.5, 3)

    elseif icon_type == "times_up" then
        -- Circle 30 timer icon
        local rad = size * 0.48
        love.graphics.circle("line", cx, cy, rad)
        love.graphics.setFont(Fonts.get(math.floor(size * 0.45)))
        love.graphics.printf("30", cx - size, cy - size * 0.30, size * 2, "center")

    elseif icon_type == "bomb" then
        -- Bomb icon with fuse
        local rad = size * 0.42
        love.graphics.circle("line", cx, cy + 3, rad)
        love.graphics.rectangle("fill", cx - 4, cy - rad - 2, 8, 4)
        love.graphics.line(cx, cy - rad - 2, cx + 8, cy - rad - 10)
        -- Spark
        love.graphics.setColor(1, 0.8, 0.2, alpha)
        love.graphics.circle("fill", cx + 9, cy - rad - 11, 3)

    elseif icon_type == "ultra" then
        -- Stopwatch / Clock icon
        local rad = size * 0.45
        love.graphics.circle("line", cx, cy + 2, rad)
        love.graphics.line(cx - 4, cy - rad - 2, cx + 4, cy - rad - 2)
        love.graphics.line(cx, cy + 2, cx + rad * 0.5, cy - rad * 0.3)
        love.graphics.circle("fill", cx, cy + 2, 2.5)

    elseif icon_type == "robot" then
        -- Robot icon for Tetribots
        local s = size * 0.40
        love.graphics.rectangle("line", cx - s, cy - s*0.7, s*2, s*1.4, 3, 3)
        -- Eyes
        love.graphics.circle("fill", cx - s*0.4, cy - s*0.2, 2.5)
        love.graphics.circle("fill", cx + s*0.4, cy - s*0.2, 2.5)
        -- Mouth
        love.graphics.line(cx - s*0.4, cy + s*0.3, cx + s*0.4, cy + s*0.3)
        -- Antenna
        love.graphics.line(cx, cy - s*0.7, cx, cy - s*1.1)
        love.graphics.circle("fill", cx, cy - s*1.2, 2)
    end

    love.graphics.setLineWidth(1)
end

-- ─── Draw Main Top Header ─────────────────────────────────────────────────────
local function draw_top_header(W, alpha, current_tab)
    local header_h = 76
    love.graphics.setColor(0.04, 0.06, 0.14, alpha * 0.98)
    love.graphics.rectangle("fill", 0, 0, W, header_h)

    -- Fine grid texture on header
    love.graphics.setColor(0.2, 0.4, 0.8, alpha * 0.08)
    for x = 0, W, 10 do
        love.graphics.rectangle("fill", x, 0, 1, header_h)
    end
    love.graphics.setColor(0.15, 0.25, 0.45, alpha * 0.8)
    love.graphics.rectangle("fill", 0, header_h - 2, W, 2)

    -- Top Tabs: PLAY, PROGRESS, OPTIONS
    local tab_x = 24
    local tab_w = 155
    local tab_h = 56
    for i, tab in ipairs(Title.TABS) do
        local is_active = (i == current_tab)
        local tx = tab_x + (i - 1) * (tab_w + 14)
        local ty = 10

        if is_active then
            love.graphics.setColor(tab.color[1], tab.color[2], tab.color[3], alpha * 0.28)
            rr(tx, ty, tab_w, tab_h, 8)
            love.graphics.setColor(1, 1, 1, alpha)
        else
            love.graphics.setColor(0.55, 0.60, 0.72, alpha * 0.65)
        end

        love.graphics.setFont(Fonts.get(18))
        love.graphics.printf(tab.label .. " " .. tab.icon, tx, ty + 16, tab_w, "center")

        -- Underline indicator bar
        if is_active then
            love.graphics.setColor(tab.underline[1], tab.underline[2], tab.underline[3], alpha * 0.95)
            love.graphics.rectangle("fill", tx + 6, header_h - 7, tab_w - 12, 5, 2, 2)
        else
            love.graphics.setColor(0.25, 0.30, 0.42, alpha * 0.4)
            love.graphics.rectangle("fill", tx + 12, header_h - 6, tab_w - 24, 3, 1, 1)
        end
    end

    -- Top Right User Profile Badge
    local Save = require("lib.save")
    local belt_info = Save.get_belt_info()
    local bc = belt_info.color
    local prof_x = W - 250
    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(bc[1], bc[2], bc[3], alpha * 0.95)
    love.graphics.printf(belt_info.rank, prof_x, 16, 150, "right")

    love.graphics.setFont(Fonts.get(17))
    love.graphics.setColor(0.9, 0.95, 1.0, alpha)
    love.graphics.printf("PLAYER 1", prof_x, 38, 150, "right")

    -- P1 Circle Badge
    local p1_cx = W - 45
    local p1_cy = 38
    love.graphics.setColor(0.08, 0.25, 0.55, alpha * 0.9)
    love.graphics.circle("fill", p1_cx, p1_cy, 22)
    love.graphics.setColor(0.20, 0.65, 1.00, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", p1_cx, p1_cy, 22)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(Fonts.get(15))
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf("P1", p1_cx - 15, p1_cy - 10, 30, "center")
end

-- ─── Draw PLAY Tab Content ────────────────────────────────────────────────────
local function draw_play_tab(W, H, alpha, time)
    local header_h = 76
    local bottom_bar_h = 58
    local margin = 16
    local sidebar_w = 260

    local grid_x = margin
    local grid_y = header_h + margin
    local grid_w = W - sidebar_w - margin * 3
    local grid_h = H - grid_y - bottom_bar_h - margin

    local cols = 3
    local rows = 2
    local gap_x = 12
    local gap_y = 12
    local card_w = math.floor((grid_w - gap_x * (cols - 1)) / cols)
    local card_h = math.floor((grid_h - gap_y * (rows - 1)) / rows)

    -- 1. Mode Cards (1..6)
    for i, card in ipairs(Title.MODE_CARDS) do
        local r = math.ceil(i / cols)
        local c = ((i - 1) % cols) + 1
        local cx = grid_x + (c - 1) * (card_w + gap_x)
        local cy = grid_y + (r - 1) * (card_h + gap_y)
        local is_sel = (Title.current_tab == 1 and Title.selected_play == i)

        if is_sel then
            Title.focus_box.target_x = cx
            Title.focus_box.target_y = cy
            Title.focus_box.target_w = card_w
            Title.focus_box.target_h = card_h
            if not Title.focus_box.active then
                Title.focus_box.x, Title.focus_box.y = cx, cy
                Title.focus_box.w, Title.focus_box.h = card_w, card_h
                Title.focus_box.active = true
            end
        end

        local cr, cg, cb = card.color[1], card.color[2], card.color[3]
        local dr, dg, db = card.dark[1], card.dark[2], card.dark[3]
        local br, bg, bb = card.border[1], card.border[2], card.border[3]

        -- Focus glow
        if is_sel then
            local pulse = math.sin(time * 4) * 0.2 + 0.8
            love.graphics.setColor(br, bg, bb, alpha * pulse * 0.25)
            rr(cx - 4, cy - 4, card_w + 8, card_h + 8, 10)
        end

        -- Base card box
        love.graphics.setColor(dr, dg, db, alpha * 0.95)
        rr(cx, cy, card_w, card_h, 8)

        -- Top header stripe in card (dark tinted for sharp text contrast)
        love.graphics.setColor(cr * 0.45, cg * 0.45, cb * 0.45, alpha * (is_sel and 0.95 or 0.75))
        rr(cx, cy, card_w, 28, 8)
        love.graphics.rectangle("fill", cx, cy + 20, card_w, 8)

        -- Title text
        love.graphics.setFont(Fonts.get(12))
        love.graphics.setColor(1, 1, 1, alpha * (is_sel and 1.0 or 0.85))
        love.graphics.printf(card.label, cx + 8, cy + 6, card_w - 16, "left")

        -- Subtag / Variant info at bottom of card
        if card.has_r then
            local vi = Title.variant_idx[i] or 1
            local vlabel = card.variants[vi] and card.variants[vi].label or card.subtag
            love.graphics.setFont(Fonts.get(10))
            love.graphics.setColor(0.15, 0.45, 0.85, alpha * 0.9)
            love.graphics.rectangle("fill", cx + 6, cy + card_h - 26, card_w - 12, 18, 4, 4)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.printf(card.subtag .. ": " .. vlabel .. "  (R▶)", cx + 8, cy + card_h - 23, card_w - 16, "center")
        end

        -- Icon in middle of card
        local icon_cx = cx + card_w * 0.5
        local icon_cy = cy + 30 + (card_h - 60) * 0.45
        local icon_sz = math.min(card_w, card_h) * 0.42
        draw_vector_icon(card.icon_type, icon_cx, icon_cy, icon_sz, cr, cg, cb, alpha * (is_sel and 1.0 or 0.65))

        -- Border accent
        love.graphics.setLineWidth(is_sel and 2.5 or 1.0)
        love.graphics.setColor(br, bg, bb, alpha * (is_sel and 0.95 or 0.3))
        rl(cx, cy, card_w, card_h, 8)
        love.graphics.setLineWidth(1)
    end

    -- 2. Right Sidebar (PARTY PLAY! & Tetribots)
    local sx = grid_x + grid_w + margin
    local sy = grid_y
    local sh = grid_h

    love.graphics.setColor(0.04, 0.07, 0.16, alpha * 0.96)
    rr(sx, sy, sidebar_w, sh, 8)
    love.graphics.setColor(0.95, 0.45, 0.10, alpha * 0.4)
    rl(sx, sy, sidebar_w, sh, 8)

    -- Header "SELECT YOUR POISON" Orange Box
    love.graphics.setColor(0.95, 0.48, 0.08, alpha * 0.98)
    rr(sx + 6, sy + 6, sidebar_w - 12, 34, 6)
    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf("SELECT YOUR POISON", sx + 6, sy + 14, sidebar_w - 12, "center")

    -- TETRIS LIVE row
    local l_y = sy + 48
    love.graphics.setColor(0.08, 0.12, 0.24, alpha * 0.9)
    rr(sx + 8, l_y, sidebar_w - 16, 36, 6)
    love.graphics.setColor(0.2, 0.4, 0.8, alpha * 0.3)
    rl(sx + 8, l_y, sidebar_w - 16, 36, 6)

    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(0.9, 0.95, 1.0, alpha)
    love.graphics.printf("TETRIS® LIVE", sx + 16, l_y + 4, 120, "left")
    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.5, 0.6, 0.75, alpha)
    love.graphics.printf(Title.tetris_live and "ON" or "OFF", sx + 16, l_y + 20, 120, "left")

    -- Atom / Globe Icon for Tetris Live
    draw_vector_icon("ultra", sx + sidebar_w - 28, l_y + 18, 20, 0.2, 0.7, 1.0, alpha * 0.8)

    -- Tetribot List (7..10)
    local bot_y = l_y + 44
    local bot_h = math.floor((sh - (bot_y - sy) - 12) / 4)

    for bi, bot in ipairs(Title.TETRIBOTS) do
        local slot_idx = 6 + bi
        local is_bot_sel = (Title.current_tab == 1 and Title.selected_play == slot_idx)
        local by = bot_y + (bi - 1) * bot_h

        if is_bot_sel then
            Title.focus_box.target_x = sx + 8
            Title.focus_box.target_y = by + 2
            Title.focus_box.target_w = sidebar_w - 16
            Title.focus_box.target_h = bot_h - 4
            if not Title.focus_box.active then
                Title.focus_box.x, Title.focus_box.y = sx + 8, by + 2
                Title.focus_box.w, Title.focus_box.h = sidebar_w - 16, bot_h - 4
                Title.focus_box.active = true
            end
        end

        if is_bot_sel then
            love.graphics.setColor(bot.color[1] * 0.4, bot.color[2] * 0.4, bot.color[3] * 0.4, alpha * 0.8)
            rr(sx + 8, by + 2, sidebar_w - 16, bot_h - 4, 6)
            love.graphics.setColor(bot.color[1], bot.color[2], bot.color[3], alpha)
            rl(sx + 8, by + 2, sidebar_w - 16, bot_h - 4, 6)
        else
            love.graphics.setColor(0.06, 0.09, 0.18, alpha * 0.7)
            rr(sx + 8, by + 2, sidebar_w - 16, bot_h - 4, 6)
        end

        -- Robot icon
        local rc, gc, bc = bot.color[1], bot.color[2], bot.color[3]
        draw_vector_icon("robot", sx + 28, by + bot_h * 0.5, 22, rc, gc, bc, alpha * (is_bot_sel and 1.0 or 0.65))

        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(1, 1, 1, alpha * (is_bot_sel and 1.0 or 0.75))
        love.graphics.printf(bot.name, sx + 50, by + 6, sidebar_w - 60, "left")

        love.graphics.setFont(Fonts.get(10))
        love.graphics.setColor(rc, gc, bc, alpha * 0.9)
        love.graphics.printf(bot.belt, sx + 50, by + 22, sidebar_w - 60, "left")
    end

    -- 3. Bottom Right Status / Action Prompt Box
    local act_w = 280
    local act_h = 36
    local act_x = W - act_w - margin
    local act_y = H - bottom_bar_h - act_h - 6

    love.graphics.setColor(0.04, 0.12, 0.32, alpha * 0.95)
    rr(act_x, act_y, act_w, act_h, 6)
    love.graphics.setColor(0.15, 0.55, 1.00, alpha * 0.6)
    rl(act_x, act_y, act_w, act_h, 6)

    local sel_mode = Title.MODE_CARDS[Title.selected_play]
    local target_text = sel_mode and sel_mode.goal_txt or "Play Selected Mode"
    if Title.selected_play > 6 then
        local bot = Title.TETRIBOTS[Title.selected_play - 6]
        target_text = "VS " .. (bot and bot.name or "Bot")
    end

    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(0.2, 0.75, 1.0, alpha)
    love.graphics.printf(target_text, act_x + 12, act_y + 9, act_w - 100, "left")

    local InputPrompts = require("lib.input_prompts")
    InputPrompts.draw_action_badge("ROTATE_CW", "PLAY", act_x + act_w - 85, act_y + 7, 22, Fonts.get(13))
end

-- ─── Draw PROGRESS Tab Content (Greyed Out / WIP) ─────────────────────────────
-- ─── Draw PROGRESS Tab Content ────────────────────────────────────────────────
local function draw_progress_tab(W, H, alpha)
    local Save = require("lib.save")
    local stats = Save.data.stats or {}
    local belt_info = Save.get_belt_info()

    local header_h = 76
    local bottom_bar_h = 58
    local margin = 12

    local px = margin
    local py = header_h + margin
    local pw = W - margin * 2
    local ph = H - py - bottom_bar_h - margin

    -- Main Container Frame
    love.graphics.setColor(0.04, 0.05, 0.09, alpha * 0.95)
    rr(px, py, pw, ph, 12)
    love.graphics.setColor(0.18, 0.22, 0.32, alpha * 0.7)
    rl(px, py, pw, ph, 12)

    local inner_margin = 12
    local inner_w = pw - inner_margin * 2

    -- ── 1. TOP ROW: Belt Progression & Lifetime Overview (Height: 120px) ──────
    local top_h = 120
    local col_w = math.floor((inner_w - inner_margin) / 2)
    local top_y = py + inner_margin

    -- Left Card: BELT PROGRESSION & RANK
    local bc = belt_info.color
    love.graphics.setColor(0.08, 0.10, 0.16, alpha * 0.9)
    rr(px + inner_margin, top_y, col_w, top_h, 10)
    love.graphics.setColor(bc[1], bc[2], bc[3], alpha * 0.5)
    rl(px + inner_margin, top_y, col_w, top_h, 10)

    -- Belt Icon / Rank Label
    love.graphics.setFont(Fonts.get(15))
    love.graphics.setColor(bc[1], bc[2], bc[3], alpha)
    love.graphics.printf("★ BELT RANK: " .. belt_info.rank:upper(), px + inner_margin + 14, top_y + 12, col_w - 28, "left")

    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.65, 0.72, 0.85, alpha * 0.8)
    love.graphics.printf("Clear lines to level up and earn new belts!", px + inner_margin + 14, top_y + 34, col_w - 28, "left")

    -- Belt Progress Bar
    local bar_x = px + inner_margin + 14
    local bar_y = top_y + 56
    local bar_w = col_w - 28
    local bar_h = 24

    love.graphics.setColor(0.04, 0.05, 0.08, alpha * 0.8)
    rr(bar_x, bar_y, bar_w, bar_h, 6)
    if belt_info.pct > 0 then
        love.graphics.setColor(bc[1], bc[2], bc[3], alpha * 0.85)
        rr(bar_x, bar_y, bar_w * belt_info.pct, bar_h, 6)
    end
    love.graphics.setColor(1, 1, 1, alpha * 0.4)
    rl(bar_x, bar_y, bar_w, bar_h, 6)

    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(1, 1, 1, alpha)
    local prog_text = string.format("%d / %d Lines  (%.0f%%)", belt_info.lines, belt_info.next_req, belt_info.pct * 100)
    love.graphics.printf(prog_text, bar_x, bar_y + 5, bar_w, "center")

    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.5, 0.55, 0.7, alpha * 0.85)
    love.graphics.printf("Next Rank: " .. belt_info.next_rank, bar_x, top_y + 90, bar_w, "right")

    -- Right Card: LIFETIME OVERVIEW
    local right_x = px + inner_margin + col_w + inner_margin
    love.graphics.setColor(0.08, 0.10, 0.16, alpha * 0.9)
    rr(right_x, top_y, col_w, top_h, 10)
    love.graphics.setColor(0.20, 0.35, 0.60, alpha * 0.5)
    rl(right_x, top_y, col_w, top_h, 10)

    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(0.3, 0.8, 1.0, alpha)
    love.graphics.printf("🏆 LIFETIME OVERVIEW", right_x + 14, top_y + 10, col_w - 28, "left")

    -- 4 Stat Tiles Grid (2x2) inside Right Card
    local tile_w = math.floor((col_w - 36) / 2)
    local tile_h = 32
    local t_sec_x = right_x + 14
    local t_sec_y = top_y + 36

    local total_sec = math.floor(stats.total_playtime or 0)
    local hours = math.floor(total_sec / 3600)
    local mins = math.floor((total_sec % 3600) / 60)
    local secs = total_sec % 60
    local time_str = string.format("%02d:%02d:%02d", hours, mins, secs)

    local tiles = {
        { label = "GAMES PLAYED", val = tostring(stats.total_games or 0) },
        { label = "TOTAL SCORE", val = string.format("%d", stats.total_score or 0) },
        { label = "TOTAL PLAYTIME", val = time_str },
        { label = "PIECES PLACED", val = tostring(stats.total_pieces or 0) },
    }

    for ti, t in ipairs(tiles) do
        local tx = t_sec_x + ((ti - 1) % 2) * (tile_w + 8)
        local ty = t_sec_y + math.floor((ti - 1) / 2) * (tile_h + 8)

        love.graphics.setColor(0.05, 0.07, 0.12, alpha * 0.75)
        rr(tx, ty, tile_w, tile_h, 6)

        love.graphics.setFont(Fonts.get(8))
        love.graphics.setColor(0.55, 0.65, 0.75, alpha * 0.8)
        love.graphics.printf(t.label, tx + 4, ty + 3, tile_w - 8, "center")

        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(1, 0.9, 0.3, alpha)
        love.graphics.printf(t.val, tx + 4, ty + 15, tile_w - 8, "center")
    end

    -- ── 2. MIDDLE ROW: Mode Bests & Records Grid (4 Columns) ──────────────────
    local mid_y = top_y + top_h + inner_margin
    local mid_h = 135
    local mcard_w = math.floor((inner_w - 3 * inner_margin) / 4)

    local m_stats = stats.marathon or {}
    local sp_stats = stats.sprint or {}
    local bl_stats = stats.blitz or {}
    local bt_stats = stats.battle or {}

    local sprint_bt = sp_stats.best_time
    local sprint_str = sprint_bt and string.format("%02d:%05.2f", math.floor(sprint_bt / 60), sprint_bt % 60) or "--:--"

    local total_battles = (bt_stats.wins or 0) + (bt_stats.losses or 0)
    local win_rate = total_battles > 0 and ((bt_stats.wins or 0) / total_battles * 100) or 0

    local mode_cards = {
        {
            title = "MARATHON",
            color = {0.65, 0.30, 0.95},
            lines = {
                { "Top Score", string.format("%d", m_stats.top_score or 0) },
                { "Max Level", string.format("Lv. %d", m_stats.max_level or 1) },
                { "Max Lines", string.format("%d L", m_stats.max_lines or 0) },
            }
        },
        {
            title = "SPRINT (40L)",
            color = {0.15, 0.85, 0.95},
            lines = {
                { "Best Time", sprint_str },
                { "Best Speed", string.format("%.2f PPS", sp_stats.best_pps or 0) },
                { "Completions", string.format("%d wins", sp_stats.completions or 0) },
            }
        },
        {
            title = "TIME'S UP (BLITZ)",
            color = {0.95, 0.30, 0.65},
            lines = {
                { "Top Score", string.format("%d", bl_stats.top_score or 0) },
                { "Max Pieces", string.format("%d pcs", bl_stats.max_pieces or 0) },
                { "Games Played", string.format("%d", bl_stats.games_played or 0) },
            }
        },
        {
            title = "VS CPU BATTLE",
            color = {0.20, 0.65, 1.00},
            lines = {
                { "Record", string.format("%dW / %dL", bt_stats.wins or 0, bt_stats.losses or 0) },
                { "Win Rate", string.format("%.0f%%", win_rate) },
                { "Best Streak", string.format("%d wins", bt_stats.best_streak or 0) },
            }
        },
    }

    for mi, mc in ipairs(mode_cards) do
        local mc_x = px + inner_margin + (mi - 1) * (mcard_w + inner_margin)
        love.graphics.setColor(0.07, 0.09, 0.15, alpha * 0.9)
        rr(mc_x, mid_y, mcard_w, mid_h, 8)
        love.graphics.setColor(mc.color[1], mc.color[2], mc.color[3], alpha * 0.5)
        rl(mc_x, mid_y, mcard_w, mid_h, 8)

        love.graphics.setFont(Fonts.get(12))
        love.graphics.setColor(mc.color[1], mc.color[2], mc.color[3], alpha)
        love.graphics.printf(mc.title, mc_x + 8, mid_y + 10, mcard_w - 16, "center")

        local line_y = mid_y + 36
        love.graphics.setFont(Fonts.get(10))
        for li, ln in ipairs(mc.lines) do
            local ly = line_y + (li - 1) * 30
            love.graphics.setColor(0.04, 0.05, 0.09, alpha * 0.6)
            rr(mc_x + 8, ly, mcard_w - 16, 26, 4)

            love.graphics.setColor(0.60, 0.68, 0.78, alpha * 0.8)
            love.graphics.printf(ln[1], mc_x + 12, ly + 6, mcard_w - 24, "left")

            love.graphics.setColor(1, 0.92, 0.40, alpha)
            love.graphics.printf(ln[2], mc_x + 12, ly + 6, mcard_w - 24, "right")
        end
    end

    -- ── 3. BOTTOM ROW: Line Clear Breakdown & Gameplay Counters ──────────────
    local bot_y = mid_y + mid_h + inner_margin
    local bot_h = ph - (bot_y - py) - inner_margin

    love.graphics.setColor(0.07, 0.09, 0.15, alpha * 0.9)
    rr(px + inner_margin, bot_y, inner_w, bot_h, 10)
    love.graphics.setColor(0.25, 0.30, 0.40, alpha * 0.5)
    rl(px + inner_margin, bot_y, inner_w, bot_h, 10)

    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(0.85, 0.90, 1.0, alpha)
    love.graphics.printf("⚡ LINE CLEAR BREAKDOWN & MECHANICS", px + inner_margin + 14, bot_y + 10, inner_w - 28, "left")

    local l_card_w = math.floor((inner_w - 28 - 3 * 10) / 4)
    local l_card_h = 42
    local l_sec_y = bot_y + 32

    local line_types = {
        { title = "SINGLE", count = stats.singles or 0, color = {1.00, 0.75, 0.20} },
        { title = "DOUBLE", count = stats.doubles or 0, color = {0.20, 0.80, 1.00} },
        { title = "TRIPLE", count = stats.triples or 0, color = {0.30, 0.95, 0.45} },
        { title = "TETRIS!", count = stats.tetrises or 0, color = {0.85, 0.35, 1.00} },
    }

    for li, lt in ipairs(line_types) do
        local lx = px + inner_margin + 14 + (li - 1) * (l_card_w + 10)
        love.graphics.setColor(0.04, 0.05, 0.09, alpha * 0.8)
        rr(lx, l_sec_y, l_card_w, l_card_h, 6)
        love.graphics.setColor(lt.color[1], lt.color[2], lt.color[3], alpha * 0.6)
        rl(lx, l_sec_y, l_card_w, l_card_h, 6)

        love.graphics.setFont(Fonts.get(9))
        love.graphics.setColor(lt.color[1], lt.color[2], lt.color[3], alpha)
        love.graphics.printf(lt.title, lx + 6, l_sec_y + 4, l_card_w - 12, "center")

        love.graphics.setFont(Fonts.get(13))
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(tostring(lt.count), lx + 6, l_sec_y + 18, l_card_w - 12, "center")
    end

    -- Bottom Sub-bar: Best Performance Metrics & Extra Counters
    local best_pps = stats.best_pps or 0
    local best_kpp_str = stats.best_kpp and string.format("%.2f KPP", stats.best_kpp) or "-- KPP"
    local best_apm = stats.best_apm or 0

    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.2, 0.95, 0.9, alpha * 0.95)
    local perf_info = string.format("★ BEST METRICS:   Speed: %.2f PPS   |   Efficiency: %s   |   Attacks: %.1f APM",
        best_pps, best_kpp_str, best_apm)
    love.graphics.printf(perf_info, px + inner_margin + 14, bot_y + bot_h - 30, inner_w - 28, "center")

    love.graphics.setFont(Fonts.get(9))
    love.graphics.setColor(0.55, 0.62, 0.75, alpha * 0.8)
    local sub_info = string.format("Holds Used: %d   |   Hard Drops: %d   |   Total Lines Cleared: %d",
        stats.holds_used or 0, stats.hard_drops or 0, stats.total_lines or 0)
    love.graphics.printf(sub_info, px + inner_margin + 14, bot_y + bot_h - 15, inner_w - 28, "center")
end

-- ─── Draw OPTIONS Tab Content ─────────────────────────────────────────────────
local function draw_options_tab(W, H, alpha)
    local header_h = 76
    local bottom_bar_h = 58
    local margin = 16
    local sidebar_w = 260

    local grid_x = margin
    local grid_y = header_h + margin
    local grid_w = W - sidebar_w - margin * 3
    local grid_h = H - grid_y - bottom_bar_h - margin

    local card_w = grid_w
    local card_h = math.floor((grid_h - 10 * (#Title.OPTION_CARDS - 1)) / #Title.OPTION_CARDS)

    -- Option List Cards
    for i, opt in ipairs(Title.OPTION_CARDS) do
        local cy = grid_y + (i - 1) * (card_h + 10)
        local is_sel = (Title.current_tab == 3 and Title.selected_options == i)

        if is_sel then
            Title.focus_box.target_x = grid_x
            Title.focus_box.target_y = cy
            Title.focus_box.target_w = card_w
            Title.focus_box.target_h = card_h
            if not Title.focus_box.active then
                Title.focus_box.x, Title.focus_box.y = grid_x, cy
                Title.focus_box.w, Title.focus_box.h = card_w, card_h
                Title.focus_box.active = true
            end
        end

        local cr, cg, cb = opt.color[1], opt.color[2], opt.color[3]

        if is_sel then
            love.graphics.setColor(cr * 0.35, cg * 0.35, cb * 0.35, alpha * 0.85)
            rr(grid_x, cy, card_w, card_h, 8)
            love.graphics.setColor(cr, cg, cb, alpha)
            rl(grid_x, cy, card_w, card_h, 8)
        else
            love.graphics.setColor(0.06, 0.08, 0.16, alpha * 0.75)
            rr(grid_x, cy, card_w, card_h, 8)
            love.graphics.setColor(0.18, 0.22, 0.35, alpha * 0.3)
            rl(grid_x, cy, card_w, card_h, 8)
        end

        -- Icon
        love.graphics.setFont(Fonts.get(18))
        love.graphics.setColor(cr, cg, cb, alpha * (is_sel and 1.0 or 0.6))
        love.graphics.printf(opt.icon, grid_x + 14, cy + card_h * 0.5 - 12, 30, "center")

        -- Label
        love.graphics.setFont(Fonts.get(14))
        love.graphics.setColor(1, 1, 1, alpha * (is_sel and 1.0 or 0.8))
        love.graphics.printf(opt.label, grid_x + 50, cy + 8, card_w - 70, "left")

        -- Description
        love.graphics.setFont(Fonts.get(10))
        love.graphics.setColor(0.6, 0.65, 0.78, alpha * 0.7)
        love.graphics.printf(opt.desc, grid_x + 50, cy + 28, card_w - 70, "left")
    end

    -- Right Sidebar (System Status Overview)
    local sx = grid_x + grid_w + margin
    local sy = grid_y
    local sh = grid_h

    love.graphics.setColor(0.04, 0.07, 0.16, alpha * 0.96)
    rr(sx, sy, sidebar_w, sh, 8)
    love.graphics.setColor(0.18, 0.35, 0.70, alpha * 0.4)
    rl(sx, sy, sidebar_w, sh, 8)

    love.graphics.setFont(Fonts.get(15))
    love.graphics.setColor(0.3, 0.7, 1.0, alpha)
    love.graphics.printf("SYSTEM STATUS", sx + 14, sy + 16, sidebar_w - 28, "left")
    love.graphics.setColor(0.2, 0.4, 0.8, alpha * 0.4)
    love.graphics.rectangle("fill", sx + 14, sy + 40, sidebar_w - 28, 1)

    local status_y = sy + 54
    local current_style = Save.get("gameplay", "block_style") or "default"
    local active_shader = (ShaderManager.get_active_name and ShaderManager.get_active_name()) or (ShaderManager.enabled and "Enabled" or "Disabled")
    local sfx_vol = math.floor((Save.get("audio", "sfx_volume") or 0.8) * 100)
    local music_vol = math.floor((Save.get("audio", "music_volume") or 0.8) * 100)

    local info_items = {
        {"Block Style", current_style:upper()},
        {"Active Shader", active_shader},
        {"SFX Volume", sfx_vol .. "%"},
        {"Music Volume", music_vol .. "%"},
        {"Control Scheme", "Standard Keyboard"},
        {"Version", "TetriX 2.0.0"},
    }

    love.graphics.setFont(Fonts.get(11))
    for ii, item in ipairs(info_items) do
        local iy = status_y + (ii - 1) * 36
        love.graphics.setColor(0.5, 0.6, 0.75, alpha * 0.7)
        love.graphics.printf(item[1], sx + 14, iy, sidebar_w - 28, "left")
        love.graphics.setColor(1, 0.9, 0.3, alpha * 0.9)
        love.graphics.printf(item[2], sx + 14, iy + 16, sidebar_w - 28, "left")
    end
end

local function draw_focus_reticle(alpha)
    if Title.current_tab == 2 then return end
    if not Title.focus_box or not Title.focus_box.active then return end
    local fx, fy, fw, fh = Title.focus_box.x, Title.focus_box.y, Title.focus_box.w, Title.focus_box.h
    local pulse = (math.sin(Title.time * 6) + 1) * 0.5

    -- Glowing selection stroke
    love.graphics.setColor(0.20, 0.70, 1.00, alpha * (0.25 + pulse * 0.15))
    love.graphics.setLineWidth(2)
    rr(fx - 3, fy - 3, fw + 6, fh + 6, 10)

    love.graphics.setColor(1.00, 0.85, 0.30, alpha * (0.45 + pulse * 0.15))
    love.graphics.setLineWidth(2)
    local cs = 10
    love.graphics.line(fx - 4, fy + cs, fx - 4, fy - 4, fx + cs, fy - 4)
    love.graphics.line(fx + fw + 4 - cs, fy - 4, fx + fw + 4, fy - 4, fx + fw + 4, fy + cs)
    love.graphics.line(fx - 4, fy + fh - cs, fx - 4, fy + fh + 4, fx + cs, fy + fh + 4)
    love.graphics.line(fx + fw + 4 - cs, fy + fh + 4, fx + fw + 4, fy + fh + 4, fx + fw + 4, fy + fh - cs)
    love.graphics.setLineWidth(1)
end

local function draw_quit_modal(W, H, alpha)
    if not Title.quit_modal then return end

    -- Dim background curtain
    love.graphics.setColor(0.01, 0.02, 0.05, alpha * 0.82)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Centered modal card
    local mw, mh = 440, 230
    local mx = math.floor((W - mw) / 2)
    local my = math.floor((H - mh) / 2)

    love.graphics.setColor(0.06, 0.08, 0.16, alpha * 0.98)
    rr(mx, my, mw, mh, 16)
    love.graphics.setColor(1.0, 0.35, 0.20, alpha * 0.85)
    love.graphics.setLineWidth(2)
    rl(mx, my, mw, mh, 16)
    love.graphics.setLineWidth(1)

    -- Title
    love.graphics.setFont(Fonts.get(22))
    love.graphics.setColor(1.0, 0.40, 0.25, alpha)
    love.graphics.printf("⚠  QUIT TETRIX?", mx, my + 24, mw, "center")

    -- Description
    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(0.85, 0.88, 0.96, alpha * 0.9)
    love.graphics.printf("Are you sure you want to exit to desktop?", mx + 20, my + 72, mw - 40, "center")

    -- Buttons
    local bw, bh = 170, 48
    local gap = 20
    local b1_x = mx + math.floor((mw - (bw * 2 + gap)) / 2)
    local b2_x = b1_x + bw + gap
    local by = my + mh - 70

    -- Button 1: Yes, Quit
    local is_b1 = (Title.quit_sel == 1)
    if is_b1 then
        love.graphics.setColor(0.9, 0.2, 0.2, alpha * 0.95)
        rr(b1_x, by, bw, bh, 10)
        love.graphics.setColor(1, 0.7, 0.7, alpha)
        rl(b1_x, by, bw, bh, 10)
        love.graphics.setColor(1, 1, 1, alpha)
    else
        love.graphics.setColor(0.12, 0.14, 0.22, alpha * 0.75)
        rr(b1_x, by, bw, bh, 10)
        love.graphics.setColor(0.3, 0.35, 0.45, alpha * 0.5)
        rl(b1_x, by, bw, bh, 10)
        love.graphics.setColor(0.7, 0.75, 0.85, alpha * 0.7)
    end
    love.graphics.setFont(Fonts.get(15))
    love.graphics.printf("Yes, Quit", b1_x, by + 14, bw, "center")

    -- Button 2: No, Stay
    local is_b2 = (Title.quit_sel == 2)
    if is_b2 then
        love.graphics.setColor(0.2, 0.6, 1.0, alpha * 0.95)
        rr(b2_x, by, bw, bh, 10)
        love.graphics.setColor(0.7, 0.9, 1.0, alpha)
        rl(b2_x, by, bw, bh, 10)
        love.graphics.setColor(1, 1, 1, alpha)
    else
        love.graphics.setColor(0.12, 0.14, 0.22, alpha * 0.75)
        rr(b2_x, by, bw, bh, 10)
        love.graphics.setColor(0.3, 0.35, 0.45, alpha * 0.5)
        rl(b2_x, by, bw, bh, 10)
        love.graphics.setColor(0.7, 0.75, 0.85, alpha * 0.7)
    end
    love.graphics.setFont(Fonts.get(15))
    love.graphics.printf("No, Stay", b2_x, by + 14, bw, "center")
end

-- ─── Draw Main Screen ────────────────────────────────────────────────────────
function Title:draw()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    local alpha = Title.alpha
    local theme = Themes.get_ui_theme()

    -- 1. Background
    love.graphics.clear(0.02, 0.04, 0.10)
    draw_dot_grid(W, H, alpha)

    -- Falling block matrix columns in background
    for _, col in ipairs(COLUMNS) do
        local r, g, b = 0.2, 0.4, 0.8
        if col.type == "I" then r, g, b = 0.1, 0.8, 0.9
        elseif col.type == "O" then r, g, b = 0.9, 0.8, 0.1
        elseif col.type == "T" then r, g, b = 0.7, 0.2, 0.9 end

        for t = 0, col.trail_len - 1 do
            local trail_alpha = col.alpha * (1 - t / col.trail_len) * alpha * 0.4
            love.graphics.setColor(r, g, b, trail_alpha)
            local s = col.size
            love.graphics.rectangle("fill", col.x - s/2, col.y - t*(s+2), s, s, 3, 3)
        end
    end

    -- 2. Top Header Bar
    draw_top_header(W, alpha, Title.current_tab)

    -- 3. Category Tab Content
    local function draw_tab_content(tab_id, tab_alpha)
        if tab_id == 1 then
            draw_play_tab(W, H, tab_alpha, Title.time)
        elseif tab_id == 2 then
            draw_progress_tab(W, H, tab_alpha)
        elseif tab_id == 3 then
            draw_options_tab(W, H, tab_alpha)
        end
    end

    if Title.tab_trans.active then
        local t = math.min(1, Title.tab_trans.timer / Title.tab_trans.duration)
        local ease = 1 - math.pow(1 - t, 3)

        local dir = Title.tab_trans.direction
        local slide_dist = 160

        -- Outgoing Tab (carousel slide out + fade out)
        local prev_id = Title.tab_trans.prev_tab
        local alpha_out = (1 - t) * alpha
        local offset_out_x = -dir * ease * slide_dist

        love.graphics.push()
        love.graphics.translate(offset_out_x, 0)
        draw_tab_content(prev_id, alpha_out)
        love.graphics.pop()

        -- Incoming Tab (carousel slide in + fade in)
        local curr_id = Title.tab_trans.curr_tab
        local alpha_in = t * alpha
        local offset_in_x = dir * (1 - ease) * slide_dist

        love.graphics.push()
        love.graphics.translate(offset_in_x, 0)
        draw_tab_content(curr_id, alpha_in)
        love.graphics.pop()
    else
        draw_tab_content(Title.current_tab, alpha)
    end

    -- Smooth focus reticle overlay
    draw_focus_reticle(alpha)

    -- 4. Bottom Ticker Banner
    local bottom_bar_h = 58
    local by = H - bottom_bar_h
    love.graphics.setColor(0.03, 0.05, 0.12, alpha * 0.96)
    love.graphics.rectangle("fill", 0, by, W, bottom_bar_h)
    love.graphics.setColor(0.15, 0.35, 0.75, alpha * 0.6)
    love.graphics.rectangle("fill", 0, by, W, 2)

    love.graphics.setScissor(0, by + 2, W, bottom_bar_h - 2)
    love.graphics.setFont(Fonts.get(14))
    love.graphics.setColor(1, 0.82, 0.20, alpha * 0.9)
    local tip = Title.TIPS[Title.tip_idx]
    love.graphics.printf("★ " .. tip, W - Title.tip_scroll, by + 10, #tip * 10 + 40, "left")
    love.graphics.setScissor()

    -- Navigation Helper Footer Prompts
    local InputPrompts = require("lib.input_prompts")
    local fy = by + bottom_bar_h - 22
    local fx = math.floor((W - 640) / 2)

    InputPrompts.draw_action_icon("HOLD", fx, fy, 16)
    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(0.5, 0.6, 0.75, alpha)
    love.graphics.print("Switch Category", fx + 20, fy + 1)

    InputPrompts.draw_action_icon("MOVE_LEFT", fx + 150, fy, 16)
    InputPrompts.draw_action_icon("MOVE_RIGHT", fx + 170, fy, 16)
    love.graphics.print("Navigate", fx + 192, fy + 1)

    InputPrompts.draw_action_icon("ROTATE_CW", fx + 300, fy, 16)
    love.graphics.print("Select", fx + 322, fy + 1)

    InputPrompts.draw_action_icon("PAUSE", fx + 420, fy, 16)
    love.graphics.print("Quit", fx + 442, fy + 1)

    -- Quit Confirmation Modal Popup
    draw_quit_modal(W, H, alpha)
end

-- ─── Keyboard & Input Logic ───────────────────────────────────────────────────
function Title:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    -- 1. Quit Modal Dialog Active
    if Title.quit_modal then
        if key == "left" or key == "right" or key == "up" or key == "down" then
            Title.quit_sel = (Title.quit_sel == 1) and 2 or 1
            Audio.play("move")
        elseif key == "return" or key == "space" then
            Audio.play("rotate")
            if Title.quit_sel == 1 then
                love.event.quit()
            else
                Title.quit_modal = false
            end
        elseif key == "escape" then
            Audio.play("move")
            Title.quit_modal = false
        end
        return
    end

    -- 2. ESC key opens Quit Confirmation Prompt
    if key == "escape" then
        Title.quit_modal = true
        Title.quit_sel = 2
        Audio.play("move")
        return
    end

    -- Global Tab Switching (Q / E or 1 / 2 / 3 keys)
    if key == "q" or key == "l1" then
        local target = Title.current_tab - 1
        if target < 1 then target = #Title.TABS end
        Title.switch_tab(target)
        return
    elseif key == "e" or key == "r1" or key == "tab" then
        local target = Title.current_tab + 1
        if target > #Title.TABS then target = 1 end
        Title.switch_tab(target)
        return
    elseif key == "1" then
        Title.switch_tab(1)
        return
    elseif key == "2" then
        Title.switch_tab(2)
        return
    elseif key == "3" then
        Title.switch_tab(3)
        return
    end

    -- Tab 1: PLAY Category Controls
    if Title.current_tab == 1 then
        local sel = Title.selected_play

        if key == "right" then
            if sel >= 1 and sel <= 6 then
                if sel % 3 ~= 0 then
                    Title.selected_play = sel + 1
                else
                    -- Move to right sidebar (party play bots)
                    if sel == 3 then Title.selected_play = 7
                    elseif sel == 6 then Title.selected_play = 9 end
                end
            elseif sel >= 7 and sel <= 10 then
                Title.selected_play = 1  -- wrap back
            end
            Audio.play("move")

        elseif key == "left" then
            if sel >= 1 and sel <= 6 then
                if (sel - 1) % 3 ~= 0 then
                    Title.selected_play = sel - 1
                else
                    Title.selected_play = 7  -- wrap to sidebar
                end
            elseif sel >= 7 and sel <= 10 then
                -- Move left from sidebar to col 3
                if sel == 7 or sel == 8 then Title.selected_play = 3
                else Title.selected_play = 6 end
            end
            Audio.play("move")

        elseif key == "down" then
            if sel >= 1 and sel <= 3 then
                Title.selected_play = sel + 3
            elseif sel >= 4 and sel <= 6 then
                Title.selected_play = sel - 3
            elseif sel >= 7 and sel <= 9 then
                Title.selected_play = sel + 1
            elseif sel == 10 then
                Title.selected_play = 7
            end
            Audio.play("move")

        elseif key == "up" then
            if sel >= 4 and sel <= 6 then
                Title.selected_play = sel - 3
            elseif sel >= 1 and sel <= 3 then
                Title.selected_play = sel + 3
            elseif sel >= 8 and sel <= 10 then
                Title.selected_play = sel - 1
            elseif sel == 7 then
                Title.selected_play = 10
            end
            Audio.play("move")

        elseif key == "r" or key == "a" or key == "d" then
            -- Variant cycle for mode cards
            if sel >= 1 and sel <= #Title.MODE_CARDS then
                local card = Title.MODE_CARDS[sel]
                if #card.variants > 0 then
                    local vi = Title.variant_idx[sel] or 1
                    vi = (vi % #card.variants) + 1
                    Title.variant_idx[sel] = vi
                    Audio.play("move")
                end
            end

        elseif key == "return" or key == "space" then
            Audio.play("rotate")

            if sel <= 6 then
                local card = Title.MODE_CARDS[sel]
                local vi = Title.variant_idx[sel] or 1
                local config = card.variants[vi] and card.variants[vi].config or {}

                if card.id == "battle" then
                    state_mgr.switch_with_swoosh("battle", config.difficulty or "medium")
                elseif card.id == "battle_ultimate" then
                    state_mgr.switch_with_swoosh("battle", "boss")
                else
                    local Modes = require("lib.modes")
                    local mode = Modes.create(card.id, config)
                    state_mgr.switch_with_swoosh("gameplay", mode)
                end
            else
                -- Tetribot selected from sidebar
                local bot_idx = sel - 6
                local bot = Title.TETRIBOTS[bot_idx]
                if bot then
                    state_mgr.switch_with_swoosh("battle", bot.diff or "medium")
                end
            end
        end

    -- Tab 2: PROGRESS Category Controls
    elseif Title.current_tab == 2 then
        -- Stats dashboard tab view

    -- Tab 3: OPTIONS Category Controls
    elseif Title.current_tab == 3 then
        local sel = Title.selected_options

        if key == "down" then
            Title.selected_options = (sel % #Title.OPTION_CARDS) + 1
            Audio.play("move")
        elseif key == "up" then
            Title.selected_options = Title.selected_options - 1
            if Title.selected_options < 1 then Title.selected_options = #Title.OPTION_CARDS end
            Audio.play("move")
        elseif key == "return" or key == "space" then
            Audio.play("rotate")
            local opt = Title.OPTION_CARDS[sel]
            if opt.id == "settings" then
                state_mgr.push("settings")
            elseif opt.id == "unlockables" then
                state_mgr.push("unlockables")
            elseif opt.id == "highscores" then
                state_mgr.push("highscores")
            elseif opt.id == "shaders" then
                if ShaderManager.toggle then ShaderManager.toggle() else ShaderManager.enabled = not ShaderManager.enabled end
            elseif opt.id == "quit" then
                Title.quit_modal = true
                Title.quit_sel = 2
            end
        end
    end
end

return Title
