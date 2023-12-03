local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()

tug_chess_logic = {}
tug_chess_logic.pieces = {
    "king",
    "queen",
    "rook",
    "bishop",
    "knight",
    "pawn",
}