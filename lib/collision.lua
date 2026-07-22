local Board = require("lib.board")
local Piece = require("lib.piece")

local Collision = {}

function Collision.any_overlap(board, piece_type, rotation, row, col)
    local cells = Piece.get_abs_cells(piece_type, rotation, row, col)
    for _, cell in ipairs(cells) do
        local r, c = cell[1], cell[2]
        if not Board.in_bounds(r, c) then
            return true
        end
        if Board.get_cell(board, r, c) then
            return true
        end
    end
    return false
end

function Collision.can_move(board, piece, dcol, drow)
    return not Collision.any_overlap(
        board, piece.type, piece.rotation,
        piece.row + drow, piece.col + dcol
    )
end

function Collision.is_grounded(board, piece)
    return Collision.any_overlap(board, piece.type, piece.rotation, piece.row + 1, piece.col)
end

return Collision
