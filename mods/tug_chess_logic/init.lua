local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_logic = {

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
                {name = "Q"},
                {name = "K"},
                {name = "B"},
                {name = "N"},
                {name = "R"},
            }
        elseif r == 8 then
            board[8] = {
                {name = "r"},
                {name = "n"},
                {name = "b"},
                {name = "q"},
                {name = "k"},
                {name = "b"},
                {name = "n"},
                {name = "r"},
            }
        else
            for _ = 1, 8 do
                table.insert(board[r], {name = ""})
            end
        end
    end
    board.player = 1
    return board
end

-- TODOS

function tug_chess_logic.has_won(board)
    -- RETURNS 0 - No winner, 1 - White won, 2 - Black won
end

function tug_chess_logic.get_next_boards(board, id)
    -- RETURNS All next boards for a current player
end

cases = {
    [""] = function(r, c, white)
        return {}
    end,
    ["p"] = function(r, c, white)
        local moves = {}
        if white then
            table.insert(moves, {x = r + 1, z = c})
            if r == 1 then
                table.insert(moves, {x = 3, z = c})
            end
        else
            table.insert(moves, {x = r - 1, z = c})
            if r == 6 then
                table.insert(moves, {x =4, z = c})
            end
        end
        return moves
    end,
    ["n"] = function(r, c, white)
        return {}
    end,
    ["b"] = function(r, c, white)
        return {}
    end,
    ["r"] = function(r, c, white)
        return {}
    end,
    ["q"] = function(r, c, white)
        return {}
    end,
    ["k"] = function(r, c, white)
        return {}
    end,
}

function tug_chess_logic.get_moves(r, c)
    -- the moves are absolute
    local name = tug_gamestate.g.current_board[r][c].name
    return cases[string.lower(name)](r, c, string.upper(name) == name)
end

-- UTILS

-- engine_next_board(board [curr board], id [player id of the engine]) - returns the next board for the engine move
