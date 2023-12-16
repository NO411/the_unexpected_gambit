local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_logic = {

}

function deepcopy(t)
    local t_type = type(t)
    local copy
    if t_type == 'table' then
        copy = {}
        for t_key, t_value in next, t, nil do
            copy[deepcopy(t_key)] = deepcopy(t_value)
        end
        setmetatable(copy, deepcopy(getmetatable(t)))
    else
        copy = t
    end
    return copy
end

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
    return board
end

-- TODOS

function tug_chess_logic.has_won(board)
    -- RETURNS 0 - No winner, 1 - White won, 2 - Black won
    return 0
end

function tug_chess_logic.get_next_boards(board, id)
    -- RETURNS All next boards for a current player
    -- id = 1 white
    -- id = 2 black
    local boards = {}

	local start_z = 0
	local end_z = 0
	local d = 0
	local piece_count = 0

	if id == 1 then
		start_z = 1
		end_z = 8
		d = 1
	else
		start_z = 8
		end_z = 1
		d = -1
	end

    for z = start_z, end_z, d do
        for x = 1, 8 do
            local piece = board[z][x]

            if ((string.upper(piece.name) == piece.name) and (id == 1)) or ((string.lower(piece.name) == piece.name) and (id == 2)) then
				piece_count = piece_count + 1
                local moves = cases[string.lower(piece.name)](deepcopy(board), z, x, string.upper(piece.name) == piece.name, true)
                if moves then
                    for _, move in pairs(moves) do
                        table.insert(boards, tug_chess_logic.apply_move({z = z, x = x}, move, deepcopy(board)))
                    end
                end
            end

			if piece_count > 15 then break end
        end
		if piece_count > 15 then break end
    end
    return boards
end

local function in_bounds(coord)
    return coord.x >= 1 and coord.x <= 8 and coord.z >= 1 and coord.z <= 8
end

local function get_piece(board, coord)
    return board[coord.z][coord.x]
end

local function moved(board, coord)
    if not in_bounds(coord) then
        return false
    end
    return get_piece(board, coord).moved
end

local function get_name(board, coord)
    if not in_bounds(coord) then
        return ""
    end
    return get_piece(board, coord).name
end

local function is_empty(board, coord)
    return get_name(board, coord) == ""
end

local function is_same_color(board, coord, white)
    local name = get_name(board, coord)
    if name == "" then
        return false
    end
    return (white == (string.upper(name) == name))
end

function tug_chess_logic.apply_move(from, to, input_board)
    -- to is the apllied move which includes the needed metadata
    local board = deepcopy(input_board)

    board[to.z][to.x] = board[from.z][from.x]
    board[from.z][from.x] = {name = ""}

    local name = get_name(board, to)
    local moved = to.moved

    get_piece(board, to).moved = moved

    local is_white = (string.upper(name) == name)
    -- set moved for opponents pawns to false
    for z = 1, 8 do
        for x = 1, 8 do
            local _name = get_name(board, {z = z, x = x})
            -- diferent color
            if ((_name == string.lower(_name) and is_white) or
            (_name == string.upper(_name) and not is_white)) and string.lower(_name) == "p"  then
                board[z][x].moved = false
            end
        end
    end

    -- apply en passant
    if to.en_passant then
        local dir = 1
        if string.lower(name) == name then
            dir = -1
        end
        if from.x < to.x then
            board[to.z - 1 * dir][to.x] = {name = ""}
        else
            board[to.z - 1 * dir][to.x] = {name = ""}
        end
    end

    -- pawn promotion
    if string.lower(name) == "p" and (to.z == 1 or to.z == 8) then
        board[to.z][to.x].name = string.upper(name) == name and "Q" or "q"
    end

    -- apply rook move on castling
    if to.castling then
        if to.x == 7 then
            board[to.z][6] = board[from.z][8]
            board[to.z][6].moved = true
            board[from.z][8] = {name = ""}
        else
            board[to.z][4] = board[from.z][1]
            board[to.z][4].moved = true
            board[from.z][1] = {name = ""}
        end
    end

    return board
end

local function in_check(board, white)
    local king_coord = nil

    -- set king_coord
    for z = 1, 8 do
        for x = 1, 8 do
            local piece = board[z][x]
            king_coord = {z = z, x = x}
            if string.lower(piece.name) == "k" and is_same_color(board, king_coord, white) then
                break
            end
        end
    end

    for z = 1, 8 do
        for x = 1, 8 do
            local piece_coord = {z = z, x = x}
            local piece = get_piece(board, piece_coord)
            if (not is_same_color(board, piece_coord, white)) and piece.name ~= "" then
                -- recursive
                -- check wether the piece could capture the king
                -- therefore calculate all possible moves without caring for oponents checks (stop recursion)
                local moves = cases[string.lower(piece.name)](board, piece_coord.z, piece_coord.x, not white, false)
                for _, move in pairs(moves) do
                    if move.z == king_coord.z and move.x == king_coord.x then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function in_check_when_move(board, from, to, white)
    -- king castle already filtered in cases["k"]
    return in_check(tug_chess_logic.apply_move(from, to, board), white)
end

local function filter_legal_moves(board, from, to_moves, white, check_for_check)
    local board_bounds_filtered = {}
    for _, coord in pairs(to_moves) do
        if in_bounds(coord) then
            table.insert(board_bounds_filtered, coord)
        end
    end

    local color_filtered = {}
    for _, coord in pairs(board_bounds_filtered) do
        if not is_same_color(board, coord, white) then
            table.insert(color_filtered, coord)
        end
    end

    if not check_for_check then
    -- ^^^^ stop recursion
        return color_filtered
    end

    local check_filtered = {}
    for _, coord in pairs(color_filtered) do
        if not in_check_when_move(board, from, coord, white) then
            table.insert(check_filtered, coord)
        end
    end

    return check_filtered
end

--[[
moving logic:
- after a king or rook moves, set moved = true for the piece
- before anything, reset moved param for all pawns to false (en passant only lasts for one move)
after this
- if a pawns moves 2 square set moved = true for en passant
--]]

cases = {
    [""] = function(board, z, x, white, check_for_check)
        return {}
    end,
    ["p"] = function(board, z, x, white, check_for_check)
        -- TODO: check if the move is legal (would there be check?)
        -- for this, apply moves to current board, check for check on generated board
        -- only return valid moves

        local moves = {}
        local direction = white and 1 or -1

        -- basic pawn moves
        local one_step = {z = z + 1 * direction, x = x}
        if is_empty(board, one_step) then
            table.insert(moves, one_step)

            local two_square_move = {z = z + 2 * direction, x = x, moved = true}
            if is_empty(board, two_square_move) and ((white and z == 2) or (not white and z == 7)) then
                table.insert(moves, two_square_move)
            end
        end

        -- capturing
        local side1 = {z = z + 1 * direction, x = x + 1}
        local side2 = {z = z + 1 * direction, x = x - 1}
        if not is_empty(board, side1) then
            table.insert(moves, side1)
        end
        if not is_empty(board, side2) then
            table.insert(moves, side2)
        end
        
        -- en passant
        -- -1 for left en passant, 1 for right
        for rl = -1, 1, 2 do
            local coord = {z = z, x = x + rl}
            if in_bounds(coord) then
                if (not is_same_color(board, coord, white)) and moved(board, coord) and string.lower(get_name(board, coord)) == "p" then
                    table.insert(moves, {z = z + 1 * direction, x = x + rl, en_passant = true})
                end
            end
        end

        return filter_legal_moves(board, {z = z, x = x}, moves, white, check_for_check)
    end,
    ["n"] = function(board, z, x, white, check_for_check)
        local moves = {}

        -- knights move in Ls
        local long_move = {2, -2}
        local short_move = {1, -1}

        -- iterate through each combination
        for _, lm in ipairs(long_move) do
            for _, sm in ipairs(short_move) do
                -- 8 possible moves
                table.insert(moves, {z = z + lm, x = x + sm})
                table.insert(moves, {z = z + sm, x = x + lm})
            end
        end

        -- filter off board moves
        return filter_legal_moves(board, {z = z, x = x}, moves, white, check_for_check)
    end,
    ["b"] = function(board, z, x, white, check_for_check)
        local moves = {}
        for no = 1, 7 do
            local move = {z = z + no, x = x + no}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                -- capture, cant go further
                table.insert(moves, move)
                break
            end
        end
        for so = 1, 7 do
            local move = {z = z - so, x = x + so}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        for sw = 1, 7 do
            local move = {z = z - sw, x = x - sw}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        for nw = 1, 7 do
            local move = {z = z + nw, x = x - nw}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        return filter_legal_moves(board, {z = z, x = x}, moves, white, check_for_check)
    end,
    ["r"] = function(board, z, x, white, check_for_check)
        local moves = {}
        for zp = 1, 7 do
            local move = {z = z + zp, x = x, moved = true}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        for zn = 1, 7 do
            local move = {z = z - zn, x = x, moved = true}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        for xp = 1, 7 do
            local move = {z = z, x = x + xp, moved = true}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        for xn = 1, 7 do
            local move = {z = z, x = x - xn, moved = true}
            if is_empty(board, move) then
                table.insert(moves, move)
            else
                table.insert(moves, move)
                break
            end
        end
        return filter_legal_moves(board, {z = z, x = x}, moves, white, check_for_check)
    end,
    ["q"] = function(board, z, x, white, check_for_check)
        -- queen moves like rook and bishop combined
        local rook_moves = cases.r(board, z, x, white, check_for_check)
        local bishop_moves = cases.b(board, z, x, white, check_for_check)

        for _, bishop_move in ipairs(bishop_moves) do
            table.insert(rook_moves, bishop_move)
        end

        -- already filtered
        return rook_moves
    end,
    ["k"] = function(board, z, x, white, check_for_check)
        local moves = {}

        local z_dir = {-1, 0, 1}
        local x_dir = {-1, 0, 1}

        for _, zm in ipairs(z_dir) do
            for _, xm in ipairs(z_dir) do
                -- 8 possible moves (x = 0, z = 0 is not possible)
                if not (zm == 0 and xm == 0) then
                    table.insert(moves, {z = z + zm, x = x + xm, moved = true})
                end
            end
        end

        -- castling
        if not moved(board, {z = z, x = x}) then
            -- z is either 0 or 7
            -- king side
            local rook = {z = z, x = 8}
            if string.lower(get_name(board, rook)) == "r" and (not moved(board, rook)) and
            is_empty(board, {z = z, x = 7}) and
            is_empty(board, {z = z, x = 6}) and
            not in_check_when_move(board, {z = z, x = x}, {z = z, x = 6}, white) then
                table.insert(moves, {z = z, x = 7, castling = true, moved = true})
            end
            -- queen side
            rook = {z = z, x = 1}
            if string.lower(get_name(board, rook)) == "r" and (not moved(board, rook)) and
            is_empty(board, {z = z, x = 2}) and
            is_empty(board, {z = z, x = 3}) and
            is_empty(board, {z = z, x = 4}) and
            not in_check_when_move(board, {z = z, x = x}, {z = z, x = 4}, white) then
                table.insert(moves, {z = z, x = 3, castling = true, moved = true})
            end
        end

        return filter_legal_moves(board, {z = z, x = x}, moves, white, check_for_check)
    end,
}

-- z is the row (1-8), x is the column (A-H)
function tug_chess_logic.get_moves(z, x)
    -- the moves are absolute
    local name = tug_gamestate.g.current_board[z][x].name
    return cases[string.lower(name)](deepcopy(tug_gamestate.g.current_board), z, x, string.upper(name) == name, true)
    -- the function which apllies this to a board needs to move the rook if the king castled, only king move returned!
end

-- UTILS

-- engine_next_board(board [curr board], id [player id of the engine]) - returns the next board for the engine move
