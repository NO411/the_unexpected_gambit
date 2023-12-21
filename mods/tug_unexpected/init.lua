tug_unexpected = {
    unexpected_behaviors = {
        {
            name = "Remove all pawns",
			color = "#6A0572",
			-- 5%
            pick_min = 1,
            pick_max = 5,
            func = function()
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if string.lower(row.name) == "p" then
							tug_gamestate.g.current_board[l][r] = {name = ""}
						end
					end
				end	
			end
        },
		{
			name = "Delete piece",
			color = "#FF4500",
			-- 25%
			pick_min = 6,
			pick_max = 30,
			func = function()
				local pieces = {}
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if row.name ~= "" then
							table.insert(pieces, {l=l, r=r})
						end
					end
				end
				local rand_piece = pieces[math.random(1, #pieces)]
				tug_gamestate.g.current_board[rand_piece.l][rand_piece.r] = {name = ""}
            end
		},
		{
			name = "Add piece",
			color = "#3498db",
			-- 20%
			pick_min = 31,
			pick_max = 50,
			func = function()
				local free_squares = {}
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if row.name == "" then
							table.insert(free_squares, {l=l, r=r})
						end
					end
				end
				if #free_squares > 0 then
					local rand_square = free_squares[math.random(1, #free_squares)]
					local pieces_list = {"k", "q", "b", "n", "r", "K", "Q", "B", "N", "R"}
					local new_piece = pieces_list[math.random(1, #pieces_list)]
					tug_gamestate.g.current_board[rand_square.l][rand_square.r] = {name = new_piece}
				end
			end
		},
		{
			name = "Swap queens",
			color = "#FFD700",
			-- 5%
			pick_min = 51,
			pick_max = 55,
			func = function()
				local queens = {}
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if string.lower(row.name) == "q" then
							queens[row.name] = {l=l, r=r}
						end
					end
				end
				local queen_num = 0
				for k, v in pairs(queens) do queen_num = queen_num + 1 end
				if queen_num == 2 then
					tug_gamestate.g.current_board[queens["q"].l][queens["q"].r] = {name = "Q"}
					tug_gamestate.g.current_board[queens["Q"].l][queens["Q"].r] = {name = "q"}
				end
            end
		},
		{
			name = "Swap two pieces",
			color = "#2ecc71",
			-- 15%
			pick_min = 56,
			pick_max = 70,
			func = function()
				local pieces = {}
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if row.name ~= "" then
							table.insert(pieces, {l=l, r=r})
						end
					end
				end
				local piece_one = pieces[math.random(1, math.floor(#pieces / 2))]
				local piece_two = pieces[math.random(math.floor(#pieces / 2) + 1, #pieces)]
				local temp_piece = tug_gamestate.g.current_board[piece_one.l][piece_one.r]
				tug_gamestate.g.current_board[piece_one.l][piece_one.r] = tug_gamestate.g.current_board[piece_two.l][piece_two.r]
				tug_gamestate.g.current_board[piece_two.l][piece_two.r] = temp_piece
			end
		},
		{
			name = "Showdown",
			color = "#9b59b6",
			-- 5%
			pick_min = 71,
			pick_max = 75,
			func = function()
				for l, line in pairs(tug_gamestate.g.current_board) do
					for r, row in pairs(line) do
						if string.lower(row.name) ~= "k" and string.lower(row.name) ~= "q" then
							tug_gamestate.g.current_board[l][r] = {name = ""}
						end
					end
				end
			end
		},
		{
			name = "Night switch",
			color = "#e74c3c",
			-- 15%
			pick_min = 76,
			pick_max = 90,
			func = function()
				minetest.set_timeofday(1)
			end
		},
		{
			name = "Time travel",
			color = "#00CED1",
			-- 10%
			pick_min = 91,
			pick_max = 100,
			func = function()
                tug_gamestate.g.current_board = deepcopy(tug_gamestate.g.last_boards[math.random(1, #tug_gamestate.g.last_boards)])
            end
		},


		{
            name = "Pawns storm",
			color = "#F08080",
            pick_min = 0,
            pick_max = 0,
            func = function()
                -- TODO: Implement this thing
            end
        },
		{
			name = "Swap player",
			color = "#1e90ff",
			pick_min = 0,
			pick_max = 0,
			func = function()
                -- TODO: Implement this thing
            end
		},
    }
}
