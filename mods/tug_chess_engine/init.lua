local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_engine = {}

local win_score = 10000

local piece_values_lookup = {
    ["p"] = 100,
    ["n"] = 320,
    ["b"] = 330,
    ["r"] = 500,
    ["q"] = 900,
    ["k"] = 0,
}

local piece_square_tables = {
    ["p"] = {
        {  0,  0,  0,  0,  0,  0,  0,  0},
        { 50, 50, 50, 50, 50, 50, 50, 50},
        { 10, 10, 20, 30, 30, 20, 10, 10},
        {  5,  5, 10, 25, 25, 10,  5,  5},
        {  0,  0,  0, 20, 20,  0,  0,  0},
        {  5, -5,-10,  0,  0,-10, -5,  5},
        {  5, 10, 10,-20,-20, 10, 10,  5},
        {  0,  0,  0,  0,  0,  0,  0,  0},
    },
    ["n"] = {
        {-50,-40,-30,-30,-30,-30,-40,-50},
        {-40,-20,  0,  0,  0,  0,-20,-40},
        {-30,  0, 10, 15, 15, 10,  0,-30},
        {-30,  5, 15, 20, 20, 15,  5,-30},
        {-30,  0, 15, 20, 20, 15,  0,-30},
        {-30,  5, 10, 15, 15, 10,  5,-30},
        {-40,-20,  0,  5,  5,  0,-20,-40},
        {-50,-40,-30,-30,-30,-30,-40,-50},
    },
    ["b"] = {
        {-20,-10,-10,-10,-10,-10,-10,-20},
        {-10,  0,  0,  0,  0,  0,  0,-10},
        {-10,  0,  5, 10, 10,  5,  0,-10},
        {-10,  5,  5, 10, 10,  5,  5,-10},
        {-10,  0, 10, 10, 10, 10,  0,-10},
        {-10, 10, 10, 10, 10, 10, 10,-10},
        {-10,  5,  0,  0,  0,  0,  5,-10},
        {-20,-10,-10,-10,-10,-10,-10,-20},
    },
    ["r"] = {
        {  0,  0,  0,  0,  0,  0,  0,  0},
        {  5, 10, 10, 10, 10, 10, 10,  5},
        { -5,  0,  0,  0,  0,  0,  0, -5},
        { -5,  0,  0,  0,  0,  0,  0, -5},
        { -5,  0,  0,  0,  0,  0,  0, -5},
        { -5,  0,  0,  0,  0,  0,  0, -5},
        { -5,  0,  0,  0,  0,  0,  0, -5},
        {  0,  0,  0,  5,  5,  0,  0,  0},
    },
    ["q"] = {
        {-20,-10,-10, -5, -5,-10,-10,-20},
        {-10,  0,  0,  0,  0,  0,  0,-10},
        {-10,  0,  5,  5,  5,  5,  0,-10},
        { -5,  0,  5,  5,  5,  5,  0, -5},
        {  0,  0,  5,  5,  5,  5,  0, -5},
        {-10,  5,  5,  5,  5,  5,  0,-10},
        {-10,  0,  5,  0,  0,  0,  0,-10},
        {-20,-10,-10, -5, -5,-10,-10,-20},
    },
    ["k"] = {
        {-30,-40,-40,-50,-50,-40,-40,-30},
        {-30,-40,-40,-50,-50,-40,-40,-30},
        {-30,-40,-40,-50,-50,-40,-40,-30},
        {-30,-40,-40,-50,-50,-40,-40,-30},
        {-20,-30,-30,-40,-40,-30,-30,-20},
        {-10,-20,-20,-20,-20,-20,-20,-10},
        { 20, 20,  0,  0,  0,  0, 20, 20},
        { 20, 30, 10,  0,  0, 10, 30, 20},
    }
}

function tug_chess_engine.heuristic(board, id)
    local score = 0
    
    -- WIN
    local winning_player = has_won(board)
    if winning_player == id then score = score + win_score
    elseif winning_player == -id + 3 then score = score - win_score end

    -- MATERIAL AND POSITION
    for l, line in ipairs(board) do
        for r, row in ipairs(board) do
            if row.name ~= "" then
                if row.name == string.upper(row.name) then
                    if id == 1 then score = score + piece_values[string.lower(row.name)] + piece_square_tables[string.lower(row.name)][l][r]
                    else score = score - piece_values[string.lower(row.name)] - piece_square_tables[string.lower(row.name)][l][r] end
                else
                    if id == 2 then score = score + piece_values[string.lower(row.name)] + piece_square_tables[string.lower(row.name)][9 - l][9 - r]
                    else score = score - piece_values[string.lower(row.name)] - piece_square_tables[string.lower(row.name)][9 - l][9 - r] end
                end
            end
        end
    end

    -- TODO: Implement https://en.wikipedia.org/wiki/Chess_piece_relative_value
    -- TODO: Implement https://www.chessprogramming.org/Simplified_Evaluation_Function

    return score
end

function tug_chess_engine.minimax(board, depth, alpha, beta, max_p, id)
    if max_p then new_boards = get_moves(board, id)
    else new_boards = get_moves(board, -id + 3) end
    
    if depth == 0 or #new_boards == 0 then return tug_chess_engine.heuristic(board, id) end

    if max_p then
        local score = -math.huge
        for _, b in ipairs(new_boards) do
            score = math.max(score, tug_chess_engine.minimax(b, depth - 1, alpha, beta, false, id))
            if score > beta then break end
            alpha = math.max(alpha, score)
        end
    else
        local score = math.huge
        for _, b in ipairs(new_boards) do
            score = math.min(score, tug_chess_engine.minimax(b, depth - 1, alpha, beta, true, id))
            if score < alpha then break end
            beta = math.min(beta, score)
        end
    end

    return score
end

function tug_chess_engine.engine_next_board(board, id)
    local new_boards = get_moves(board, id)
    local max_score = -math.huge
    local best_board = nil

    for _, b in ipairs(new_boards) do
        local score = tug_chess_engine.minimax(b, 10, -math.huge, math.huge, false, id)
        if max_score < score then
            max_score = score
            best_board = b
        end
    end
    
    return best_board
end