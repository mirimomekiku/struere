local Themes = require("lib.themes")
local Piece = require("lib.piece")
local Board = require("lib.board")
local GameplayOpts = require("lib.gameplay_opts")

local Renderer = {}

-- ─── Block Drawing Primitives ──────────────────────────────────────────────

-- Fancy filled block: beveled borders + glossy highlight
function Renderer.draw_filled(x, y, size, color)
    local r, g, b = color[1]/255, color[2]/255, color[3]/255

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", x+2, y+2, size, size)

    -- Main fill
    love.graphics.setColor(r * 0.8, g * 0.8, b * 0.8)
    love.graphics.rectangle("fill", x, y, size, size)

    -- Inner bright face
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x+1, y+1, size-4, size-4)

    -- Top highlight bevel
    love.graphics.setColor(math.min(r+0.45,1), math.min(g+0.45,1), math.min(b+0.45,1), 0.9)
    love.graphics.rectangle("fill", x+2, y+2, size-5, 3)

    -- Left highlight bevel
    love.graphics.setColor(math.min(r+0.3,1), math.min(g+0.3,1), math.min(b+0.3,1), 0.6)
    love.graphics.rectangle("fill", x+2, y+2, 3, size-5)

    -- Bottom shadow bevel
    love.graphics.setColor(r*0.4, g*0.4, b*0.4, 0.9)
    love.graphics.rectangle("fill", x+2, y+size-4, size-4, 3)

    -- Right shadow bevel
    love.graphics.setColor(r*0.4, g*0.4, b*0.4, 0.7)
    love.graphics.rectangle("fill", x+size-4, y+2, 3, size-4)

    -- Glossy top-left cap
    love.graphics.setColor(1, 1, 1, 0.22)
    love.graphics.rectangle("fill", x+3, y+3, size-8, math.floor(size*0.3))

    -- Thin outer border
    love.graphics.setColor(r*0.3, g*0.3, b*0.3, 0.8)
    love.graphics.rectangle("line", x, y, size, size)
end

-- Flat/minimalist block: clean fill with subtle inner highlight
function Renderer.draw_flat(x, y, size, color)
    local r, g, b = color[1]/255, color[2]/255, color[3]/255
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x, y, size, size)
    love.graphics.setColor(r*0.6, g*0.6, b*0.6)
    love.graphics.rectangle("line", x, y, size, size)
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle("fill", x+2, y+2, size-4, math.floor(size*0.35))
end

-- Glass block: translucent with frosted highlight
function Renderer.draw_glass(x, y, size, color)
    local r, g, b = color[1]/255, color[2]/255, color[3]/255

    -- Translucent base
    love.graphics.setColor(r, g, b, 0.5)
    love.graphics.rectangle("fill", x, y, size, size)

    -- Inner glow
    love.graphics.setColor(r, g, b, 0.25)
    love.graphics.rectangle("fill", x+1, y+1, size-2, size-2)

    -- Frosted highlight top
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.rectangle("fill", x+2, y+2, size-5, math.floor(size*0.42))

    -- Rim
    love.graphics.setColor(r*0.5, g*0.5, b*0.5, 0.3)
    love.graphics.rectangle("fill", x+2, y+size-4, size-4, 3)

    -- Glass border
    love.graphics.setColor(r, g, b, 0.5)
    love.graphics.rectangle("line", x, y, size, size)
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", x+1, y+1, size-2, size-2)
end

-- Neon/cyberpunk block: glowing outer bloom + bright core
function Renderer.draw_neon(x, y, size, color)
    local r, g, b = color[1]/255, color[2]/255, color[3]/255

    -- Outer glow layers (larger, dimmer)
    love.graphics.setColor(r, g, b, 0.12)
    love.graphics.rectangle("fill", x-3, y-3, size+6, size+6)
    love.graphics.setColor(r, g, b, 0.20)
    love.graphics.rectangle("fill", x-2, y-2, size+4, size+4)
    love.graphics.setColor(r, g, b, 0.35)
    love.graphics.rectangle("fill", x-1, y-1, size+2, size+2)

    -- Dark inner core
    love.graphics.setColor(r*0.25, g*0.25, b*0.25)
    love.graphics.rectangle("fill", x, y, size, size)

    -- Bright neon face fill
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x+2, y+2, size-4, size-4)

    -- Glossy line near top
    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.rectangle("fill", x+3, y+3, size-8, 2)

    -- Bright neon border
    love.graphics.setColor(r, g, b, 0.85)
    love.graphics.rectangle("line", x, y, size, size)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", x+1, y+1, size-2, size-2)
end

function Renderer.draw_block(x, y, size, color, style)
    if style == "flat" then
        Renderer.draw_flat(x, y, size, color)
    elseif style == "glass" then
        Renderer.draw_glass(x, y, size, color)
    elseif style == "neon" then
        Renderer.draw_neon(x, y, size, color)
    else
        Renderer.draw_filled(x, y, size, color)
    end
end

-- ─── Grid & Board ─────────────────────────────────────────────────────────

function Renderer.draw_grid(board_x, board_y, cols, rows, cell_size, theme, custom_opacity, custom_pattern)
    local opacity = custom_opacity or (GameplayOpts and GameplayOpts.grid_opacity) or 0.6
    local pattern = custom_pattern or (GameplayOpts and GameplayOpts.grid_pattern) or "lines"

    if opacity > 0 then
        if pattern == "check" then
            for r = 0, rows - 1 do
                for c = 0, cols - 1 do
                    if (r + c) % 2 == 0 then
                        love.graphics.setColor(theme.grid_color[1], theme.grid_color[2], theme.grid_color[3], opacity * 0.3)
                        love.graphics.rectangle("fill", board_x + c * cell_size, board_y + r * cell_size, cell_size, cell_size)
                    end
                end
            end
        elseif pattern == "dots" then
            love.graphics.setColor(theme.grid_color[1], theme.grid_color[2], theme.grid_color[3], opacity)
            for r = 0, rows do
                for c = 0, cols do
                    love.graphics.circle("fill", board_x + c * cell_size, board_y + r * cell_size, 2)
                end
            end
        else -- "lines"
            love.graphics.setColor(theme.grid_color[1], theme.grid_color[2], theme.grid_color[3], opacity)
            for r = 0, rows do
                love.graphics.line(board_x, board_y + r * cell_size,
                                   board_x + cols * cell_size, board_y + r * cell_size)
            end
            for c = 0, cols do
                love.graphics.line(board_x + c * cell_size, board_y,
                                   board_x + c * cell_size, board_y + rows * cell_size)
            end
        end
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3])
    love.graphics.rectangle("line", board_x - 1, board_y - 1,
                             cols * cell_size + 2, rows * cell_size + 2)
    love.graphics.setLineWidth(1)
end

function Renderer.draw_board_cell(value, x, y, cell_size, theme)
    if value then
        local color = theme.colors[value]
        Renderer.draw_block(x, y, cell_size, color, theme.block_style)
    else
        love.graphics.setColor(theme.grid_color[1], theme.grid_color[2], theme.grid_color[3], 0.15)
        love.graphics.rectangle("fill", x, y, cell_size, cell_size)
    end
end

function Renderer.draw_ghost(piece, ghost_row, board_x, board_y, cell_size, theme, custom_style)
    local style = custom_style or (GameplayOpts and GameplayOpts.ghost_style) or "tint"
    if GameplayOpts and not GameplayOpts.ghost_enabled then return end
    if style == "disabled" then return end

    local cells = Piece.get_abs_cells(piece.type, piece.rotation, ghost_row, piece.col)
    local color = theme.colors[piece.type]
    local r, g, b = color[1]/255, color[2]/255, color[3]/255

    for _, cell in ipairs(cells) do
        local x = board_x + (cell[2] - 1) * cell_size
        local y = board_y + (cell[1] - 21) * cell_size

        if style == "outline" then
            love.graphics.setLineWidth(2)
            love.graphics.setColor(r, g, b, 0.85)
            love.graphics.rectangle("line", x + 1, y + 1, cell_size - 2, cell_size - 2)
            love.graphics.setLineWidth(1)
        elseif style == "solid" then
            love.graphics.setColor(r, g, b, 0.35)
            love.graphics.rectangle("fill", x, y, cell_size, cell_size)
            love.graphics.setColor(1, 1, 1, 0.25)
            love.graphics.rectangle("line", x, y, cell_size, cell_size)
        else -- "tint"
            love.graphics.setColor(r, g, b, theme.ghost_alpha or 0.25)
            love.graphics.rectangle("fill", x + 1, y + 1, cell_size - 2, cell_size - 2)
            love.graphics.setColor(r, g, b, (theme.ghost_alpha or 0.25) * 2)
            love.graphics.rectangle("line", x, y, cell_size, cell_size)
        end
    end
end

function Renderer.draw_piece(piece, board_x, board_y, cell_size, theme)
    local cells = Piece.get_abs_cells(piece.type, piece.rotation, piece.row, piece.col)
    local color = theme.colors[piece.type]
    for _, cell in ipairs(cells) do
        local x = board_x + (cell[2] - 1) * cell_size
        local y = board_y + (cell[1] - 21) * cell_size
        Renderer.draw_block(x, y, cell_size, color, theme.block_style)
    end
end

function Renderer.draw_mini_piece(ptype, x, y, cell_size, theme, box_w, box_h)
    if not ptype then return end
    local cells = Piece.get_cells(ptype, 0)
    local color = theme.colors[ptype]
    -- Find bounding box to center mini piece
    local min_c, max_c = math.huge, -math.huge
    local min_r, max_r = math.huge, -math.huge
    for _, cell in ipairs(cells) do
        if cell[1] < min_c then min_c = cell[1] end
        if cell[1] > max_c then max_c = cell[1] end
        if cell[2] < min_r then min_r = cell[2] end
        if cell[2] > max_r then max_r = cell[2] end
    end
    local piece_w = (max_c - min_c + 1) * cell_size
    local piece_h = (max_r - min_r + 1) * cell_size

    local off_x = box_w and math.floor((box_w - piece_w) / 2) or 0
    local off_y = box_h and math.floor((box_h - piece_h) / 2) or 0

    for _, cell in ipairs(cells) do
        Renderer.draw_block(
            x + off_x + (cell[1] - min_c) * cell_size,
            y + off_y + (cell[2] - min_r) * cell_size,
            cell_size, color, theme.block_style
        )
    end
end

function Renderer.draw_board(board, board_x, board_y, cell_size, theme)
    for r = 21, 40 do
        for c = 1, 10 do
            local cell = Board.get_cell(board, r, c)
            local x = board_x + (c - 1) * cell_size
            local y = board_y + (r - 21) * cell_size
            Renderer.draw_board_cell(cell, x, y, cell_size, theme)
        end
    end
end

return Renderer
