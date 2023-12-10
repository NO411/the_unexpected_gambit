local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_engine = {}

local win_score = 1.00

local piece_values_lookup = {
    ["p"] = 0.10,
    ["n"] = 0.30,
    ["b"] = 0.30,
    ["r"] = 0.50,
    ["q"] = 0.90,
    ["k"] = 0.00,
}

local piece_square_tables = {
    ["p"] = {
        { 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00},
        { 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50},
        { 0.10, 0.10, 0.20, 0.30, 0.30, 0.20, 0.10, 0.10},
        { 0.05, 0.05, 0.10, 0.25, 0.25, 0.10, 0.05, 0.05},
        { 0.00, 0.00, 0.00, 0.20, 0.20, 0.00, 0.00, 0.00},
        { 0.05,-0.05,-0.10, 0.00, 0.00,-0.10,-0.05, 0.05},
        { 0.05, 0.10, 0.10,-0.20,-0.20, 0.10, 0.10, 0.05},
        { 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00},
    },
    ["n"] = {
        {-0.50,-0.40,-0.30,-0.30,-0.30,-0.30,-0.40,-0.50},
        {-0.40,-0.20, 0.00, 0.00, 0.00, 0.00,-0.20,-0.40},
        {-0.30, 0.00, 0.10, 0.15, 0.15, 0.10, 0.00,-0.30},
        {-0.30, 0.05, 0.15, 0.20, 0.20, 0.15, 0.05,-0.30},
        {-0.30, 0.00, 0.15, 0.20, 0.20, 0.15, 0.00,-0.30},
        {-0.30, 0.05, 0.10, 0.15, 0.15, 0.10, 0.05,-0.30},
        {-0.40,-0.20, 0.00, 0.05, 0.05, 0.00,-0.20,-0.40},
        {-0.50,-0.40,-0.30,-0.30,-0.30,-0.30,-0.40,-0.50},
    },
    ["b"] = {
        {-0.20,-0.10,-0.10,-0.10,-0.10,-0.10,-0.10,-0.20},
        {-0.10, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.10},
        {-0.10, 0.00, 0.05, 0.10, 0.10, 0.05, 0.00,-0.10},
        {-0.10, 0.05, 0.05, 0.10, 0.10, 0.05, 0.05,-0.10},
        {-0.10, 0.00, 0.10, 0.10, 0.10, 0.10, 0.00,-0.10},
        {-0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10,-0.10},
        {-0.10, 0.05, 0.00, 0.00, 0.00, 0.00, 0.05,-0.10},
        {-0.20,-0.10,-0.10,-0.10,-0.10,-0.10,-0.10,-0.20},
    },
    ["r"] = {
        { 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00},
        { 0.05, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.05},
        {-0.05, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.05},
        {-0.05, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.05},
        {-0.05, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.05},
        {-0.05, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.05},
        {-0.05, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.05},
        { 0.00, 0.00, 0.00, 0.05, 0.05, 0.00, 0.00, 0.00},
    },
    ["q"] = {
        {-0.20,-0.10,-0.10,-0.05,-0.05,-0.10,-0.10,-0.20},
        {-0.10, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,-0.10},
        {-0.10, 0.00, 0.05, 0.05, 0.05, 0.05, 0.00,-0.10},
        {-0.05, 0.00, 0.05, 0.05, 0.05, 0.05, 0.00,-0.05},
        { 0.00, 0.00, 0.05, 0.05, 0.05, 0.05, 0.00,-0.05},
        {-0.10, 0.05, 0.05, 0.05, 0.05, 0.05, 0.00,-0.10},
        {-0.10, 0.00, 0.05, 0.00, 0.00, 0.00, 0.00,-0.10},
        {-0.20,-0.10,-0.10,-0.05,-0.05,-0.10,-0.10,-0.20},
    },
    ["k"] = {
        {-0.30,-0.40,-0.40,-0.50,-0.50,-0.40,-0.40,-0.30},
        {-0.30,-0.40,-0.40,-0.50,-0.50,-0.40,-0.40,-0.30},
        {-0.30,-0.40,-0.40,-0.50,-0.50,-0.40,-0.40,-0.30},
        {-0.30,-0.40,-0.40,-0.50,-0.50,-0.40,-0.40,-0.30},
        {-0.20,-0.30,-0.30,-0.40,-0.40,-0.30,-0.30,-0.20},
        {-0.10,-0.20,-0.20,-0.20,-0.20,-0.20,-0.20,-0.10},
        { 0.20, 0.20, 0.00, 0.00, 0.00, 0.00, 0.20, 0.20},
        { 0.20, 0.30, 0.10, 0.00, 0.00, 0.10, 0.30, 0.20},
    }
}

function tug_chess_engine.heuristic(board, id)
    local score = 0
    
    -- WIN
    local winning_player = tug_chess_logic.has_won(board)
    if winning_player == id then score = score + win_score
    elseif winning_player == -id + 3 then score = score - win_score end


    -- MATERIAL AND POSITION
    for l, line in pairs(board) do
        for r, row in pairs(line) do
            if row.name ~= "" then
                if row.name == string.upper(row.name) then
                    if id == 1 then score = score + piece_values_lookup[string.lower(row.name)] + piece_square_tables[string.lower(row.name)][l][r]
                    else score = score - piece_values_lookup[string.lower(row.name)] - piece_square_tables[string.lower(row.name)][l][r] end
                else
                    if id == 2 then score = score + piece_values_lookup[string.lower(row.name)] + piece_square_tables[string.lower(row.name)][9 - l][9 - r]
                    else score = score - piece_values_lookup[string.lower(row.name)] - piece_square_tables[string.lower(row.name)][9 - l][9 - r] end
                end
            end
        end
    end

    -- TODO: Implement https://en.wikipedia.org/wiki/Chess_piece_relative_value
    -- TODO: Implement https://www.chessprogramming.org/Simplified_Evaluation_Function

    return score
end

function tug_chess_engine.minimax(board, depth, alpha, beta, max_p, id)
    if depth == 0 or tug_chess_logic.has_won(board) ~= 0 then return tug_chess_engine.heuristic(board, id) end
    
    local new_boards = nil
    if max_p then
        new_boards = tug_chess_logic.get_next_boards(board, id)
    else
        new_boards = tug_chess_logic.get_next_boards(board, -id + 3)
    end

    local score = 0
    if max_p then
        score = -math.huge
        for _, b in ipairs(new_boards) do
            score = math.max(score, tug_chess_engine.minimax(b, depth - 1, alpha, beta, false, id))
            if score > beta then break end
            alpha = math.max(alpha, score)
        end
    else
        score = math.huge
        for _, b in ipairs(new_boards) do
            score = math.min(score, tug_chess_engine.minimax(b, depth - 1, alpha, beta, true, id))
            if score < alpha then break end
            beta = math.min(beta, score)
        end
    end

    return score
end

function tug_chess_engine.engine_next_board(board, id)
    local new_boards = tug_chess_logic.get_next_boards(board, id)
    local max_score = -math.huge
    local eval_boards = {}

    for _, b in ipairs(new_boards) do
        local score = tug_chess_engine.minimax(b, 2, -math.huge, math.huge, false, id)
        table.insert(eval_boards, {b, score})
        if max_score < score then
            max_score = score
        end
    end

    local best_boards = {}
    for _, b in ipairs(eval_boards) do
        if b[2] == max_score then
            table.insert(best_boards, b[1])
        end
    end

    local best_board = best_boards[math.random(#best_boards)]
    
    return best_board
end
