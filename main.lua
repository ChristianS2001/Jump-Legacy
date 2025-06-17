-- main.lua
local Player = require("player")
local Camera = require("camera")
local Map    = require("map")

local player, camera, platforms
local gameState = "play"

local options = {
    items      = { "Audio Volume", "Controls", "Fullscreen", "Resolution", "Quit" },
    selected   = 1,
    volume     = 1.0,
    fullscreen = true,
    -- only pixel‐resolutions; FOV stays Map.width×Map.height
    resolutions = {
        { w = 800,  h = 600,  label = "800×600"  },
        { w = 1024, h = 768,  label = "1024×768" },
        { w = 1280, h = 720,  label = "1280×720" },
        { w = 1920, h = 1080, label = "1920×1080" },
    },
    resIndex = 4,  -- default to 1080p
}

local function clamp(v,minv,maxv)
    if v<minv then return minv end
    if v>maxv then return maxv end
    return v
end

-- apply fullscreen + resolution, then recompute camera.scale & letterbox offsets
local function applyWindowSettings()
    local r = options.resolutions[options.resIndex]
    love.window.setFullscreen(options.fullscreen)
    love.window.setMode(r.w, r.h, {
        fullscreen = options.fullscreen,
        resizable  = false,
        vsync      = true,
    })

    -- how big is the drawable area?
    local pixelW, pixelH = love.graphics.getDimensions()

    -- world FOV is always Map.width x Map.height:
    local worldW, worldH = Map.width, Map.height

    -- uniform scale to fit world into window, letterbox others
    local sx = pixelW / worldW
    local sy = pixelH / worldH
    camera.scale = math.min(sx, sy)

    -- center the scaled world
    camera.offsetX = (pixelW - worldW * camera.scale) / 2
    camera.offsetY = (pixelH - worldH * camera.scale) / 2
end

function love.load()
    love.window.setTitle("Jump Legacy")
    love.graphics.setDefaultFilter("nearest", "nearest")

    player    = Player:new(350, 510)
    platforms = Map.platforms
    -- camera world size locked to Map dimensions:
    camera    = Camera:new(
        player.x, player.y,
        Map.width, Map.height
    )

    love.audio.setVolume(options.volume)
    applyWindowSettings()
end

function love.update(dt)
    if gameState == "play" then
        player:update(dt, platforms)
        camera:lookAt(player.x, player.y)
    end
end

function love.draw()
    if gameState == "play" then
        camera:attach()
          for _, p in ipairs(platforms) do p:draw() end
          player:draw()
        camera:detach()

        love.graphics.setColor(1,1,1,1)
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 10)
        love.graphics.print(
          ("Player X: %.1f, Y: %.1f"):format(player.x, player.y),
          10, 30
        )

    else
        -- OPTIONS MENU (same as before) ...
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", 0,0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("OPTIONS", 0,40, love.graphics.getWidth(), "center")

        local x0,y0,sp = 150,100,40
        local mx,my = love.mouse.getPosition()
        for i,label in ipairs(options.items) do
            local y = y0 + (i-1)*sp
            -- hover/selection highlight...
            if i==options.selected then
                love.graphics.setColor(0.2,0.2,0.8,0.4)
                love.graphics.rectangle("fill", x0-10,y-5,400,sp-10)
            elseif my>=y-5 and my<=y+sp-10 and mx>=x0-10 and mx<=x0+400 then
                love.graphics.setColor(0.8,0.8,0.2,0.2)
                love.graphics.rectangle("fill", x0-10,y-5,400,sp-10)
            end

            love.graphics.setColor(i==options.selected and 1 or 0.9,1,i==options.selected and 0 or 1,1)
            local disp = label
            if label=="Audio Volume" then
                disp = ("%s: %d%%"):format(label,math.floor(options.volume*100))
            elseif label=="Fullscreen" then
                disp = ("%s: %s"):format(label,options.fullscreen and "On" or "Off")
            elseif label=="Resolution" then
                disp = ("%s: %s"):format(label,options.resolutions[options.resIndex].label)
            end
            love.graphics.print(disp, x0, y)

            if label=="Audio Volume" or label=="Fullscreen" or label=="Resolution" then
                love.graphics.rectangle("line", x0+300,y,20,20)
                love.graphics.print("<", x0+304,y)
                love.graphics.rectangle("line", x0+330,y,20,20)
                love.graphics.print(">", x0+334,y)
            end
        end
    end
end

function love.keypressed(key)
    if key=="escape" then
        gameState = (gameState=="play") and "options" or "play"
        return
    end
    if gameState=="play" then player:keypressed(key) end
end

function love.keyreleased(key)
    if gameState=="play" then player:keyreleased(key) end
end

function love.mousepressed(x,y,button)
    if gameState~="options" or button~=1 then return end
    local x0,y0,sp = 150,100,40

    -- select row
    for i=1,#options.items do
        local yy = y0 + (i-1)*sp
        if y>=yy-5 and y<=yy+sp-10 and x>=x0-10 and x<=x0+400 then
            options.selected = i
            break
        end
    end

    local sel,label = options.selected, options.items[options.selected]
    local leftBX,rightBX,by = x0+300, x0+330, y0 + (sel-1)*sp

    if label=="Audio Volume" then
        if x>=leftBX and x<=leftBX+20 and y>=by and y<=by+20 then
            options.volume = clamp(options.volume-0.1,0,1)
            love.audio.setVolume(options.volume)
        elseif x>=rightBX and x<=rightBX+20 and y>=by and y<=by+20 then
            options.volume = clamp(options.volume+0.1,0,1)
            love.audio.setVolume(options.volume)
        end

    elseif label=="Fullscreen" then
        if (x>=leftBX and x<=leftBX+20 or x>=rightBX and x<=rightBX+20)
           and y>=by and y<=by+20 then
            options.fullscreen = not options.fullscreen
            applyWindowSettings()
        end

    elseif label=="Resolution" then
        if x>=leftBX and x<=leftBX+20 and y>=by and y<=by+20 then
            options.resIndex = clamp(options.resIndex-1,1,#options.resolutions)
        elseif x>=rightBX and x<=rightBX+20 and y>=by and y<=by+20 then
            options.resIndex = clamp(options.resIndex+1,1,#options.resolutions)
        end
        applyWindowSettings()

    elseif label=="Quit" then
        if x>=x0 and x<=x0+100
           and y>=y0+(sel-1)*sp and y<=y0+(sel-1)*sp+20 then
            love.event.quit()
        end
    end
end
