-- map.lua
local Platform = require("platform")

local Map = {}

-- playfield dimensions
Map.width  = 800
Map.height = 600

-- A helper to quickly make a wall
local function wall(x)
    -- x: left‐edge of wall (could be negative for offscreen)
    return Platform:new(x, 0, 50, Map.height, "normal")
end

Map.platforms = {
    -- left & right walls
    wall(-50),
    wall(Map.width),

    -- (optional) ceiling to stop you flying off top
    Platform:new(0, -50, Map.width, 50, "normal"),

    -- ground
    Platform:new(0, Map.height - 50, Map.width, 50, "normal"),

    -- staggered test platforms
    Platform:new(100, 450, 120, 20, "normal"),
    Platform:new(250, 380, 100, 20, "normal"),
    Platform:new(400, 310, 150, 20, "normal"),
    Platform:new(600, 260, 100, 20, "normal"),
    Platform:new(300, 200, 80, 20, "normal"),
    Platform:new(150, 150, 100, 20, "normal"),
    Platform:new(500, 100, 120, 20, "normal"),

    -- a few floating islands
    Platform:new(50, 300, 60, 15, "normal"),
    Platform:new(700, 350, 60, 15, "normal"),

    -- keep your vertical sliders for sliding tests
    Platform:new(650, 250, 20, 200, "vertical"),
    Platform:new(100, 150, 20, 200, "vertical"),
}

return Map
