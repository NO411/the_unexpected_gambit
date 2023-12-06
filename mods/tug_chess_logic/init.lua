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

-- TODOS

function has_won(board)
    -- RETURNS 0 - No winner, 1 - White won, 2 - Black won
end

function get_next_boards(board, id)
    -- RETURNS All next boards for a current player
end

-- board = {
--  {nil, {""}}
--  ...
-- }

-- UTILS

-- engine_next_board(board [curr board], id [player id of the engine]) - returns the next board for the engine move