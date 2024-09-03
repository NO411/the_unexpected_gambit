local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()
local prefix = modname .. ":"
local storage = minetest.get_mod_storage()

local loaded_gamestate = minetest.deserialize(storage:get_string("gamestate"))
tug_gamestate.g = loaded_gamestate

local function delete_gamestate()
    tug_gamestate.g = {
        players = {"", ""},
        current_player = nil,
        current_selected = nil,
        current_board = nil,
		moves_until_unexpected = -1,
		last_boards = {},
		engine_strength = 1,
    }
end

if loaded_gamestate == nil then
    delete_gamestate()
end

math.randomseed(os.time())

tug_core = {
    engine_moves_true = 3,
    hud_refs = {},
    unexpected_hud_refs = {},
    interaction_blocked = false,
}

-- metadata
local function save_metadata()
    storage:set_string("gamestate", minetest.serialize(tug_gamestate.g))
end

-- fix
ground_level = 8

minetest.register_alias("mapgen_stone", prefix .. "ground")
minetest.register_alias("mapgen_grass", prefix .. "ground")
minetest.register_alias("mapgen_water_source", prefix .. "ground")
minetest.register_alias("mapgen_river_water_source", prefix .. "ground")

local colors = {
    sky = "#8e8e8e", -- sky
    ground = "#8e8e8e", -- ground
    frame = "#baca44", -- frame
    light_square = "#EEEED2", -- light square
    dark_square = "#769656",  -- dark square
    light_pieces = "#ffffff", -- light pieces
    dark_pieces = "#2E2E2E", -- dark pieces
}

local entity_lookup = {
    ["R"] = "rook",
    ["N"] = "knight",
    ["B"] = "bishop",
    ["Q"] = "queen",
    ["K"] = "king",
    ["P"] = "pawn",
}

minetest.register_node(prefix .. "ground", {
	tiles = {"tug_blank.png^[colorize:" .. colors.ground},
	pointable = false,
    is_ground_content = false,
})

minetest.register_node(prefix .. "frame", {
	tiles = {"tug_frame.png"},
	pointable = false,
    is_ground_content = false,
    paramtype2 = "facedir",
})

minetest.register_node(prefix .. "frame_corner", {
	tiles = {"tug_frame_corner.png"},
	pointable = false,
    is_ground_content = false,
    paramtype2 = "facedir",
})

minetest.register_node(prefix .. "dark", {
	tiles = {"tug_blank.png^[colorize:" .. colors.dark_square},
    is_ground_content = false,
})

minetest.register_node(prefix .. "light", {
	tiles = {"tug_blank.png^[colorize:" .. colors.light_square},
    is_ground_content = false,
})

minetest.register_node(prefix .. "barrier", {
    drawtype = "airlike",
    paramtype = "light",
    pointable = false,
    sunlight_propagates = true,
})

-- hack to get higher hand range, set on joinplayer
local function set_player_hand(player)
    player:get_inventory():set_stack("main", 1, {name = prefix .. "hand"})
end

minetest.register_craftitem(prefix .. "hand", {
    range = 20,
    on_drop = function(itemstack, dropper, pos)
        itemstack:clear()
        set_player_hand(dropper)
    end,
})

local top_circle_def = {
    hud_elem_type = "image",
    position = {x = 1, y = 0},
    alignment = {x = 0, y = 0},
    scale = {x = 0.25, y = 0.25},
    offset = {x = -100, y = 100},
    z_index = 0,
}

local bottom_circle_def = {
    hud_elem_type = "image",
    position = {x = 1, y = 1},
    alignment = {x = 0, y = 0},
    scale = {x = 0.25, y = 0.25},
    offset = {x = -100, y = -100},
    z_index = 0,
}

local function copy_hud_def(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copy_hud_def(orig_key)] = copy_hud_def(orig_value)
        end
        setmetatable(copy, copy_hud_def(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function get_player_id(player)
    for i, _player in pairs(tug_gamestate.g.players) do
        if _player.name == player:get_player_name() then
            return i
        end
    end
end

local function add_marking_circle(player, name)
    local marking_circle = copy_hud_def(top_circle_def)
    if tug_gamestate.g.players ~= {"", ""} and tug_gamestate.g.players[tug_gamestate.g.current_player].name == name then
        marking_circle = copy_hud_def(bottom_circle_def)
    end
    marking_circle.text = "tug_marking_circle.png"
    marking_circle.z_index = 1

    tug_core.hud_refs[name].marking_circle = player:hud_add(marking_circle)
end

local function add_color_hud(player)
    local name = player:get_player_name()
    tug_core.hud_refs[name] = {}

    local top_color = "white"
    local bottom_color = "black"

    if tug_gamestate.g.players[get_player_id(player)].color == 1 then
        local _temp = top_color
        top_color = bottom_color
        bottom_color = _temp
    end

    local top_circle = copy_hud_def(top_circle_def)
    top_circle.text = "tug_" .. top_color .. "_circle.png"
    tug_core.hud_refs[name].top_circle = player:hud_add(top_circle)

    local bottom_circle = copy_hud_def(bottom_circle_def)
    bottom_circle.text = "tug_" .. bottom_color .. "_circle.png"
    tug_core.hud_refs[name].bottom_circle = player:hud_add(bottom_circle)

    local bottom_circle_text = copy_hud_def(bottom_circle_def)
    bottom_circle_text.text = "You"
    bottom_circle_text.hud_elem_type = "text"
    bottom_circle_text.offset.y = bottom_circle_text.offset.y - 80
    bottom_circle_text.number = 0x2E2E2E
    bottom_circle_text.style = 1
    tug_core.hud_refs[name].bottom_circle_text = player:hud_add(bottom_circle_text)

    local top_circle_text = copy_hud_def(top_circle_def)
    top_circle_text.text = "Opponent"
    top_circle_text.hud_elem_type = "text"
    top_circle_text.offset.y = top_circle_text.offset.y - 80
    top_circle_text.number = 0x2E2E2E
    top_circle_text.style = 1
    tug_core.hud_refs[name].top_circle_text = player:hud_add(top_circle_text)

    add_marking_circle(player, name)
end

local function remove_all_huds()
    for name, huds in pairs(tug_core.hud_refs) do
        for _, hud in pairs(huds) do
            local player = minetest.get_player_by_name(name)
            if player then
                player:hud_remove(hud)
            end
        end
    end
    tug_core.hud_refs = {}
end

local function switch_marking_circle(id)
    local name = tug_gamestate.g.players[id].name
    local player = minetest.get_player_by_name(name)

    if not player then
        return
    end

    player:hud_remove(tug_core.hud_refs[name].marking_circle)
    add_marking_circle(player, name)
end

minetest.register_on_generated(function(minp, maxp, blockseed)
    for x = -1, 8 do
        for z = -1, 8 do
            local node = "light"
            if (x + z) % 2 == 0 then
                node = "dark"
            end

            local param2 = 0
            if x == -1 or x == 8 or z == -1 or z == 8 then
                node = "frame"
                if z == 8 then
                    param2 = 2
                elseif x == 8 then
                    param2 = 3
                elseif x == - 1 then
                    param2 = 1
                end
                if (x == -1 and (z == -1 or z == 8)) or (x == 8 and (z == -1 or z == 8)) then
                    node = "frame_corner"
                    if z == 8 and x == -1 then
                        param2 = 2
                    elseif z == 8 and x == 8 then
                        param2 = 3
                    elseif z == -1 and x == 8 then
                        param2 = 4
                    end
                end
            end

            minetest.set_node({x = x, y = ground_level, z = z}, {name = prefix .. node, param2 = param2})
        end
    end

    local cube_radius = 15
    for x = -cube_radius, cube_radius do
        for y = -cube_radius, cube_radius do
            for z = -cube_radius, cube_radius do
                if (math.abs(x) == cube_radius or math.abs(y) == cube_radius or math.abs(z) == cube_radius) and ground_level + y > ground_level then
                    minetest.set_node({x = x + 5, y = ground_level + y, z = z + 5}, {name = prefix .. "barrier"})
                end
            end
        end
    end

end)

for _, piece in pairs(entity_lookup) do
    --minetest.chat_send_all(piece)
    minetest.register_entity(prefix .. piece, {
        initial_properties = {
            visual = "mesh",
            mesh = "tug_core_" .. piece .. ".obj",
            physical = true,
            pointable = false,
            collide_with_objects = false,
            textures = {"tug_blank.png^[colorize:" .. colors.light_pieces},
            visual_size = vector.new(2, 2, 2),
            static_save = false,
            use_texture_alpha = true,
        },
        on_step = function(self, dtime, moveresult)
        end,
    })
end

local selected_textures = {}
local last_textures = {}

for n = 1, 6 do
    table.insert(selected_textures, "tug_blank.png^[colorize:#ff000080")
	table.insert(last_textures, "tug_blank.png^[colorize:#fcb10380")
end

minetest.register_entity(prefix .. "selected", {
    initial_properties = {
        visual = "cube",
        physical = true,
        pointable = false,
        collide_with_objects = false,
        textures = selected_textures,
        visual_size = vector.new(1, 1, 1),
        static_save = false,
        use_texture_alpha = true,
    },
    on_step = function(self, dtime, moveresult)
    end,
})

minetest.register_entity(prefix .. "last", {
    initial_properties = {
        visual = "cube",
        physical = true,
        pointable = false,
        collide_with_objects = false,
        textures = last_textures,
        visual_size = vector.new(1, 1, 1),
        static_save = false,
        use_texture_alpha = true,
    },
    on_step = function(self, dtime, moveresult)
    end,
})

minetest.register_on_newplayer(function(player)
    local name = player:get_player_name()
    player:set_pos(vector.new(0, ground_level + 1, 0))
    local basic_privs = minetest.get_player_privs(name)
    basic_privs.fly = true
    minetest.set_player_privs(name, basic_privs)
end)

local make_move = 0
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    player:hud_set_hotbar_itemcount(1)
    player:get_inventory():set_size("main", 1)
    set_player_hand(player)
    player:set_inventory_formspec(
		"formspec_version[4]" ..
		"size[10, 10]" ..
		"label[0.5,0.5;" ..
        [[
Chat commands:

/start [Player2\] - Play the game as it was intended.
/start_normal [Player2\] - Play a normal game of chess.

The Player2 parameter is optional, but necessary
if you want to play against another player.
Without it, the engine will be selected as an opponent.

/strength - Display the current strength of the engine.
/strength [Depth\] - Change the strength of the engine
to the desired value. Only odd numbers are allowed.

Tip: The fly mode is activated by default and
should be used to get a better overview!
]]
)

    player:set_physics_override({speed = 1.5})
    player:set_properties({selectionbox = {0, 0, 0, 0, 0, 0, rotate = false}})
    local clr1 = colors.sky
	player:set_sky({
        clouds = false,
        type = "regular",
		sky_color = {
			day_sky = clr1,
			day_horizon = clr1,
			dawn_sky = clr1,
			dawn_horizon = clr1,
			night_sky = clr1,
			night_horizon = clr1,
		},
    })
    player:set_sun({
        visible = false,
        sunrise_visible = false,
    })
    player:hud_set_flags({
        hotbar = false,
		healthbar = false,
		crosshair = true,
		wielditem = false,
		breathbar = false,
		minimap = false,
		minimap_radar = false,
	})

    local found = false
    for i, p in ipairs(tug_gamestate.g.players) do
        if p.name == name then
            if i ~= tug_gamestate.g.current_player then
                --minetest.chat_send_player(p.name, "Your turn.")
            else
                --minetest.chat_send_player(p.name, tug_gamestate.g.players[tug_gamestate.g.current_player].name .. "'s turn.")
                -- engine moves
                if tug_gamestate.g.players[tug_gamestate.g.current_player].name == "" then
                    make_move = tug_core.engine_moves_true
                end
            end
            add_color_hud(player)
            found = true
        end
    end

    if not found then
        minetest.chat_send_player(name, "Use /start to start a game. Open inventory for more info!")
    end

    minetest.after(0, function()
        update_game_board()
    end)
end)

local function split(s, delimiter)
    local result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local function switch_player()
    tug_gamestate.g.current_player = 3 - tug_gamestate.g.current_player
    --minetest.chat_send_player(tug_gamestate.g.players[tug_gamestate.g.current_player].name, "Your turn.")
    --minetest.chat_send_player(tug_gamestate.g.players[3 - tug_gamestate.g.current_player].name, tug_gamestate.g.players[tug_gamestate.g.current_player].name .. "'s turn.")
    switch_marking_circle(1)
    switch_marking_circle(2)
end

local function get_player_name_by_color(color_id)
    for _, player in pairs(tug_gamestate.g.players) do
        if player.color == color_id then
            return player.name
        end
    end
end

local function clear_all()
	tug_core.interaction_blocked = false
	delete_gamestate()
	save_metadata()
end

local function reset_game(has_won)
    local message = "This game is a draw!"
    if has_won ~= 3 then
        local winner_name = get_player_name_by_color(has_won)
        if winner_name == "" then
            winner_name = "The Engine"
        end
        message = winner_name .. " won with the " .. ((has_won == 1) and "white" or "black") .. " pieces!"
    end
    tug_core.interaction_blocked = true

	minetest.set_timeofday(0.5)

    local msg_huds = {}
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        msg_huds[name] = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.5},
            offset = {x = 0, y = -100},
            text = message,
            alignment = {x = 0, y = 0},
            size = {x = 2, y = 2},
            style = 1,
            number = 0x96C441,
        })
    end

    minetest.after(0.3, function()
        minetest.sound_play({name = "tug_core_game_end"}, {}, true)
    end)

    minetest.after(4, function()
		clear_all()
		for name, hud in pairs(msg_huds) do
			local player = minetest.get_player_by_name(name)
			if player then
				player:hud_remove(msg_huds[name])
			end
		end
		remove_all_huds()
	end)
end

local function append_timeline()
	table.insert(tug_gamestate.g.last_boards, deepcopy(tug_gamestate.g.current_board))
	if #tug_gamestate.g.last_boards > 10 then
		table.remove(tug_gamestate.g.last_boards, 1)
	end
end

local function made_move(new_board)
    if not new_board then
        return
    end

    local old_pieces = 0
    for l, line in pairs(tug_gamestate.g.current_board) do
        for r, row in pairs(line) do
            if string.lower(row.name) ~= "" then
                old_pieces = old_pieces + 1
            end
        end
    end	
    local new_pieces = 0
    for l, line in pairs(new_board) do
        for r, row in pairs(line) do
            if string.lower(row.name) ~= "" then
                new_pieces = new_pieces + 1
            end
        end
    end
    local capture_move = new_pieces == (old_pieces - 1)

    tug_gamestate.g.current_board = new_board

    switch_player()
	decrease_moves_until_unexpected()
	append_timeline()	
    save_metadata()
    update_game_board()

    if tug_chess_logic.in_check(tug_gamestate.g.current_board, tug_gamestate.g.players[tug_gamestate.g.current_player].color == 1) then
        minetest.sound_play({name = "tug_core_check"}, {}, true)
    elseif capture_move then
        minetest.sound_play({name = "tug_core_capture"}, {}, true)
    else
        minetest.sound_play({name = "tug_core_move"}, {}, true)
    end
end

minetest.register_globalstep(function(dtime)
    if make_move == 0 then
        return
    end
    make_move = make_move - 1
    if make_move == 1 then
        make_move = 0
        local new_board = tug_chess_engine.engine_next_board(tug_gamestate.g.current_board, tug_gamestate.g.players[2].color, tug_gamestate.g.engine_strength)
        if new_board then
            made_move(new_board)
            local has_won = tug_chess_logic.has_won(tug_gamestate.g.current_board, tug_gamestate.g.players[tug_gamestate.g.current_player].color == 1)
            if has_won > 0 then
                reset_game(has_won)
            end
        end
    end
end)

local function display_unexpected_behavior(behavior_name, behavior_color)
    minetest.sound_play({name = "tug_core_unexpected"}, {}, true)

    local event_time = 2
    local behavior_huds = {}
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        behavior_huds[name] = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.5},
            offset = {x = 0, y = 100},
            text = behavior_name,
            alignment = {x = 0, y = 0},
            size = {x = 3, y = 3},
            style = 1,
            number = tonumber(string.sub(behavior_color, 2), 16),
        })
    end

    minetest.after(event_time, function()
        for name, hud in pairs(behavior_huds) do
            local player = minetest.get_player_by_name(name)
            if player then
                player:hud_remove(behavior_huds[name])
            end
        end
    end)

    minetest.add_particlespawner({
        amount = 1000,
        time = event_time,
        vertical = true,
        texture = "tug_blank.png^[colorize:" .. behavior_color,
        glow = 5,
        minpos = {x = 0, y = ground_level, z = 0},
        maxpos = {x = 7, y = ground_level, z = 7},
        minvel = {x = -1, y = 0, z = -1},
        maxvel = {x = 1, y = 10, z = 1},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 0,
        maxexptime = event_time,
        minsize = 1,
        maxsize = 2,
    })
end

local function generate_moves_until_unexpected()
	local available_move_count = {6, 8, 10}
	tug_gamestate.g.moves_until_unexpected = available_move_count[math.random(#available_move_count)]
end

function decrease_moves_until_unexpected()
	if tug_gamestate.g.moves_until_unexpected > -1 then
		tug_gamestate.g.moves_until_unexpected = tug_gamestate.g.moves_until_unexpected - 1
		if tug_gamestate.g.moves_until_unexpected == 0 then
			generate_moves_until_unexpected()
			local behavior_pick = math.random(1, 100)
			for _, behavior in pairs(tug_unexpected.unexpected_behaviors) do
				minetest.set_timeofday(0.5)
				if behavior.pick_min <= behavior_pick and behavior_pick <= behavior.pick_max then
					display_unexpected_behavior(behavior.name, behavior.color)
					append_timeline()
					behavior.func()
					break
				end
			end
		end
	end
end

local function start_game(name, param, unexpected)
    if tug_core.interaction_blocked then
        return
    end

    delete_gamestate()
    remove_all_huds()

	tug_gamestate.g.players[1] = {name = name, color = 1}
	local t = split(param, " ")
	local player2 = t[1]

	if player2 ~= "" then
		local p = minetest.get_player_by_name(player2)
		if p then
			tug_gamestate.g.players[2] = {name = player2, color = 2}
		else
			minetest.chat_send_player(name, "[ERROR] Requested opponent couldn't be found. Try again!");
			clear_all()
			return nil
		end
	else
		tug_gamestate.g.players[2] = {name = "", color = 2}
	end

	tug_gamestate.g.current_player = 1
	if math.random(0, 1) == 1 then
		tug_gamestate.g.players[1].color = 2
		tug_gamestate.g.players[2].color = 1
		tug_gamestate.g.current_player = 2
	end

	tug_gamestate.g.current_board = tug_chess_logic.get_default_board()
	append_timeline()
	update_game_board()

	local opponent_name = tug_gamestate.g.players[2].name
	if opponent_name == "" then opponent_name = "the engine" end
	if unexpected then
		if tug_gamestate.g.current_player == 2 then tug_gamestate.g.moves_until_unexpected = 7
		else tug_gamestate.g.moves_until_unexpected = 8 end
		minetest.chat_send_player(name, "[INFO] Unexpected game of chess against " .. opponent_name .. " started.")
	else
		tug_gamestate.g.moves_until_unexpected = -1
		minetest.chat_send_player(name, "[INFO] Normal game of chess against " .. opponent_name .. " started.")
	end

	if tug_gamestate.g.players[tug_gamestate.g.current_player].name == "" then
		make_move = tug_core.engine_moves_true
	end

    add_color_hud(minetest.get_player_by_name(name))
	if player2 ~= "" then
		add_color_hud(minetest.get_player_by_name(player2))
	end

	save_metadata()
end

local function set_strength(name, param)
	local args = split(param, " ")
	if args[1] == "" then
		minetest.chat_send_player(name, "[INFO] The current engine strength is set to " .. tug_gamestate.g.engine_strength .. ". Use the [Depth] parameter to specify a new one.")
		return nil
	end
	local strength = tonumber(args[1])
	if strength ~= nil and math.fmod(strength, 2) == 1 then
		tug_gamestate.g.engine_strength = strength
		save_metadata()
		minetest.chat_send_player(name, "[INFO] Engine strength set to " .. strength .. ".")
	else
		minetest.chat_send_player(name, "[ERROR] Invalid strength. Only odd numbers are allowed!")
	end
end

minetest.register_chatcommand("start", {
	params = "[Player2]",
	description = "Play the game as it was intended. The default is a single player against the engine. Use Player2 parameter to play against another player.",
	privs = {},
	func = function(name, param)
		start_game(name, param, true)
	end,

})

minetest.register_chatcommand("start_normal", {
    params = "[Player2]",
    description = "Play a normal game of chess. The default is a single player against the engine. Use Player2 parameter to play against another player.",
    privs = {},
    func = function(name, param)
		start_game(name, param, false)
	end,
})

minetest.register_chatcommand("strength", {
	params = "[Depth]",
	description = "Specify the strength of the engine. Only odd numbers are allowed.",
	privs = {},
	func = function(name, param)
		set_strength(name, param)
	end
})

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if tug_core.interaction_blocked then
        return
    end

    if node.name == prefix .. "light" or node.name == prefix .. "dark" then
        local x = pos.x
        local y = pos.y
        local z = pos.z
        
        -- is current player the puncher
        if tug_gamestate.g.current_board ~= nil and puncher:get_player_name() == tug_gamestate.g.players[tug_gamestate.g.current_player].name then
            if tug_gamestate.g.current_selected == nil then
                -- check if piece is on square
                if tug_gamestate.g.current_board[z + 1][x + 1].name ~= "" then
                    -- punched piece (if white or not)
                    local is_white = tug_gamestate.g.current_board[z + 1][x + 1].name == string.upper(tug_gamestate.g.current_board[z + 1][x + 1].name)
                    -- check wether player color matches punched piece color
                    if (tug_gamestate.g.players[tug_gamestate.g.current_player].color == 1 and is_white) or (tug_gamestate.g.players[tug_gamestate.g.current_player].color == 2 and not is_white) then
                        tug_gamestate.g.current_selected = {x = x, z = z}
                        local objs = minetest.get_objects_in_area(vector.new(x - 0.5, y + 0.5, z - 0.5), vector.new(x + 0.5, y + 1.5, z + 0.5))
                        objs[1]:set_properties({ textures = {objs[1]:get_properties().textures[1] .. "C8"}})
                        local moves = tug_chess_logic.get_moves(z + 1, x + 1)
                        for _, move in pairs(moves) do
                            minetest.add_entity(vector.new(move.x - 1, y + 0.05, move.z - 1), prefix .. "selected")
                        end
                        tug_gamestate.g.current_selected.moves = moves
                    end
                end
            else
                if (x ~= tug_gamestate.g.current_selected.x) or (z ~= tug_gamestate.g.current_selected.z) then
                    local selected_move = nil
                    for _, m in pairs(tug_gamestate.g.current_selected.moves) do
                        if (m.x == x + 1) and (m.z == z + 1) then
                            selected_move = m
                            break
                        end
                    end
                    if selected_move then
                        made_move(tug_chess_logic.apply_move({x = tug_gamestate.g.current_selected.x + 1, z = tug_gamestate.g.current_selected.z + 1}, selected_move, tug_gamestate.g.current_board))
                        local has_won = tug_chess_logic.has_won(tug_gamestate.g.current_board, tug_gamestate.g.players[tug_gamestate.g.current_player].color == 1)

                        if has_won > 0 then
                            reset_game(has_won)
                        elseif tug_gamestate.g.players[tug_gamestate.g.current_player].name == "" then
                            -- engine makes move when no remi or win found
                            make_move = tug_core.engine_moves_true
                            -- the global step will make the move and check for a win again
                        end
                    end
                end
                update_game_board()
                tug_gamestate.g.current_selected = nil
            end
        end
    end
end)

function update_game_board()
    if tug_gamestate.g.current_board == nil and not tug_core.interaction_blocked then
        for y = 0, 7 do
            for x = 0, 7 do
                local objs = minetest.get_objects_in_area(vector.new(x - 0.5, ground_level - 0.5, y - 0.5), vector.new(x + 0.5, ground_level + 0.5, y + 0.5))
                if #objs > 0 then
                    for _, obj in pairs(objs) do
                        obj:remove()
                    end
                end
            end
        end
        return
    end

    for y = 0, 7 do
        for x = 0, 7 do
            local objs = minetest.get_objects_in_area(vector.new(x - 0.5, ground_level - 0.5, y - 0.5), vector.new(x + 0.5, ground_level + 0.5, y + 0.5))
            if #objs > 0 then
                for _, obj in pairs(objs) do
                    obj:remove()
                end
            end
			if #tug_gamestate.g.last_boards > 1 then
				if tug_gamestate.g.current_board[y + 1][x + 1].name ~= tug_gamestate.g.last_boards[#tug_gamestate.g.last_boards - 1][y + 1][x + 1].name then
					minetest.add_entity(vector.new(x, ground_level + 0.05, y), prefix .. "last")
				end
			end
            local piece = tug_gamestate.g.current_board[y + 1][x + 1]
            if piece.name ~= "" then
                local ent = minetest.add_entity(vector.new(x, ground_level + 0.5, y), prefix .. entity_lookup[string.upper(piece.name)])
                if piece.name == string.upper(piece.name) then
                    ent:set_properties({ textures = {"tug_blank.png^[colorize:" .. colors.light_pieces} })
                    ent:set_yaw(0.5 * math.pi)
                else
                    ent:set_properties({ textures = {"tug_blank.png^[colorize:" .. colors.dark_pieces} })
					ent:set_yaw(-0.5 * math.pi)
                end
            end
        end
    end
end
