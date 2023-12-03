local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()
local prefix = modname .. ":"

minetest.settings:set("time_speed", 0)

minetest.register_alias("mapgen_stone", prefix .. "ground")
minetest.register_alias("mapgen_grass", prefix .. "ground")
minetest.register_alias("mapgen_water_source", prefix .. "ground")
minetest.register_alias("mapgen_river_water_source", prefix .. "ground")

local colors = {
    "#040D12",
    "#183D3D",
    "#5C8374",
    "#93B1A6",
}

minetest.register_node(prefix .. "ground", {
	tiles = {"tug_blank.png^[colorize:" .. colors[3]},
	pointable = false,
    is_ground_content = false,
})

minetest.register_entity(prefix .. "rook", {
    initial_properties = {
        visual = "mesh",
        mesh = "tug_core_" .. "knight" .. ".obj",
        physical = true,
        pointable = true,
        collide_with_objects = false,
        textures = {"tug_blank.png^[colorize:" .. colors[2]},
        visual_size = vector.new(1, 1, 1),
    },
    on_step = function(self, dtime, moveresult)
    end,
})

minetest.register_on_joinplayer(function(player)
    minetest.add_entity(player:get_pos(), prefix .. "rook")
    clr1 = colors[2]
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