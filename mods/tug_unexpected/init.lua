tug_unexpected = {
    unexpected_behaviors = {
        {
            name = "Remove all pawns",
            pick_min = 0,
            pick_max = 0,
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
            name = "Pawns storm",
            pick_min = 0,
            pick_max = 0,
            func = function()
                -- TODO: Implement this thing
            end
        },
		{
			name = "Swap player",
			pick_min = 0,
			pick_max = 0,
			func = function()
                -- TODO: Implement this thing
            end
		},
		{
			name = "Delete piece",
			pick_min = 0,
			pick_max = 0,
			func = function()
                -- TODO: Implement this thing
            end
		},
		{
			name = "Add piece",
			pick_min = 0,
			pick_max = 0,
			func = function()
                -- TODO: Implement this thing
            end
		},
		{
			name = "Swap queens",
			pick_min = 0,
			pick_max = 0,
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
			pick_min = 0,
			pick_max = 0,
			func = function()
				-- TODO: Implement this thing
			end
		},
		{
			name = "Showdown",
			pick_min = 0,
			pick_max = 0,
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
			name = "Time travel",
			pick_min = 0,
			pick_max = 0,
			func = function()
                -- TODO: Implement this thing
            end
		},
    }
}
