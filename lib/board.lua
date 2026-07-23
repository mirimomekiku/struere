local constants = require("lib.constants")
local batteries = require("lib.vendor.batteries")

local Board = {}

function Board.new()
    local matrix = batteries.matrix.new(constants.GRID_COLS, constants.TOTAL_ROWS, nil)
    return { matrix = matrix }
end

function Board.in_bounds(row, col)
    return row >= 1 and row <= constants.TOTAL_ROWS
        and col >= 1 and col <= constants.GRID_COLS
end

function Board.get_cell(board, row, col)
    if Board.in_bounds(row, col) then
        return board.matrix:get(col, row)
    end
    return nil
end

function Board.set_cell(board, row, col, value)
    if Board.in_bounds(row, col) then
        board.matrix:set(col, row, value)
    end
end

function Board.place_piece(board, piece)
    local Piece = require("lib.piece")
    local cells = Piece.get_abs_cells(piece.type, piece.rotation, piece.row, piece.col)
    for _, cell in ipairs(cells) do
        Board.set_cell(board, cell[1], cell[2], piece.type)
    end
end

function Board.clear_lines(board)
    local cleared = {}
    for r = constants.TOTAL_ROWS, constants.BUFFER_ROWS + 1, -1 do
        local full = true
        for c = 1, constants.GRID_COLS do
            if not Board.get_cell(board, r, c) then
                full = false
                break
            end
        end
        if full then
            table.insert(cleared, r)
        end
    end

    for _, r in ipairs(cleared) do
        -- Shift rows above 'r' down
        for y = r, 2, -1 do
            for x = 1, constants.GRID_COLS do
                local prev = board.matrix:get(x, y - 1)
                board.matrix:set(x, y, prev)
            end
        end
        -- Clear top row
        for x = 1, constants.GRID_COLS do
            board.matrix:set(x, 1, nil)
        end
    end

    return #cleared
end

function Board.get_ghost_row(board, piece)
    local Piece = require("lib.piece")
    local row = piece.row
    while true do
        local next_row = row + 1
        local cells = Piece.get_abs_cells(piece.type, piece.rotation, next_row, piece.col)
        local valid = true
        for _, cell in ipairs(cells) do
            if not Board.in_bounds(cell[1], cell[2]) then
                valid = false
                break
            end
            if Board.get_cell(board, cell[1], cell[2]) then
                valid = false
                break
            end
        end
        if not valid then break end
        row = next_row
    end
    return row
end

-- All-clear detection: returns true if visible board (rows 21..40) is completely empty
function Board.is_empty(board)
    for r = constants.BUFFER_ROWS + 1, constants.TOTAL_ROWS do
        for c = 1, constants.GRID_COLS do
            if Board.get_cell(board, r, c) then return false end
        end
    end
    return true
end

-- Deep copy board for undo snapshots
function Board.deep_copy(board)
    local batteries = require("lib.vendor.batteries")
    local new_matrix = batteries.matrix.new(constants.GRID_COLS, constants.TOTAL_ROWS, nil)
    for c = 1, constants.GRID_COLS do
        for r = 1, constants.TOTAL_ROWS do
            new_matrix:set(c, r, board.matrix:get(c, r))
        end
    end
    return { matrix = new_matrix }
end

return Board
