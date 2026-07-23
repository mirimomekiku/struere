-- lib/screens/unlockables.lua
-- Customization Screen: Dual tab picker for [1] BLOCK STYLES and [2] VISUAL THEMES

local Themes      = require("lib.themes")
local Audio       = require("lib.audio")
local BlockStyles = require("lib.block_styles")
local Save        = require("lib.save")
local Fonts       = require("lib.fonts")

local Unlockables = {}

Unlockables.tab      = 1  -- 1 = BLOCK STYLES, 2 = VISUAL THEMES
Unlockables.selected = 1
Unlockables.tabs     = {"BLOCK STYLES", "VISUAL THEMES"}

function Unlockables:enter(previous)
    Unlockables.tab      = 1
    Unlockables.selected = 1
end

function Unlockables:draw()
    local theme = Themes.get_ui_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(0.02, 0.03, 0.08)

    local px = math.floor(W * 0.06)
    local py = math.floor(H * 0.04)
    local pw = W - px * 2
    local ph = H - py * 2

    -- Modal Container
    love.graphics.setColor(0.04, 0.04, 0.10, 0.95)
    love.graphics.rectangle("fill", px, py, pw, ph, 16, 16)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 16, 16)
    love.graphics.setLineWidth(1)

    -- Header
    love.graphics.setFont(Fonts.get(22))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CUSTOMIZATION", px, py + 14, pw, "center")

    -- Tab Headers
    local tab_w = math.floor((pw - 32) / 2)
    for i, title in ipairs(Unlockables.tabs) do
        local tx = px + 12 + (i - 1) * (tab_w + 8)
        local ty = py + 48
        local is_curr = (i == Unlockables.tab)
        if is_curr then
            love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
            love.graphics.rectangle("fill", tx, ty, tab_w, 30, 6, 6)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.12, 0.14, 0.22, 0.8)
            love.graphics.rectangle("fill", tx, ty, tab_w, 30, 6, 6)
            love.graphics.setColor(0.7, 0.7, 0.8)
        end
        love.graphics.setFont(Fonts.get(11))
        love.graphics.printf(title, tx, ty + 8, tab_w, "center")
    end

    love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
    love.graphics.line(px + 12, py + 86, px + pw - 12, py + 86)

    local list_y = py + 94
    local list_h = ph - 130

    if Unlockables.tab == 1 then
        -- ── TAB 1: BLOCK STYLES ─────────────────────────────────────────────
        local items = BlockStyles.keys
        local row_h = math.floor(list_h / #items)

        for i, key in ipairs(items) do
            local y = list_y + (i - 1) * row_h
            local name = BlockStyles.names[i] or key
            local is_selected = (i == Unlockables.selected)
            local is_current  = (key == BlockStyles.current_key)

            if is_selected then
                love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
                love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 4, 8, 8)
                love.graphics.setColor(0, 0, 0)
            else
                love.graphics.setColor(0.08, 0.09, 0.16, 0.8)
                love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 4, 8, 8)
                love.graphics.setColor(0.85, 0.85, 0.9)
            end

            love.graphics.setFont(Fonts.get(13))
            love.graphics.print(name, px + 24, y + 8)

            if is_current then
                love.graphics.setColor(0.2, 1.0, 0.4, 0.95)
                love.graphics.setFont(Fonts.get(11))
                love.graphics.printf("ACTIVE", px + 12, y + 8, pw - 36, "right")
            end

            -- Sprite sheet cell previews
            if BlockStyles.sheet then
                local preview_x = px + 24
                local preview_y = y + 28
                local preview_scale = 0.35
                for pi = 1, 7 do
                    local q = BlockStyles.get_cell_quad(key, pi)
                    if q then
                        local offset_x = (pi - 1) * 60
                        love.graphics.setColor(1, 1, 1, is_selected and 1.0 or 0.65)
                        love.graphics.draw(BlockStyles.sheet, q, preview_x + offset_x, preview_y, 0, preview_scale, preview_scale)
                    end
                end
            end
        end

    else
        -- ── TAB 2: VISUAL THEMES ────────────────────────────────────────────
        local items = Themes.order
        local row_h = math.floor(list_h / #items)

        for i, key in ipairs(items) do
            local y = list_y + (i - 1) * row_h
            local tdata = Themes.list[key]
            local name = tdata and tdata.name or key
            local is_selected = (i == Unlockables.selected)
            local is_current  = (key == Themes.current_name)

            if is_selected then
                love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
                love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 4, 8, 8)
                love.graphics.setColor(0, 0, 0)
            else
                love.graphics.setColor(0.08, 0.09, 0.16, 0.8)
                love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 4, 8, 8)
                love.graphics.setColor(0.85, 0.85, 0.9)
            end

            love.graphics.setFont(Fonts.get(13))
            love.graphics.print(name, px + 24, y + 6)

            if is_current then
                love.graphics.setColor(0.2, 1.0, 0.4, 0.95)
                love.graphics.setFont(Fonts.get(11))
                love.graphics.printf("ACTIVE", px + 12, y + 6, pw - 36, "right")
            end

            -- Color palette swatches preview (I, O, T, S, Z, J, L)
            if tdata and tdata.colors then
                local sx = px + 200
                local sy = y + 7
                local sw = 18
                local sh = 16
                local p_keys = {"I", "O", "T", "S", "Z", "J", "L"}
                for pi, pk in ipairs(p_keys) do
                    local c = tdata.colors[pk]
                    if c then
                        love.graphics.setColor(c[1]/255, c[2]/255, c[3]/255, 0.95)
                        love.graphics.rectangle("fill", sx + (pi - 1) * (sw + 4), sy, sw, sh, 3, 3)
                        love.graphics.setColor(0, 0, 0, 0.4)
                        love.graphics.rectangle("line", sx + (pi - 1) * (sw + 4), sy, sw, sh, 3, 3)
                    end
                end
            end
        end
    end

    -- Bottom instructions
    love.graphics.setFont(Fonts.get(10))
    love.graphics.setColor(0.45, 0.45, 0.58)
    love.graphics.printf("TAB / L / R: Switch Tab  |  UP/DOWN: Select  |  ENTER: Apply Theme/Style  |  ESC: Back",
        px, py + ph - 20, pw, "center")
end

function Unlockables:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "tab" or key == "l" or key == "r" then
        Unlockables.tab = (Unlockables.tab == 1) and 2 or 1
        Unlockables.selected = 1
        Audio.play("move")
        return
    end

    local max_items = (Unlockables.tab == 1) and #BlockStyles.keys or #Themes.order

    if key == "up" then
        Unlockables.selected = Unlockables.selected - 1
        if Unlockables.selected < 1 then Unlockables.selected = max_items end
        Audio.play("move")
    elseif key == "down" then
        Unlockables.selected = Unlockables.selected + 1
        if Unlockables.selected > max_items then Unlockables.selected = 1 end
        Audio.play("move")
    elseif key == "return" or key == "space" then
        if Unlockables.tab == 1 then
            local style_key = BlockStyles.keys[Unlockables.selected]
            BlockStyles.set_current(style_key)
            Save.set("settings", "block_style", style_key)
        else
            local theme_key = Themes.order[Unlockables.selected]
            Themes.set(theme_key)
            Save.set("settings", "theme", theme_key)
        end
        Save.save()
        Audio.play("rotate")
    elseif key == "escape" then
        state_mgr.pop()
    end
end

return Unlockables
