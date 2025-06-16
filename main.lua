-- main.lua
local Player = require("player")
local Platform = require("platform")
local Camera = require("camera")

local player
local platforms = {}
local camera

function love.load()
    love.window.setTitle("Jump King LÖVE2D")
    love.window.setMode(800, 600, {resizable = false, vsync = true})
    love.graphics.setDefaultFilter("nearest", "nearest") -- For crisp pixels if scaling later

    -- Initialize player
    player = Player:new(350, 510) -- Starting position, adjusted for ground

    -- Create some platforms
    table.insert(platforms, Platform:new(0, 550, 800, 50, "normal")) -- Ground
    table.insert(platforms, Platform:new(100, 400, 150, 20, "normal"))
    table.insert(platforms, Platform:new(300, 300, 100, 20, "normal"))
    table.insert(platforms, Platform:new(500, 200, 120, 20, "normal"))
    table.insert(platforms, Platform:new(700, 100, 80, 20, "normal"))

    -- NEW: Add a vertical sliding platform for testing
    table.insert(platforms, Platform:new(650, 250, 20, 200, "vertical")) -- Red platform
    -- Another for opposite side test
    table.insert(platforms, Platform:new(100, 150, 20, 200, "vertical"))

    -- Initialize camera
    camera = Camera:new(player.x, player.y, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    player:update(dt, platforms)

    -- Update camera to follow player
    camera:lookAt(player.x, player.y)
end

function love.draw()
    -- Apply camera transform
    if camera then
        camera:attach()
    end

    -- Draw platforms
    for _, platform in ipairs(platforms) do
        platform:draw()
    end

    -- Draw player
    player:draw()

    -- Release camera transform
    if camera then
        camera:detach()
    end

    -- Optional: Draw debug info (screen fixed, not camera-affected)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    love.graphics.print("Player X: " .. string.format("%.1f", player.x) .. ", Y: " .. string.format("%.1f", player.y), 10, 30)
end

function love.keypressed(key)
    player:keypressed(key)
end

function love.keyreleased(key)
    player:keyreleased(key)
end