local flux = require("lib.vendor.flux")
local Themes = require("lib.themes")
local Audio = require("lib.audio")
local Save = require("lib.save")
local constants = require("lib.constants")
local Renderer = require("lib.renderer")
local Piece = require("lib.piece")

local Title = {}

Title.selected = 1
Title.menu_items = {
    { label = "PLAY GAME",          action = "play",       icon = "▶" },
    { label = "SETTINGS & SHADERS", action = "settings",   icon = "⚙" },
    { label = "HIGH SCORES",        action = "highscores", icon = "★" },
    { label = "QUIT",               action = "quit",       icon = "✕" },
}

Title.bg_blocks = {}
Title.piece_types = {"I", "O", "T", "S", "Z", "J", "L"}

-- Anim state
Title.title_alpha = 0
Title.menu_alpha  = 0
Title.time        = 0

-- Scanline flicker
Title.scanline_y  = 0

local COLUMNS = {}

function Title:enter(previous)
    Title.selected = 1
    Title.bg_blocks = {}
    Title.title_alpha = 0
    Title.menu_alpha  = 0
    Title.time        = 0

    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    -- Spawn raining columns of blocks (like a Matrix-style tetromino rain)
    COLUMNS = {}
    local col_count = math.floor(W / 32)
    for i = 1, col_count do
        table.insert(COLUMNS, {
            x     = (i - 0.5) * 32,
            y     = math.random(-H, 0),
            speed = math.random(40, 130),
            type  = Title.piece_types[math.random(#Title.piece_types)],
            size  = 26,
            alpha = math.random(8, 30) / 100,
            trail_len = math.random(3, 9),
        })
    end

    -- Fade-in tweens
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

function Title:draw()
    local theme = Themes.get()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    -- ── Background ────────────────────────────────────────────────────────
    love.graphics.clear(
        theme.background[1] * 0.6,
        theme.background[2] * 0.6,
        theme.background[3] * 0.7
    )

    -- Tetromino rain columns
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
            -- Inner highlight
            love.graphics.setColor(1, 1, 1, trail_alpha * 0.3)
            love.graphics.rectangle("fill", col.x - s/2 + 2, col.y - t*(s+2) + 2, s-4, 4)
        end
    end

    -- Vertical gradient vignette overlay
    love.graphics.setColor(theme.background[1]*0.5, theme.background[2]*0.5, theme.background[3]*0.5, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- ── Title Card ────────────────────────────────────────────────────────
    local card_w = math.floor(W * 0.60)
    local card_h = 130
    local card_x = math.floor((W - card_w) / 2)
    local card_y = math.floor(H * 0.08)

    -- Glowing behind title
    love.graphics.setColor(theme.accent[1] * 0.3, theme.accent[2] * 0.3, theme.accent[3] * 0.3, Title.title_alpha * 0.6)
    love.graphics.rectangle("fill", card_x - 10, card_y - 10, card_w + 20, card_h + 20, 18, 18)

    -- Main title card
    love.graphics.setColor(0.02, 0.02, 0.06, Title.title_alpha * 0.92)
    love.graphics.rectangle("fill", card_x, card_y, card_w, card_h, 14, 14)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], Title.title_alpha * 0.85)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", card_x, card_y, card_w, card_h, 14, 14)
    love.graphics.setLineWidth(1)

    -- Scanline shimmer inside title card
    local scan_y = (Title.time * 60) % card_h
    love.graphics.setColor(1, 1, 1, 0.04)
    love.graphics.rectangle("fill", card_x, card_y + scan_y, card_w, 3)

    -- Title text – "T E T R I X" with letter spacing
    love.graphics.setFont(love.graphics.newFont(52))
    love.graphics.setColor(1.0, 0.88, 0.12, Title.title_alpha)
    love.graphics.printf("T E T R I X", card_x, card_y + 16, card_w, "center")

    love.graphics.setFont(love.graphics.newFont(13))
    love.graphics.setColor(0.6, 0.85, 1.0, Title.title_alpha * 0.9)
    love.graphics.printf("✦ REFINED RETRO ARCADE EDITION ✦", card_x, card_y + 90, card_w, "center")

    -- ── Menu Card ─────────────────────────────────────────────────────────
    local menu_item_h = math.floor(H * 0.072)
    local menu_pad = 12
    local menu_w = math.floor(W * 0.38)
    local menu_h = #Title.menu_items * (menu_item_h + menu_pad) + menu_pad
    local menu_x = math.floor((W - menu_w) / 2)
    local menu_y = card_y + card_h + math.floor(H * 0.05)

    love.graphics.setColor(0.03, 0.03, 0.08, Title.menu_alpha * 0.9)
    love.graphics.rectangle("fill", menu_x, menu_y, menu_w, menu_h, 14, 14)
    love.graphics.setColor(0.25, 0.25, 0.4, Title.menu_alpha * 0.5)
    love.graphics.rectangle("line", menu_x, menu_y, menu_w, menu_h, 14, 14)

    for i, item in ipairs(Title.menu_items) do
        local iy = menu_y + menu_pad + (i - 1) * (menu_item_h + menu_pad)
        local sel = (i == Title.selected)
        local pulse = (math.sin(Title.time * 5) * 0.1 + 0.9)

        if sel then
            -- Gradient pill highlight
            love.graphics.setColor(
                theme.accent[1] * pulse,
                theme.accent[2] * pulse,
                theme.accent[3] * pulse,
                Title.menu_alpha * 0.92)
            love.graphics.rectangle("fill", menu_x + 10, iy, menu_w - 20, menu_item_h, 10, 10)
            -- Left accent bar
            love.graphics.setColor(1, 1, 1, Title.menu_alpha * 0.8)
            love.graphics.rectangle("fill", menu_x + 10, iy + 6, 4, menu_item_h - 12, 2, 2)
            love.graphics.setColor(0, 0, 0, Title.menu_alpha)
        else
            love.graphics.setColor(0.1, 0.1, 0.2, Title.menu_alpha * 0.7)
            love.graphics.rectangle("fill", menu_x + 10, iy, menu_w - 20, menu_item_h, 10, 10)
            love.graphics.setColor(0.78, 0.78, 0.88, Title.menu_alpha)
        end

        love.graphics.setFont(love.graphics.newFont(16))
        local label = item.icon .. "  " .. item.label
        love.graphics.printf(label, menu_x + 10, iy + math.floor(menu_item_h / 2) - 9, menu_w - 20, "center")
    end

    -- ── Footer ────────────────────────────────────────────────────────────
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.5, 0.5, 0.65, Title.menu_alpha * 0.8)
    love.graphics.printf("↑↓ Navigate    ENTER Select    ESC Quit", 0, H - 22, W, "center")
end

function Title:keypressed(key)
    local state_mgr = require("lib.state_mgr")
    if key == "up" then
        Title.selected = Title.selected - 1
        if Title.selected < 1 then Title.selected = #Title.menu_items end
        Audio.play("move")
    elseif key == "down" then
        Title.selected = Title.selected + 1
        if Title.selected > #Title.menu_items then Title.selected = 1 end
        Audio.play("move")
    elseif key == "return" or key == "space" then
        Audio.play("rotate")
        local act = Title.menu_items[Title.selected].action
        if act == "play" then
            state_mgr.switch("gameplay")
        elseif act == "settings" then
            state_mgr.push("settings")
        elseif act == "highscores" then
            state_mgr.push("highscores")
        elseif act == "quit" then
            love.event.quit()
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

return Title
