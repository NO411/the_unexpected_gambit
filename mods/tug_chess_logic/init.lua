local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_logic = {}
tug_chess_logic.pieces = {
    "king",
    "queen",
    "rook",
    "bishop",
    "knight",
    "pawn",
}

function tug_chess_logic.get_default_board()
    local board = {}
    for r = 1, 8 do
        board[r] = {}
        if r == 2 or r == 7 then
            for _ = 1, 8 do
                table.insert(board[r], {name = r == 2 and "P" or "p"})
            end
        elseif r == 1 then
            board[1] = {
                {name = "R"},
                {name = "N"},
                {name = "B"},
                {name = "K"},
                {name = "Q"},
                {name = "B"},
                {name = "N"},
                {name = "R"},
            }
        elseif r == 8 then
            board[8] = {
                {name = "r"},
                {name = "n"},
                {name = "b"},
                {name = "k"},
                {name = "q"},
                {name = "b"},
                {name = "n"},
                {name = "r"},
            }
        else
            for _ = 1, 8 do
                table.insert(board[r], nil)
            end
        end
    end
    return board
end

-- TODOS

function tug_chess_logic.has_won(board)
    -- RETURNS 0 - No winner, 1 - White won, 2 - Black won
end

function tug_chess_logic.get_next_boards(board, id)
    -- RETURNS All next boards for a current player
end

-- board = {
--  {nil, {name = ""}}
--  ...
-- }

-- UTILS

-- engine_next_board(board [curr board], id [player id of the engine]) - returns the next board for the engine move
