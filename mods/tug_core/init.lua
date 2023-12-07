local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()
local prefix = modname .. ":"
local storage = minetest.get_mod_storage()

tug_core = {
    player1 = "",
    player2 = "",
    white = nil,
}

-- metadata
function save_metadata()
    storage:set_string("board", minetest.serialize(tug_chess_logic.current_board))
end

minetest.settings:set("time_speed", 0)
minetest.settings:set("viewing_range", 50)

-- fix
ground_level = 8

minetest.register_alias("mapgen_stone", prefix .. "ground")
minetest.register_alias("mapgen_grass", prefix .. "ground")
minetest.register_alias("mapgen_water_source", prefix .. "ground")
minetest.register_alias("mapgen_river_water_source", prefix .. "ground")

local colors = {
    sky = "#ffffff", -- sky
    ground = "#ffffff", -- ground
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
	--pointable = false,
    is_ground_content = false,
})

minetest.register_node(prefix .. "frame", {
	tiles = {"tug_blank.png^[colorize:" .. colors.frame},
	--pointable = false,
    is_ground_content = false,
})

minetest.register_node(prefix .. "dark", {
	tiles = {"tug_blank.png^[colorize:" .. colors.dark_square},
	--pointable = false,
    is_ground_content = false,
})

minetest.register_node(prefix .. "light", {
	tiles = {"tug_blank.png^[colorize:" .. colors.light_square},
	--pointable = false,
    is_ground_content = false,
})

minetest.register_node(prefix .. "barrier", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
})

minetest.register_on_generated(function(minp, maxp, blockseed)
    for x = -1, 8 do
        for y = -1, 8 do
            local node = "dark"
            if (x + y) % 2 == 0 then
                node = "light"
            end

            if x == -1 or x == 8 or y == -1 or y == 8 then
                node = "frame"
            end

            minetest.set_node({x = x, y = ground_level, z = y}, {name = prefix .. node})
        end
    end
end)

for _, piece in pairs(entity_lookup) do
    minetest.chat_send_all(piece)
    minetest.register_entity(prefix .. piece, {
        initial_properties = {
            visual = "mesh",
            mesh = "tug_core_" .. piece .. ".obj",
            physical = true,
            pointable = true,
            collide_with_objects = false,
            textures = {"tug_blank.png^[colorize:" .. colors.light_pieces},
            visual_size = vector.new(2, 2, 2),
            static_save = false,
        },
        on_step = function(self, dtime, moveresult)
        end,
    })
end

minetest.register_on_joinplayer(function(player)
    player:set_pos(vector.new(0, ground_level + 1, 0))

    if #minetest.get_connected_players() == 1 then
        local board = minetest.deserialize(storage:get_string("board"))
        if board ~= nil then
            tug_chess_logic.restart(board)
        end

        update_game_board()
    end

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
end)

function split(s, delimiter)
    local result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

minetest.register_chatcommand("start", {
    params = "[player2]",
    description = "default is singleplayer against engine, use player2 to play against an other player",
    privs = {},
    func = function(name, param)
        tug_core.player1 = name
        local t = split(param, " ")
        local player2 = t[#t]

        if player2 ~= "" then
            tug_core.player2 = player2
        else
            tug_core.player2 = ""
        end
        
        local white = 1
        if math.random(0, 1) == 1 then
            white = 2
            minetest.chat_send_player(name, "You play with the black pieces.")
            minetest.chat_send_player(player2, "You play with the white pieces.")
        else
            minetest.chat_send_player(name, "You play with the white pieces.")
            minetest.chat_send_player(player2, "You play with the black pieces.")
        end

        tug_chess_logic.start()
        update_game_board()
        save_metadata()
    end,
})

function update_game_board()
    if tug_chess_logic.current_board == nil then
        return
    end

    for x = 0, 7 do
        for y = 0, 7 do
            local piece = tug_chess_logic.current_board[x + 1][y + 1]
            if piece.name ~= "" then
                local objs = minetest.get_objects_in_area(vector.new(x - 0.5, ground_level - 0.5, y - 0.5), vector.new(x + 0.5, ground_level + 0.5, y + 0.5))
                if #objs > 0 then
                    for _, obj in pairs(objs) do
                        obj:remove()
                    end
                end
                local ent = minetest.add_entity(vector.new(x, ground_level + 0.5, y), prefix .. entity_lookup[string.upper(piece.name)])
                if piece.name == string.upper(piece.name) then
                    ent:set_properties({ textures = {"tug_blank.png^[colorize:" .. colors.light_pieces} })
                else
                    ent:set_properties({ textures = {"tug_blank.png^[colorize:" .. colors.dark_pieces} })
					ent:set_yaw(math.pi)
                end
            end
        end
    end
end
