local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

function heuristic(board, id)
    score = 0
    
    winning_player = has_won(board)
    if winning_player == id then score = score + 100
    elseif winning_player == -id + 3 then score = score - 100 end

    figure_count_enemy = 0
    figure_count_self = 0

    -- TODO: Implement https://en.wikipedia.org/wiki/Chess_piece_relative_value

    piece_values = {
        ["p"] = 1,
        ["r"] = 4,
        ["b"] = 3,
        ["n"] = 3,
        ["k"] = 0,
        ["q"] = 9,
    }

    for _, line in ipairs(board) do
        for _, row in ipairs(board) do
            if row != nil then
                if row.name == row.name.upper() then
                    if id == 1 then figure_count_self = figure_count_self + piece_values[row.name.lower()]
                    else figure_count_enemy = figure_count_enemy + piece_values[row.name.lower()] end
                else
                    if id == 2 then figure_count_self = figure_count_self + piece_values[row.name.lower()]
                    else figure_count_enemy = figure_count_enemy + piece_values[row.name.lower()] end
                end
            end
        end
    end

    score = score + figure_count_self - figure_count_enemy

    -- TODO: Implement best positions for pieces

    return score
end

function minimax(board, depth, alpha, beta, max_p, id)
    if max_p then new_boards = get_moves(board, id)
    else new_boards = get_moves(board, -id + 3) end
    
    if depth == 0 or #new_boards == 0 then return heuristic(board, id) end

    if max_p then
        score = -math.huge
        for _, b in ipairs(new_boards) do
            score = math.max(score, minimax(b, depth - 1, alpha, beta, false, id))
            if score > beta then break end
            alpha = math.max(alpha, score)
        end
    else
        score = math.huge
        for _, b in ipairs(new_boards) do
            score = math.min(score, minimax(b, depth - 1, alpha, beta, true, id))
            if score < alpha then break end
            beta = math.min(beta, score)
        end
    end

    return score
end

function engine_next_board(board, id)
    new_boards = get_moves(board, id)
    max_score = -math.huge
    best_board = nil

    for _, b in ipairs(new_boards) do
        score = minimax(b, 10, -math.huge, math.huge, false, id)
        if max_score < score then
            max_score = score
            best_board = b
        end
    end
    
    return best_board
end