-- camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, worldWidth, worldHeight)
    local o = {
        x = x,
        y = y,
        worldWidth  = worldWidth,
        worldHeight = worldHeight,
        scale   = 1,
        offsetX = 0,
        offsetY = 0,
    }
    setmetatable(o, self)
    return o
end

function Camera:lookAt(targetX, targetY)
    local lerp = 0.05
    local halfW = self.worldWidth  / 2
    local halfH = self.worldHeight / 2
    self.x = self.x + (targetX - halfW - self.x) * lerp
    self.y = self.y + (targetY - halfH - self.y) * lerp
end

function Camera:attach()
    love.graphics.push()
    -- center‐letterbox
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
    -- world offset
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera
