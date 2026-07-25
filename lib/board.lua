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
    local write_r = constants.TOTAL_ROWS
    local cleared_count = 0
    local cleared_rows = {}

    -- Single pass from bottom to top
    for r = constants.TOTAL_ROWS, 1, -1 do
        local full = true
        for c = 1, constants.GRID_COLS do
            if not Board.get_cell(board, r, c) then
                full = false
                break
            end
        end
        if full then
            cleared_count = cleared_count + 1
            table.insert(cleared_rows, r)
        else
            if write_r ~= r then
                for c = 1, constants.GRID_COLS do
                    Board.set_cell(board, write_r, c, Board.get_cell(board, r, c))
                end
            end
            write_r = write_r - 1
        end
    end

    -- Clear remaining top rows
    for r = write_r, 1, -1 do
        for c = 1, constants.GRID_COLS do
            Board.set_cell(board, r, c, nil)
        end
    end

    return cleared_count, cleared_rows
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

-- Get the row index (1..40) of the highest occupied block on the board
function Board.get_highest_block_row(board)
    if not board then return constants.TOTAL_ROWS + 1 end
    for r = 1, constants.TOTAL_ROWS do
        for c = 1, constants.GRID_COLS do
            if Board.get_cell(board, r, c) then
                return r
            end
        end
    end
    return constants.TOTAL_ROWS + 1
end

-- Get danger level (0.0 to 1.0) based on how close highest block is to top
function Board.get_danger_level(board)
    local highest = Board.get_highest_block_row(board)
    -- Visible grid rows are 21..40. Danger zone starts at row <= 25 (15+ blocks high)
    if highest <= 25 then
        local level = math.min(1.0, (26 - highest) / 5.0)
        return level
    end
    return 0.0
end

return Board
