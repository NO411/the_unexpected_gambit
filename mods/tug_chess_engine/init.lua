local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

function heuristic(board, id)
    score = 0
    winning_player = has_won(board)
    if winning_player == id then
        score = score + 100
    elseif winning_player == -id + 3 then
        score = score - 100
    end
    return score
end

function minimax(board, depth, max_p, id)
    if max_p then
        new_boards = get_moves(board, id)
    else
        new_boards = get_moves(board, -id + 3)
    end
    if depth == 0 or #new_boards == 0 then
        return heuristic(board, id)
    end
    if max_p then
        score = -math.huge
        for _, b in ipairs(new_boards) do
            score = math.max(score, minimax(b, depth - 1, false, id))
        end
    else
        score = math.huge
        for _, b in ipairs(new_boards) do
            score = math.min(score, minimax(b, depth - 1, true, id))
        end
    end
    return score
end

function engine_next_board(board, id)
    new_boards = get_moves(board, id)
    max_score = -math.huge
    best_board = nil
    for _, b in ipairs(new_boards) do
        score = minimax(b, 10, false, id)
        if max_score < score then
            max_score = score
            best_board = b
        end
    end
    return best_board
end