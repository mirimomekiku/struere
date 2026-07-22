local Save = require("lib.save")

local BlockStyles = {}

BlockStyles.sheet = nil
BlockStyles.quads = {}
BlockStyles.block_quads = {}

BlockStyles.names = {
    "Classic Style",
    "Retro Pixel Art",
    "Modern Glass",
    "Glow Neon",
    "Steampunk Metal",
    "Geometric Flat",
    "Roguelike Special",
}

BlockStyles.keys = {
    "classic", "retro_pixel", "modern_glass",
    "glow_neon", "steampunk", "geometric_flat", "roguelike",
}

BlockStyles.cols = 7
BlockStyles.rows = 7

BlockStyles.current_key = "classic"

function BlockStyles.load()
    BlockStyles.sheet = love.graphics.newImage("assets/blocks/block_1.png")
    BlockStyles.sheet:setFilter("nearest", "nearest")

    local sw = BlockStyles.sheet:getWidth()
    local sh = BlockStyles.sheet:getHeight()
    local cell_w = math.floor(sw / BlockStyles.cols)
    local cell_h = math.floor(sh / BlockStyles.rows)

    BlockStyles.quads = {}
    BlockStyles.block_quads = {}

    for row = 0, BlockStyles.rows - 1 do
        local style_key = BlockStyles.keys[row + 1]
        BlockStyles.quads[style_key] = {}
        BlockStyles.block_quads[style_key] = {}

        for col = 0, BlockStyles.cols - 1 do
            local qx = col * cell_w
            local qy = row * cell_h
            BlockStyles.quads[style_key][col + 1] = love.graphics.newQuad(qx, qy, cell_w, cell_h, sw, sh)

            local bw = math.floor(cell_w * 0.22)
            local bh = math.floor(cell_h * 0.42)
            local bx = qx + math.floor(cell_w * 0.05)
            local by = qy + math.floor(cell_h * 0.08)
            BlockStyles.block_quads[style_key][col + 1] = love.graphics.newQuad(bx, by, bw, bh, sw, sh)
        end
    end

    BlockStyles.current_key = Save.get("settings", "block_style") or "classic"
end

function BlockStyles.get_block_quad(style_key, piece_index)
    local quads = BlockStyles.block_quads[style_key]
    if quads and quads[piece_index] then
        return quads[piece_index]
    end
    return nil
end

function BlockStyles.get_cell_quad(style_key, piece_index)
    local quads = BlockStyles.quads[style_key]
    if quads and quads[piece_index] then
        return quads[piece_index]
    end
    return nil
end

function BlockStyles.set_current(style_key)
    for _, k in ipairs(BlockStyles.keys) do
        if k == style_key then
            BlockStyles.current_key = style_key
            Save.set("settings", "block_style", style_key)
            Save.save()

            if style_key ~= "classic" then
                local Themes = require("lib.themes")
                Themes.current.block_style = "sprite"
            else
                local Themes = require("lib.themes")
                Themes.current.block_style = "filled"
            end
            return true
        end
    end
    return false
end

function BlockStyles.get_current()
    return BlockStyles.current_key
end

function BlockStyles.get_current_name()
    for i, k in ipairs(BlockStyles.keys) do
        if k == BlockStyles.current_key then
            return BlockStyles.names[i]
        end
    end
    return "Classic Style"
end

function BlockStyles.get_piece_index(piece_type)
    local map = { I = 1, O = 2, T = 3, S = 4, Z = 5, J = 6, L = 7 }
    return map[piece_type] or 1
end

return BlockStyles
