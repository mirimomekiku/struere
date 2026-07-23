local flux = require("lib.vendor.flux")

local Piece = {}

local PIECES = {
    I = {
        [0] = {{0,0}, {1,0}, {2,0}, {3,0}},
        [1] = {{0,0}, {0,1}, {0,2}, {0,3}},
        [2] = {{0,0}, {1,0}, {2,0}, {3,0}},
        [3] = {{0,0}, {0,1}, {0,2}, {0,3}},
    },
    O = {
        [0] = {{0,0}, {1,0}, {0,1}, {1,1}},
        [1] = {{0,0}, {1,0}, {0,1}, {1,1}},
        [2] = {{0,0}, {1,0}, {0,1}, {1,1}},
        [3] = {{0,0}, {1,0}, {0,1}, {1,1}},
    },
    T = {
        [0] = {{0,0}, {1,0}, {2,0}, {1,1}},
        [1] = {{0,0}, {0,1}, {0,2}, {1,1}},
        [2] = {{0,1}, {1,1}, {2,1}, {1,0}},
        [3] = {{1,0}, {1,1}, {1,2}, {0,1}},
    },
    S = {
        [0] = {{1,0}, {2,0}, {0,1}, {1,1}},
        [1] = {{0,0}, {0,1}, {1,1}, {1,2}},
        [2] = {{1,0}, {2,0}, {0,1}, {1,1}},
        [3] = {{0,0}, {0,1}, {1,1}, {1,2}},
    },
    Z = {
        [0] = {{0,0}, {1,0}, {1,1}, {2,1}},
        [1] = {{1,0}, {0,1}, {1,1}, {0,2}},
        [2] = {{0,0}, {1,0}, {1,1}, {2,1}},
        [3] = {{1,0}, {0,1}, {1,1}, {0,2}},
    },
    J = {
        [0] = {{0,0}, {0,1}, {1,1}, {2,1}},
        [1] = {{0,0}, {1,0}, {0,1}, {0,2}},
        [2] = {{0,0}, {1,0}, {2,0}, {2,1}},
        [3] = {{1,0}, {1,1}, {0,2}, {1,2}},
    },
    L = {
        [0] = {{2,0}, {0,1}, {1,1}, {2,1}},
        [1] = {{0,0}, {0,1}, {0,2}, {1,2}},
        [2] = {{0,0}, {1,0}, {2,0}, {0,1}},
        [3] = {{0,0}, {1,0}, {1,1}, {1,2}},
    },
}

local JLSTZ_KICKS = {
    ["0>1"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},
    ["1>2"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}},
    ["2>3"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},
    ["3>0"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},
    ["1>0"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}},
    ["2>1"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},
    ["3>2"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},
    ["0>3"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},
}

local I_KICKS = {
    ["0>1"] = {{0,0}, {-2,0}, {1,0}, {-2,1}, {1,-2}},
    ["1>2"] = {{0,0}, {-1,0}, {2,0}, {-1,-2}, {2,1}},
    ["2>3"] = {{0,0}, {2,0}, {-1,0}, {2,-1}, {-1,2}},
    ["3>0"] = {{0,0}, {1,0}, {-2,0}, {1,2}, {-2,-1}},
    ["1>0"] = {{0,0}, {2,0}, {-1,0}, {2,-1}, {-1,2}},
    ["2>1"] = {{0,0}, {1,0}, {-2,0}, {1,2}, {-2,-1}},
    ["3>2"] = {{0,0}, {-2,0}, {1,0}, {-2,1}, {1,-2}},
    ["0>3"] = {{0,0}, {-1,0}, {2,0}, {-1,-2}, {2,1}},
}

-- Extra edge nudge offsets tried after standard SRS kicks fail
-- Allows rotation next to left/right walls and floor
local EDGE_NUDGES = {{1,0}, {-1,0}, {2,0}, {-2,0}, {0,-1}, {1,-1}, {-1,-1}}

function Piece.new(piece_type, row, col)
    return {
        type = piece_type,
        rotation = 0,
        row = row or 1,
        col = col or 4,
        anim_row = row or 1,
        anim_col = col or 4,
    }
end

function Piece.get_cells(piece_type, rotation)
    return PIECES[piece_type][rotation]
end

function Piece.get_abs_cells(piece_type, rotation, row, col)
    local cells = PIECES[piece_type][rotation]
    local result = {}
    for _, offset in ipairs(cells) do
        table.insert(result, {row + offset[2], col + offset[1]})
    end
    return result
end

function Piece.get_kicks(piece_type, from_rot, to_rot)
    if piece_type == "O" then
        return {{0, 0}}
    end
    local key = from_rot .. ">" .. to_rot
    if piece_type == "I" then
        return I_KICKS[key]
    end
    return JLSTZ_KICKS[key]
end

function Piece.try_rotate(board, piece, direction)
    local Collision = require("lib.collision")
    local from = piece.rotation
    local to = (from + direction) % 4

    -- ── SRS disabled: only try basic zero-offset rotation ────────────────────
    local ok_gp, GameplayOpts = pcall(require, "lib.gameplay_opts")
    if ok_gp and GameplayOpts.srs_enabled == false then
        if not Collision.any_overlap(board, piece.type, to, piece.row, piece.col) then
            piece.rotation = to
            flux.to(piece, 0.08, { anim_col = piece.col, anim_row = piece.row }):ease("quadout")
            return true
        end
        return false
    end

    -- ── SRS enabled: full wall-kick table ────────────────────────────────────
    local kicks = Piece.get_kicks(piece.type, from, to)

    -- Try standard SRS kicks first
    for _, kick in ipairs(kicks) do
        local new_col = piece.col + kick[1]
        local new_row = piece.row + kick[2]
        if not Collision.any_overlap(board, piece.type, to, new_row, new_col) then
            piece.rotation = to
            piece.col = new_col
            piece.row = new_row
            flux.to(piece, 0.08, { anim_col = new_col, anim_row = new_row }):ease("quadout")
            return true
        end
    end

    -- Fallback edge-nudge: try shifting away from walls/floor
    for _, nudge in ipairs(EDGE_NUDGES) do
        local new_col = piece.col + nudge[1]
        local new_row = piece.row + nudge[2]
        if not Collision.any_overlap(board, piece.type, to, new_row, new_col) then
            piece.rotation = to
            piece.col = new_col
            piece.row = new_row
            flux.to(piece, 0.08, { anim_col = new_col, anim_row = new_row }):ease("quadout")
            return true
        end
    end

    return false
end

function Piece.move(piece, d_row, d_col)
    piece.row = piece.row + d_row
    piece.col = piece.col + d_col
    flux.to(piece, 0.05, { anim_col = piece.col, anim_row = piece.row }):ease("quadout")
end

return Piece
