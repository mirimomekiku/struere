-- lib/screens/mode_select.lua
-- Game mode picker screen – styled after Tetris Effect / PPT grid layout

local flux    = require("lib.vendor.flux")
local Themes  = require("lib.themes")
local Audio   = require("lib.audio")
local Save    = require("lib.save")
local constants = require("lib.constants")

local ModeSelect = {}

-- ─── Mode card definitions ────────────────────────────────────────────────────
local MODE_CARDS = {
    {
        id       = "marathon",
        label    = "MARATHON",
        icon     = "\226\151\136",  -- ◈
        sublabel = "Gravity Climb",
        desc     = "Stack under ever-increasing gravity.\nReach your line goal before the speed overwhelms you.",
        color    = {0.60, 0.15, 0.75},
        dark     = {0.22, 0.05, 0.30},
        border   = {0.80, 0.30, 1.00},
        variants = {
            { label = "150 Lines",  config = { line_goal = 150 } },
            { label = "200 Lines",  config = { line_goal = 200 } },
            { label = "Endless",    config = { line_goal = nil  } },
        },
        record_key = "marathon",
        record_fmt = function(r) return r and string.format("Score: %d  Lv.%d  Lines: %d", r.score or 0, r.level or 0, r.lines or 0) or "No record yet" end,
    },
    {
        id       = "sprint",
        label    = "SPRINT",
        icon     = "\226\167\151",  -- ⧗
        sublabel = "Time Attack",
        desc     = "Clear your line target as fast as possible.\nEvery millisecond counts. Track your PPS.",
        color    = {0.08, 0.65, 0.90},
        dark     = {0.03, 0.22, 0.38},
        border   = {0.25, 0.85, 1.00},
        variants = {
            { label = "40 Lines",  config = { line_goal = 40  } },
            { label = "100 Lines", config = { line_goal = 100 } },
        },
        record_key = "sprint",
        record_fmt = function(r) return r and string.format("Best: %02d:%05.2f", math.floor((r.time or 0)/60), (r.time or 0)%60) or "No record yet" end,
    },
    {
        id       = "blitz",
        label    = "BLITZ",
        icon     = "\226\151\183",  -- ◷
        sublabel = "2-Min Score Attack",
        desc     = "120 seconds. Maximum score.\nCombos, T-Spins, All Clears — use everything.",
        color    = {0.92, 0.50, 0.08},
        dark     = {0.38, 0.18, 0.03},
        border   = {1.00, 0.72, 0.20},
        variants = {},
        record_key = "blitz",
        record_fmt = function(r) return r and string.format("Score: %d", r.score or 0) or "No record yet" end,
    },
    {
        id       = "zen",
        label    = "ZEN",
        icon     = "\226\136\158",  -- ∞
        sublabel = "Stress-Free Practice",
        desc     = "No game over. Customize gravity.\nUndo misdrops. Play at your own pace.",
        color    = {0.10, 0.72, 0.62},
        dark     = {0.03, 0.28, 0.24},
        border   = {0.20, 0.95, 0.80},
        variants = {},
        record_key = nil,
        record_fmt = function(r) return "Infinite — no record" end,
    },
    {
        id       = "battle",
        label    = "VS CPU",
        icon     = "\226\154\148",  -- ⚔
        sublabel = "Battle Mode",
        desc     = "Face off against an AI opponent.\nSend garbage lines, survive attacks,\ntop out the CPU to win!",
        color    = {0.80, 0.12, 0.12},
        dark     = {0.32, 0.04, 0.04},
        border   = {1.00, 0.30, 0.30},
        variants = {
            { label = "Easy",   config = { difficulty = "easy"   } },
            { label = "Medium", config = { difficulty = "medium" } },
            { label = "Hard",   config = { difficulty = "hard"   } },
            { label = "Boss \226\152\133", config = { difficulty = "boss" } },
        },
        record_key = "battle",
        record_fmt = function(r) return r and ("Wins: " .. (r.wins or 0)) or "No wins yet" end,
    },
}

-- Tips rotated in the bottom bar
local TIPS = {
    "\226\152\133  T-Spin Double scores 2\195\151 in Blitz mode — set up T-Spin towers!",
    "\226\152\133  Sprint: focus on flat stacks and I-piece Tetrises for maximum speed.",
    "\226\152\133  Zen mode: press U to undo your last misdrop at any time.",
    "\226\152\133  Marathon: gravity doubles every 10 lines — survive to level 15!",
    "\226\152\133  Back-to-Back Tetris clears give a 1.5\195\151 score bonus.",
    "\226\152\133  All Clear (empty board) awards a huge bonus in any mode.",
    "\226\152\133  Hold the shift key to stash a piece — swap it back when needed.",
    "\226\152\133  VS CPU: clear 4 lines (Tetris) to send 4 garbage rows to the CPU!",
}

-- ─── State ────────────────────────────────────────────────────────────────────
ModeSelect.selected    = 1   -- which card (1..4)
ModeSelect.variant_idx = {}  -- per-mode selected variant index
ModeSelect.time        = 0
ModeSelect.alpha       = 0
ModeSelect.tip_idx     = 1
ModeSelect.tip_x       = 0
ModeSelect.tip_scroll  = 0
ModeSelect.sidebar_flash = 0  -- brief highlight when variant changes

-- Grid layout: 3 cols × 2 rows (positions 1..6, only 4 filled)
-- card at grid pos: row=ceil(i/3), col=((i-1)%3)+1
-- Navigation map: left/right within row, up/down between rows
local GRID_COLS = 3
local GRID_ROWS = 2

local function card_grid_pos(idx)
    local row = math.ceil(idx / GRID_COLS)
    local col = ((idx - 1) % GRID_COLS) + 1
    return row, col
end

function ModeSelect:enter(previous)
    ModeSelect.selected = 1
    ModeSelect.time     = 0
    ModeSelect.alpha    = 0
    ModeSelect.tip_scroll = 0
    ModeSelect.tip_idx  = 1

    -- Initialize variant indices
    for i, card in ipairs(MODE_CARDS) do
        if not ModeSelect.variant_idx[i] then
            ModeSelect.variant_idx[i] = 1
        end
    end

    flux.to(ModeSelect, 0.4, { alpha = 1 }):ease("quadout")
end

function ModeSelect:update(dt)
    ModeSelect.time = ModeSelect.time + dt
    flux.update(dt)

    -- Scroll bottom tip text
    local W = love.graphics.getWidth()
    ModeSelect.tip_scroll = ModeSelect.tip_scroll + 38 * dt
    local tip = TIPS[ModeSelect.tip_idx]
    local tip_width = #tip * 8  -- approx
    if ModeSelect.tip_scroll > W + tip_width then
        ModeSelect.tip_scroll = -W * 0.1
        ModeSelect.tip_idx = (ModeSelect.tip_idx % #TIPS) + 1
    end

    if ModeSelect.sidebar_flash > 0 then
        ModeSelect.sidebar_flash = ModeSelect.sidebar_flash - dt
    end
end

-- ─── Drawing helpers ──────────────────────────────────────────────────────────

local function rr(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r or 8, r or 8)
end

local function rl(x, y, w, h, r)
    love.graphics.rectangle("line", x, y, w, h, r or 8, r or 8)
end

local function draw_dot_grid(W, H, alpha)
    love.graphics.setColor(0.20, 0.38, 0.80, alpha * 0.18)
    local step = 24
    for x = 0, W, step do
        for y = 0, H, step do
            love.graphics.circle("fill", x, y, 1.5)
        end
    end
end

local function draw_mode_icon(icon_char, cx, cy, size, r, g, b, alpha)
    -- Glow circle behind icon
    love.graphics.setColor(r, g, b, alpha * 0.18)
    love.graphics.circle("fill", cx, cy, size * 0.62)
    love.graphics.setColor(r, g, b, alpha * 0.32)
    love.graphics.circle("fill", cx, cy, size * 0.45)

    -- Icon text
    love.graphics.setFont(love.graphics.newFont(math.floor(size * 0.68)))
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.printf(icon_char, cx - size, cy - size * 0.4, size * 2, "center")
end

local function draw_card(card, x, y, w, h, is_sel, alpha, time)
    local cr, cg, cb = card.color[1], card.color[2], card.color[3]
    local dr, dg, db = card.dark[1], card.dark[2], card.dark[3]
    local br, bg, bb = card.border[1], card.border[2], card.border[3]

    -- Outer glow when selected
    if is_sel then
        local pulse = math.sin(time * 3.5) * 0.25 + 0.75
        love.graphics.setColor(br, bg, bb, alpha * pulse * 0.55)
        rr(x - 5, y - 5, w + 10, h + 10, 14)
        love.graphics.setColor(br, bg, bb, alpha * pulse * 0.22)
        rr(x - 9, y - 9, w + 18, h + 18, 18)
    end

    -- Card base
    love.graphics.setColor(dr, dg, db, alpha * 0.96)
    rr(x, y, w, h, 12)

    -- Top color band (header)
    local band_h = math.floor(h * 0.30)
    love.graphics.setColor(cr * 0.75, cg * 0.75, cb * 0.75, alpha * (is_sel and 1.0 or 0.65))
    rr(x, y, w, band_h, 12)
    -- Hide rounded bottom of band
    love.graphics.rectangle("fill", x, y + band_h - 8, w, 8)

    -- Inner grid texture overlay (like the reference's dot grid inside cards)
    love.graphics.setColor(0, 0, 0, alpha * 0.18)
    rr(x, y, w, h, 12)
    local step = 12
    love.graphics.setColor(1, 1, 1, alpha * 0.03)
    for gx = x, x + w, step do
        for gy = y + band_h, y + h, step do
            love.graphics.circle("fill", gx, gy, 1.0)
        end
    end

    -- Mode label in header band
    love.graphics.setFont(love.graphics.newFont(13))
    love.graphics.setColor(1, 1, 1, alpha * (is_sel and 1.0 or 0.75))
    love.graphics.printf(card.label, x + 4, y + 7, w - 8, "left")

    -- Selected indicator (right side of header)
    if is_sel then
        love.graphics.setColor(1, 1, 0.3, alpha * 0.9)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("▶", x + 4, y + 7, w - 10, "right")
    end

    -- Big icon in center
    local icon_cx = x + w * 0.5
    local icon_cy = y + band_h + (h - band_h) * 0.42
    local icon_size = math.floor(math.min(w, h - band_h) * 0.34)
    draw_mode_icon(card.icon, icon_cx, icon_cy, icon_size, cr, cg, cb, alpha * (is_sel and 1.0 or 0.55))

    -- Sublabel below icon
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.setColor(cr, cg, cb, alpha * (is_sel and 0.95 or 0.5))
    love.graphics.printf(card.sublabel, x + 4, y + h - 22, w - 8, "center")

    -- Border
    love.graphics.setLineWidth(is_sel and 2.0 or 1.0)
    love.graphics.setColor(br, bg, bb, alpha * (is_sel and 0.9 or 0.22))
    rl(x, y, w, h, 12)
    love.graphics.setLineWidth(1)
end

local function draw_sidebar(card, variant_idx, best_record, x, y, w, h, alpha, time, flash)
    local cr, cg, cb = card.color[1], card.color[2], card.color[3]
    local dr, dg, db = card.dark[1], card.dark[2], card.dark[3]

    -- Sidebar panel
    love.graphics.setColor(0.04, 0.06, 0.12, alpha * 0.96)
    rr(x, y, w, h, 10)
    love.graphics.setColor(cr * 0.5, cg * 0.5, cb * 0.5, alpha * 0.4)
    rl(x, y, w, h, 10)

    local pad = 16
    local cy = y + pad

    -- Mode name header
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(cr, cg, cb, alpha)
    love.graphics.printf(card.label, x + pad, cy, w - pad*2, "left")
    cy = cy + 26

    love.graphics.setColor(cr * 0.6, cg * 0.6, cb * 0.6, alpha * 0.6)
    love.graphics.rectangle("fill", x + pad, cy, w - pad*2, 1)
    cy = cy + 8

    -- Description
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.78, 0.82, 0.90, alpha * 0.88)
    love.graphics.printf(card.desc, x + pad, cy, w - pad*2, "left")
    cy = cy + 54

    -- Best record
    love.graphics.setColor(cr * 0.6, cg * 0.6, cb * 0.6, alpha * 0.6)
    love.graphics.rectangle("fill", x + pad, cy, w - pad*2, 1)
    cy = cy + 8

    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.setColor(0.55, 0.65, 0.75, alpha * 0.75)
    love.graphics.printf("BEST RECORD", x + pad, cy, w - pad*2, "left")
    cy = cy + 16

    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 0.90, 0.25, alpha * 0.9)
    love.graphics.printf(card.record_fmt(best_record), x + pad, cy, w - pad*2, "left")
    cy = cy + 30

    -- Variant picker (if any)
    if #card.variants > 0 then
        love.graphics.setColor(cr * 0.6, cg * 0.6, cb * 0.6, alpha * 0.6)
        love.graphics.rectangle("fill", x + pad, cy, w - pad*2, 1)
        cy = cy + 8

        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.55, 0.65, 0.75, alpha * 0.75)
        love.graphics.printf("SELECT VARIANT", x + pad, cy, w - pad*2, "left")
        cy = cy + 16

        local flash_boost = math.max(0, flash) * 0.5
        for vi, variant in ipairs(card.variants) do
            local is_v = (vi == variant_idx)
            if is_v then
                love.graphics.setColor(cr, cg, cb, alpha * (0.88 + flash_boost))
                rr(x + pad - 4, cy - 2, w - pad*2 + 8, 24, 6)
                love.graphics.setColor(0, 0, 0, alpha)
            else
                love.graphics.setColor(0.12, 0.14, 0.22, alpha * 0.7)
                rr(x + pad - 4, cy - 2, w - pad*2 + 8, 24, 6)
                love.graphics.setColor(0.6, 0.6, 0.7, alpha * 0.7)
            end
            love.graphics.setFont(love.graphics.newFont(12))
            local vtext = (is_v and "▶ " or "  ") .. variant.label
            love.graphics.printf(vtext, x + pad, cy + 3, w - pad*2, "left")
            cy = cy + 28
        end

        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.setColor(0.45, 0.55, 0.65, alpha * 0.65)
        love.graphics.printf("← → to change", x + pad, cy + 4, w - pad*2, "left")
    end

    -- ENTER to start prompt (pulsing)
    local enter_pulse = math.sin(time * 5) * 0.2 + 0.8
    love.graphics.setFont(love.graphics.newFont(13))
    love.graphics.setColor(1, 1, 1, alpha * enter_pulse)
    love.graphics.printf("ENTER  —  Start Game", x + pad, y + h - 32, w - pad*2, "center")
    love.graphics.setColor(cr, cg, cb, alpha * enter_pulse * 0.6)
    love.graphics.rectangle("fill", x + pad, y + h - 18, w - pad*2, 2)
end

function ModeSelect:draw()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    local alpha = ModeSelect.alpha
    local theme = Themes.get()

    -- Background
    love.graphics.clear(0.02, 0.04, 0.10)
    draw_dot_grid(W, H, alpha)

    -- Top tab bar
    local tab_h = 50
    love.graphics.setColor(0.04, 0.06, 0.14, alpha * 0.98)
    love.graphics.rectangle("fill", 0, 0, W, tab_h)

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf("PLAY", 0, 13, W * 0.18, "center")
    love.graphics.setColor(0.2, 0.75, 1.0, alpha)
    love.graphics.rectangle("fill", W * 0.01, tab_h - 3, W * 0.16, 3)

    love.graphics.setFont(love.graphics.newFont(15))
    love.graphics.setColor(0.5, 0.55, 0.65, alpha * 0.7)
    love.graphics.printf("PROGRESS", W * 0.18, 15, W * 0.18, "center")
    love.graphics.setColor(0.35, 0.38, 0.48, alpha * 0.4)
    love.graphics.rectangle("fill", W * 0.18 + W*0.01, tab_h - 3, W * 0.16, 2)

    love.graphics.printf("OPTIONS", W * 0.36, 15, W * 0.18, "center")
    love.graphics.setColor(0.35, 0.38, 0.48, alpha * 0.4)
    love.graphics.rectangle("fill", W * 0.36 + W*0.01, tab_h - 3, W * 0.16, 2)

    -- ESC hint top right
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.45, 0.50, 0.60, alpha * 0.7)
    love.graphics.printf("ESC: Back", W - 100, 16, 90, "right")

    -- Divider
    love.graphics.setColor(0.15, 0.22, 0.38, alpha * 0.8)
    love.graphics.rectangle("fill", 0, tab_h, W, 2)

    -- Grid area
    local grid_margin   = 16
    local sidebar_w     = math.floor(W * 0.30)
    local sidebar_gap   = 14
    local bottom_bar_h  = 40
    local grid_x        = grid_margin
    local grid_y        = tab_h + grid_margin + 2
    local grid_w        = W - sidebar_w - sidebar_gap - grid_margin * 2
    local grid_h        = H - grid_y - bottom_bar_h - grid_margin

    local card_gap_x    = 12
    local card_gap_y    = 12
    local card_w        = math.floor((grid_w - card_gap_x * (GRID_COLS - 1)) / GRID_COLS)
    local card_h        = math.floor((grid_h - card_gap_y * (GRID_ROWS - 1)) / GRID_ROWS)

    -- Draw cards
    for i, card in ipairs(MODE_CARDS) do
        local row, col = card_grid_pos(i)
        local cx = grid_x + (col - 1) * (card_w + card_gap_x)
        local cy = grid_y + (row - 1) * (card_h + card_gap_y)
        draw_card(card, cx, cy, card_w, card_h, i == ModeSelect.selected, alpha, ModeSelect.time)
    end

    -- Draw empty card placeholders (grid positions 5..6 beyond mode count)
    for i = #MODE_CARDS + 1, GRID_COLS * GRID_ROWS do
        local row, col = card_grid_pos(i)
        local cx = grid_x + (col - 1) * (card_w + card_gap_x)
        local cy = grid_y + (row - 1) * (card_h + card_gap_y)
        love.graphics.setColor(0.05, 0.07, 0.14, alpha * 0.6)
        rr(cx, cy, card_w, card_h, 12)
        love.graphics.setColor(0.12, 0.16, 0.28, alpha * 0.35)
        rl(cx, cy, card_w, card_h, 12)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.setColor(0.20, 0.25, 0.40, alpha * 0.5)
        love.graphics.printf("COMING SOON", cx, cy + card_h * 0.45, card_w, "center")
    end

    -- Sidebar
    local sx = grid_x + grid_w + sidebar_gap
    local sy = grid_y
    local sh = grid_h
    local sel_card  = MODE_CARDS[ModeSelect.selected]
    local best_key  = sel_card.record_key
    local best_rec  = best_key and Save.get("high_scores", best_key) or nil
    draw_sidebar(sel_card, ModeSelect.variant_idx[ModeSelect.selected] or 1, best_rec,
                 sx, sy, sidebar_w - grid_margin, sh, alpha, ModeSelect.time, ModeSelect.sidebar_flash)

    -- Bottom tip bar
    local by = H - bottom_bar_h
    love.graphics.setColor(0.04, 0.06, 0.14, alpha * 0.95)
    love.graphics.rectangle("fill", 0, by, W, bottom_bar_h)
    love.graphics.setColor(0.12, 0.20, 0.40, alpha * 0.6)
    love.graphics.rectangle("fill", 0, by, W, 2)

    love.graphics.setScissor(0, by + 2, W, bottom_bar_h - 2)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 0.85, 0.25, alpha * 0.85)
    local tip = TIPS[ModeSelect.tip_idx]
    love.graphics.printf(tip, W - ModeSelect.tip_scroll, by + 12, #tip * 8, "left")
    love.graphics.setScissor()

    -- Footer nav hint
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.setColor(0.40, 0.45, 0.58, alpha * 0.7)
    love.graphics.printf("← → ↑ ↓ Navigate    LEFT/RIGHT on sidebar: Change Variant    ENTER: Start", 0, by + bottom_bar_h - 18, W, "center")
end

function ModeSelect:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "escape" then
        state_mgr.pop()
        return
    end

    -- Grid navigation
    local sel = ModeSelect.selected
    local row, col = card_grid_pos(sel)

    if key == "right" then
        local new_col = col + 1
        if new_col > GRID_COLS then new_col = 1 end
        local new_idx = (row - 1) * GRID_COLS + new_col
        if new_idx <= #MODE_CARDS then
            ModeSelect.selected = new_idx
            Audio.play("move")
        end

    elseif key == "left" then
        local new_col = col - 1
        if new_col < 1 then new_col = GRID_COLS end
        local new_idx = (row - 1) * GRID_COLS + new_col
        if new_idx <= #MODE_CARDS then
            ModeSelect.selected = new_idx
            Audio.play("move")
        end

    elseif key == "down" then
        local new_row = row + 1
        if new_row > GRID_ROWS then new_row = 1 end
        local new_idx = (new_row - 1) * GRID_COLS + col
        if new_idx > #MODE_CARDS then new_idx = #MODE_CARDS end
        ModeSelect.selected = new_idx
        Audio.play("move")

    elseif key == "up" then
        local new_row = row - 1
        if new_row < 1 then new_row = GRID_ROWS end
        local new_idx = (new_row - 1) * GRID_COLS + col
        if new_idx > #MODE_CARDS then new_idx = #MODE_CARDS end
        ModeSelect.selected = new_idx
        Audio.play("move")

    elseif key == "a" or key == "kp4" then
        -- Variant left
        local card = MODE_CARDS[sel]
        if #card.variants > 0 then
            local vi = ModeSelect.variant_idx[sel] or 1
            vi = vi - 1
            if vi < 1 then vi = #card.variants end
            ModeSelect.variant_idx[sel] = vi
            ModeSelect.sidebar_flash = 0.4
            Audio.play("move")
        end

    elseif key == "d" or key == "kp6" then
        -- Variant right
        local card = MODE_CARDS[sel]
        if #card.variants > 0 then
            local vi = ModeSelect.variant_idx[sel] or 1
            vi = vi + 1
            if vi > #card.variants then vi = 1 end
            ModeSelect.variant_idx[sel] = vi
            ModeSelect.sidebar_flash = 0.4
            Audio.play("move")
        end

    elseif key == "return" or key == "space" then
        Audio.play("rotate")
        local card = MODE_CARDS[sel]

        -- Build config from selected variant (if any)
        local config = {}
        if #card.variants > 0 then
            local vi = ModeSelect.variant_idx[sel] or 1
            config = card.variants[vi].config or {}
        end

        if card.id == "battle" then
            -- VS CPU → push dedicated battle screen
            state_mgr.switch("battle", config.difficulty or "medium")
        else
            local Modes = require("lib.modes")
            local mode = Modes.create(card.id, config)
            state_mgr.switch("gameplay", mode)
        end
    end
end

return ModeSelect
