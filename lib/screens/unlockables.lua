local Themes = require("lib.themes")
local Audio = require("lib.audio")
local BlockStyles = require("lib.block_styles")

local Unlockables = {}

Unlockables.selected = 1
Unlockables.page = 1
Unlockables.items_per_page = 7

function Unlockables:enter(previous)
    Unlockables.selected = 1
    Unlockables.page = 1
end

function Unlockables:draw()
    local theme = Themes.get()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    love.graphics.clear(
        theme.background[1] * 0.7,
        theme.background[2] * 0.7,
        theme.background[3] * 0.7
    )

    local px = math.floor(W * 0.06)
    local py = math.floor(H * 0.04)
    local pw = W - px * 2
    local ph = H - py * 2

    love.graphics.setColor(0.03, 0.03, 0.08, 0.94)
    love.graphics.rectangle("fill", px, py, pw, ph, 16, 16)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 16, 16)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("BLOCK CUSTOMIZATION", px, py + 14, pw, "center")

    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.6, 0.7, 0.8)
    love.graphics.printf("Select a block style for your pieces", px, py + 44, pw, "center")

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.line(px + 12, py + 64, px + pw - 12, py + 64)

    local start_idx = (Unlockables.page - 1) * Unlockables.items_per_page + 1
    local end_idx = math.min(start_idx + Unlockables.items_per_page - 1, #BlockStyles.keys)
    local visible_count = end_idx - start_idx + 1

    local preview_h = 220
    local list_y = py + 78
    local list_h = ph - 140
    local row_h = math.floor(list_h / Unlockables.items_per_page)

    for i = start_idx, end_idx do
        local vi = i - start_idx + 1
        local y = list_y + (vi - 1) * row_h
        local style_key = BlockStyles.keys[i]
        local style_name = BlockStyles.names[i]
        local is_selected = (i == Unlockables.selected)
        local is_current = (style_key == BlockStyles.current_key)

        if is_selected then
            love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
            love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 6, 10, 10)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.08, 0.08, 0.15, 0.8)
            love.graphics.rectangle("fill", px + 12, y, pw - 24, row_h - 6, 10, 10)
            love.graphics.setColor(0.85, 0.85, 0.9)
        end

        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(style_name, px + 28, y + 10)

        if is_current then
            love.graphics.setColor(0.2, 1, 0.4, 0.9)
            love.graphics.setFont(love.graphics.newFont(11))
            love.graphics.printf("ACTIVE", px + 12, y + 10, pw - 36, "right")
        end

        if BlockStyles.sheet then
            local preview_x = px + 28
            local preview_y = y + 34
            local preview_scale = 0.38
            for pi = 1, 7 do
                local q = BlockStyles.get_cell_quad(style_key, pi)
                if q then
                    local offset_x = (pi - 1) * 70
                    love.graphics.setColor(1, 1, 1, is_selected and 1.0 or 0.6)
                    love.graphics.draw(BlockStyles.sheet, q, preview_x + offset_x, preview_y, 0, preview_scale, preview_scale)
                end
            end
        end
    end

    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.45, 0.45, 0.55)
    love.graphics.printf("UP/DOWN: Select  |  ENTER: Apply  |  ESC: Back",
        px, py + ph - 22, pw, "center")
end

function Unlockables:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "up" then
        Unlockables.selected = Unlockables.selected - 1
        if Unlockables.selected < 1 then Unlockables.selected = #BlockStyles.keys end
        Unlockables.page = math.ceil(Unlockables.selected / Unlockables.items_per_page)
        Audio.play("move")
    elseif key == "down" then
        Unlockables.selected = Unlockables.selected + 1
        if Unlockables.selected > #BlockStyles.keys then Unlockables.selected = 1 end
        Unlockables.page = math.ceil(Unlockables.selected / Unlockables.items_per_page)
        Audio.play("move")
    elseif key == "return" or key == "space" then
        local style_key = BlockStyles.keys[Unlockables.selected]
        BlockStyles.set_current(style_key)
        Audio.play("rotate")
    elseif key == "escape" then
        state_mgr.pop()
    end
end

return Unlockables
