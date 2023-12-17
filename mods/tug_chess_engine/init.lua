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
    ["k"] = 2000,
}

local piece_square_tables = {
    ["p"] = {
		{  0,  0,  0,  0,  0,  0,  0,  0},
		{  5, 10, 10,-20,-20, 10, 10,  5},
		{  5, -5,-10,  0,  0,-10, -5,  5},
		{  0,  0,  0, 20, 20,  0,  0,  0},
		{  5,  5, 10, 25, 25, 10,  5,  5},
		{ 10, 10, 20, 30, 30, 20, 10, 10},
		{ 50, 50, 50, 50, 50, 50, 50, 50},
		{  0,  0,  0,  0,  0,  0,  0,  0},
    },
    ["n"] = {
		{-50,-40,-30,-30,-30,-30,-40,-50},
		{-40,-20,  0,  5,  5,  0,-20,-40},
		{-30,  5, 10, 15, 15, 10,  5,-30},
		{-30,  0, 15, 20, 20, 15,  0,-30},
		{-30,  5, 15, 20, 20, 15,  5,-30},
		{-30,  0, 10, 15, 15, 10,  0,-30},
		{-40,-20,  0,  0,  0,  0,-20,-40},
		{-50,-40,-30,-30,-30,-30,-40,-50},
	},
    ["b"] = {
		{-20,-10,-10,-10,-10,-10,-10,-20},
		{-10,  5,  0,  0,  0,  0,  5,-10},
		{-10, 10, 10, 10, 10, 10, 10,-10},
		{-10,  0, 20, 10, 10, 20,  0,-10},
		{-10,  5,  5, 10, 10,  5,  5,-10},
		{-10,  0,  5, 10, 10,  5,  0,-10},
		{-10,  0,  0,  0,  0,  0,  0,-10},
		{-20,-10,-10,-10,-10,-10,-10,-20},
    },
    ["r"] = {
		{  0,-50,  5,  10, 10, 5,-50,  0},
		{ -5,  0,  0,  0,  0,  0,  0, -5},
		{ -5,  0,  0,  0,  0,  0,  0, -5},
		{ -5,  0,  0,  0,  0,  0,  0, -5},
		{ -5,  0,  0,  0,  0,  0,  0, -5},
		{ -5,  0,  0,  0,  0,  0,  0, -5},
		{  5, 10, 10, 10, 10, 10, 10,  5},
		{  0,  0,  0,  0,  0,  0,  0,  0},
    },
    ["q"] = {
		{-20,-10,-10, -5, -5,-10,-10,-20},
		{-10,  0,  5,  0,  0,  0,  0,-10},
		{-10,  5,  5,  5,  5,  5,  0,-10},
		{  0,  0,  5,  5,  5,  5,  0, -5},
		{ -5,  0,  5,  5,  5,  5,  0, -5},
		{-10,  0,  5,  5,  5,  5,  0,-10},
		{-10,  0,  0,  0,  0,  0,  0,-10},
		{-20,-10,-10, -5, -5,-10,-10,-20},
    },
    ["k"] = {
		{ 20, 30, 10,  0,  0, 10, 30, 20},
		{ 20, 20,  0,  0,  0,  0, 20, 20},
		{-10,-20,-20,-20,-20,-20,-20,-10},
		{-20,-30,-30,-40,-40,-30,-30,-20},
		{-30,-40,-40,-50,-50,-40,-40,-30},
		{-30,-40,-40,-50,-50,-40,-40,-30},
		{-30,-40,-40,-50,-50,-40,-40,-30},
		{-30,-40,-40,-50,-50,-40,-40,-30},
    },
}

function tug_chess_engine.heuristic(board)
    local white_score = 0
    
    --local winning_player = tug_chess_logic.has_won(board)
    --if winning_player == 1 then white_score = white_score + win_score
    --elseif winning_player == 2 then white_score = white_score - win_score end

	for l, line in pairs(board) do
		for r, row in pairs(line) do
			if row.name ~= "" then
				local lower_row = string.lower(row.name)
				if row.name == string.upper(row.name) then
					white_score = white_score + piece_values_lookup[lower_row]
					white_score = white_score + piece_square_tables[lower_row][l][r]
				else
					white_score = white_score - piece_values_lookup[lower_row]
					white_score = white_score - piece_square_tables[lower_row][9 - l][9 - r]
				end
			end
		end
	end

	return white_score
end

--local transposition_table = {}

function tug_chess_engine.hash_board(board)
	local hash = ""
	local free_count = 0

	for _, line in pairs(board) do
		free_count = 0
		for _, row in pairs(line) do
			if row.name == "" then
				free_count = free_count + 1
			else
				if free_count > 0 then hash = hash .. free_count end
				hash = hash .. row.name
				free_count = 0
			end
		end
		if free_count > 0 then hash = hash .. free_count end
		hash = hash .. "/"
	end
	
	return hash
end

function tug_chess_engine.negamax(board, depth, alpha, beta, color)
    if depth == 0 or tug_chess_logic.has_won(board) ~= 0 then return (3 - 2 * color) * tug_chess_engine.heuristic(board) end

    local new_boards = tug_chess_logic.get_next_boards(board, color)

    local score = -math.huge
    for _, b in pairs(new_boards) do
		--local board_hash = tug_chess_engine.hash_board(b)
		--if transposition_table[board_hash] ~= nil then
		--	score = transposition_table[board_hash]
		--else
		--	score = math.max(score, -tug_chess_engine.negamax(b, depth - 1, -beta, -alpha, -color + 3))
		--	transposition_table[board_hash] = score
		--end
		score = math.max(score, -tug_chess_engine.negamax(b, depth - 1, -beta, -alpha, -color + 3))
		alpha = math.max(alpha, score)
        if alpha >= beta then
            break
        end
    end

    return score
end

function tug_chess_engine.engine_next_board(board, id)
    local new_boards = tug_chess_logic.get_next_boards(board, id)
    local max_score = -math.huge
	local best_board = nil

	minetest.debug(tug_chess_engine.hash_board(board))

    for _, b in pairs(new_boards) do
        local score = -tug_chess_engine.negamax(b, 1, -math.huge, math.huge, -id + 3)
        if max_score < score then
            max_score = score
			best_board = b
        end
    end

    return best_board
end
