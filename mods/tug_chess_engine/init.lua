local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_engine = {}

local win_score = 1000

local piece_values_lookup = {
    ["p"] = 1,
    ["n"] = 3,
    ["b"] = 3,
    ["r"] = 5,
    ["q"] = 9,
    ["k"] = 0,
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

function tug_chess_engine.heuristic(board)
    local white_score = 0
    
    local winning_player = tug_chess_logic.has_won(board)
    if winning_player == 1 then white_score = white_score + win_score
    elseif winning_player == 2 then white_score = white_score - win_score end

	for l, line in pairs(board) do
		for r, row in pairs(line) do
			if row.name ~= "" then
				local lower_row = string.lower(row.name)
				if row.name == string.upper(row.name) then
					white_score = white_score + piece_values_lookup[lower_row]
					white_score = white_score + piece_square_tables[lower_row][9 - l][9 - r]
				else
					white_score = white_score - piece_values_lookup[lower_row]
					white_score = white_score - piece_square_tables[lower_row][l][r]
				end
			end
		end
	end

	return white_score
end

function tug_chess_engine.negamax(board, depth, alpha, beta, color)
    if depth == 0 or tug_chess_logic.has_won(board) ~= 0 then return (3 - 2 * color) * tug_chess_engine.heuristic(board) end

    local new_boards = tug_chess_logic.get_next_boards(board, color)

    local score = -math.huge
    for _, b in pairs(new_boards) do
        score = math.max(score, -tug_chess_engine.negamax(b, depth - 1, -beta, -alpha, -color + 3))
        alpha = math.max(alpha, score)
        if alpha >= beta then
            break
        end
    end

    return score
end

function tug_chess_engine.minimax(board, depth, alpha, beta, max_p, id)
    if depth == 0 or tug_chess_logic.has_won(board) ~= 0 then return (3 - 2 * id) * tug_chess_engine.heuristic(board) end
    
    local new_boards = nil
    if max_p then new_boards = tug_chess_logic.get_next_boards(board, id)
    else new_boards = tug_chess_logic.get_next_boards(board, -id + 3) end

    local score = 0
    if max_p then
        score = -math.huge
        for _, b in pairs(new_boards) do
            score = math.max(score, tug_chess_engine.minimax(b, depth - 1, alpha, beta, false, id))
            if score > beta then break end
            alpha = math.max(alpha, score)
        end
    else
        score = math.huge
        for _, b in pairs(new_boards) do
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
	local best_board = nil

    for _, b in pairs(new_boards) do
        --local score = tug_chess_engine.minimax(b, 2, -math.huge, math.huge, false, id)
        local score = -tug_chess_engine.negamax(b, 2, -math.huge, math.huge, -id + 3)
        if max_score < score then
            max_score = score
			best_board = b
        end
    end

    return best_board
end
