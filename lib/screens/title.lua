local flux = require("lib.vendor.flux")
local Themes = require("lib.themes")
local Audio = require("lib.audio")
local Save = require("lib.save")
local constants = require("lib.constants")
local Renderer = require("lib.renderer")
local Piece = require("lib.piece")
local Fonts = require("lib.fonts")

local Title = {}

Title.selected = 1

Title.cards = {
    {
        label = "PLAY",
        sublabel = "Solo Arcade",
        action = "play",
        color = {0.15, 0.70, 0.35},
        dark_color = {0.08, 0.45, 0.22},
        icon_char = "▶",
        desc = "Start a new game in Marathon, Sprint, or Blitz mode!",
    },
    {
        label = "SETTINGS",
        sublabel = "Options & Shaders",
        action = "settings",
        color = {0.18, 0.45, 0.82},
        dark_color = {0.10, 0.28, 0.55},
        icon_char = "⚙",
        desc = "Configure controls, shaders, audio, and display.",
    },
    {
        label = "BLOCKS",
        sublabel = "Customization",
        action = "unlockables",
        color = {0.60, 0.25, 0.80},
        dark_color = {0.38, 0.15, 0.52},
        icon_char = "◆",
        desc = "Unlock and select different block styles.",
    },
    {
        label = "SCORES",
        sublabel = "High Scores",
        action = "highscores",
        color = {0.90, 0.50, 0.12},
        dark_color = {0.60, 0.32, 0.08},
        icon_char = "★",
        desc = "View your best records across all modes.",
    },
    {
        label = "QUIT",
        sublabel = "Exit Game",
        action = "quit",
        color = {0.85, 0.22, 0.28},
        dark_color = {0.58, 0.14, 0.18},
        icon_char = "✕",
        desc = "Close TetriX and return to desktop.",
    },
}

Title.piece_types = {"I", "O", "T", "S", "Z", "J", "L"}
Title.title_alpha = 0
Title.menu_alpha = 0
Title.time = 0

local COLUMNS = {}

function Title:enter(previous)
    Title.selected = 1
    Title.title_alpha = 0
    Title.menu_alpha = 0
    Title.time = 0

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    COLUMNS = {}
    local col_count = math.floor(W / 32)
    for i = 1, col_count do
        table.insert(COLUMNS, {
            x = (i - 0.5) * 32,
            y = math.random(-H, 0),
            speed = math.random(40, 130),
            type = Title.piece_types[math.random(#Title.piece_types)],
            size = 26,
            alpha = math.random(8, 30) / 100,
            trail_len = math.random(3, 9),
        })
    end

    flux.to(Title, 0.8, { title_alpha = 1 }):ease("quadout"):oncomplete(function()
        flux.to(Title, 0.5, { menu_alpha = 1 }):ease("quadout")
    end)
end

function Title:update(dt)
    Title.time = Title.time + dt
    flux.update(dt)

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    for _, col in ipairs(COLUMNS) do
        col.y = col.y + col.speed * dt
        if col.y > H + 60 then
            col.y = -60
            col.x = math.random(0, W)
            col.type = Title.piece_types[math.random(#Title.piece_types)]
            col.speed = math.random(40, 130)
        end
    end
end

local function get_piece_color_normalized(ptype, theme)
    local c = theme.colors[ptype] or {200, 200, 200}
    return c[1]/255, c[2]/255, c[3]/255
end

local function draw_rounded_rect(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r, r)
end

local function draw_card(card, x, y, w, h, is_selected, alpha, time)
    local pulse = is_selected and (math.sin(time * 4) * 0.06 + 1.0) or 1.0
    local cr, cg, cb = card.color[1], card.color[2], card.color[3]
    local dr, dg, db = card.dark_color[1], card.dark_color[2], card.dark_color[3]

    love.graphics.push()

    if is_selected then
        love.graphics.setColor(cr * 0.4, cg * 0.4, cb * 0.4, alpha * 0.7)
        draw_rounded_rect(x - 4, y - 4, w + 8, h + 8, 14)
    end

    love.graphics.setColor(dr, dg, db, alpha * 0.95)
    draw_rounded_rect(x, y, w, h, 12)

    love.graphics.setColor(cr * pulse, cg * pulse, cb * pulse, alpha * 0.85)
    draw_rounded_rect(x, y, w, h * 0.55, 12)

    love.graphics.setColor(cr * 0.7, cg * 0.7, cb * 0.7, alpha * 0.5)
    draw_rounded_rect(x, y + h * 0.45, w, h * 0.12, 0)

    love.graphics.setColor(1, 1, 1, alpha * 0.95)
    love.graphics.setFont(Fonts.get(20))
    love.graphics.printf(card.label, x, y + 10, w, "center")

    love.graphics.setColor(1, 1, 1, alpha * 0.7)
    love.graphics.setFont(Fonts.get(11))
    love.graphics.printf(card.sublabel, x, y + 36, w, "center")

    love.graphics.setColor(0, 0, 0, alpha * 0.85)
    love.graphics.setFont(Fonts.get(9))
    local desc_lines = {}
    for line in card.desc:gmatch("[^\n]+") do
        table.insert(desc_lines, line)
    end
    for i, line in ipairs(desc_lines) do
        love.graphics.printf(line, x + 8, y + h * 0.58 + (i - 1) * 13, w - 16, "center")
    end

    if is_selected then
        local sel_pulse = math.sin(time * 6) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, sel_pulse * alpha)
        love.graphics.setFont(Fonts.get(10))
        love.graphics.printf("▶ PRESS ENTER", x, y + h - 18, w, "center")
    end

    love.graphics.pop()
end

function Title:draw()
    local theme = Themes.get_ui_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(
        theme.background[1] * 0.6,
        theme.background[2] * 0.6,
        theme.background[3] * 0.7
    )

    for _, col in ipairs(COLUMNS) do
        local r, g, b = get_piece_color_normalized(col.type, theme)
        for t = 0, col.trail_len - 1 do
            local trail_alpha = col.alpha * (1 - t / col.trail_len)
            love.graphics.setColor(r, g, b, trail_alpha)
            local s = col.size
            love.graphics.rectangle("fill",
                col.x - s / 2,
                col.y - t * (s + 2),
                s, s, 4, 4)
            love.graphics.setColor(1, 1, 1, trail_alpha * 0.3)
            love.graphics.rectangle("fill", col.x - s/2 + 2, col.y - t*(s+2) + 2, s-4, 4)
        end
    end

    love.graphics.setColor(theme.background[1]*0.5, theme.background[2]*0.5, theme.background[3]*0.5, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local header_h = 70
    love.graphics.setColor(0.92, 0.35, 0.10, Title.title_alpha * 0.95)
    draw_rounded_rect(0, 0, W, header_h, 0)

    love.graphics.setColor(1, 1, 1, Title.title_alpha * 0.08)
    for dx = 0, W, 8 do
        love.graphics.rectangle("fill", dx, 0, 4, header_h)
    end

    love.graphics.setFont(Fonts.get(38))
    love.graphics.setColor(1, 1, 1, Title.title_alpha)
    love.graphics.printf("MAIN MENU", 0, 16, W, "center")

    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(1, 1, 1, Title.title_alpha * 0.7)
    love.graphics.printf("TETRIX  -  REFINED RETRO ARCADE", 0, 52, W, "center")

    local grid_top = header_h + 20
    local grid_bottom = H - 50
    local grid_h = grid_bottom - grid_top

    local card_w = math.floor(W * 0.28)
    local card_h = math.floor(grid_h * 0.55)
    local gap_x = 18
    local gap_y = 16

    local row1_count = 3
    local row1_total_w = row1_count * card_w + (row1_count - 1) * gap_x
    local row1_start_x = math.floor((W - row1_total_w) / 2)
    local row1_y = grid_top

    local row2_count = 2
    local row2_total_w = row2_count * card_w + (row2_count - 1) * gap_x
    local row2_start_x = math.floor((W - row2_total_w) / 2)
    local row2_y = row1_y + card_h + gap_y

    local positions = {
        {x = row1_start_x,                          y = row1_y},
        {x = row1_start_x + card_w + gap_x,         y = row1_y},
        {x = row1_start_x + (card_w + gap_x) * 2,   y = row1_y},
        {x = row2_start_x,                          y = row2_y},
        {x = row2_start_x + card_w + gap_x,         y = row2_y},
    }

    for i, card in ipairs(Title.cards) do
        if positions[i] then
            local is_sel = (i == Title.selected)
            draw_card(card, positions[i].x, positions[i].y, card_w, card_h, is_sel, Title.menu_alpha, Title.time)
        end
    end

    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(0.5, 0.5, 0.65, Title.menu_alpha * 0.8)
    love.graphics.printf("← → ↑ ↓ Navigate    ENTER Select    ESC Quit", 0, H - 28, W, "center")
end

function Title:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "right" then
        Title.selected = Title.selected + 1
        if Title.selected > #Title.cards then Title.selected = 1 end
        Audio.play("move")
    elseif key == "left" then
        Title.selected = Title.selected - 1
        if Title.selected < 1 then Title.selected = #Title.cards end
        Audio.play("move")
    elseif key == "down" then
        if Title.selected <= 3 then
            Title.selected = Title.selected + 3
            if Title.selected > #Title.cards then Title.selected = #Title.cards end
        else
            Title.selected = 1
        end
        Audio.play("move")
    elseif key == "up" then
        if Title.selected > 3 then
            Title.selected = Title.selected - 3
        else
            Title.selected = #Title.cards
        end
        Audio.play("move")
    elseif key == "return" or key == "space" then
        Audio.play("rotate")
        local card = Title.cards[Title.selected]
        if card.action == "play" then
            state_mgr.push("mode_select")
        elseif card.action == "settings" then
            state_mgr.push("settings")
        elseif card.action == "unlockables" then
            state_mgr.push("unlockables")
        elseif card.action == "highscores" then
            state_mgr.push("highscores")
        elseif card.action == "quit" then
            love.event.quit()
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

return Title
