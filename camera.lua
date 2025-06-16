-- camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, viewportWidth, viewportHeight)
    local o = {
        x = x,
        y = y,
        viewportWidth = viewportWidth,
        viewportHeight = viewportHeight,
        scale = 1 -- Can be used for zooming
    }
    setmetatable(o, self)
    return o
end

function Camera:lookAt(targetX, targetY)
    -- Smooth camera movement (optional, but good for Jump King feel)
    local lerpFactor = 0.05 -- Adjust for camera smoothness
    self.x = self.x + (targetX - self.viewportWidth / 2 - self.x) * lerpFactor
    self.y = self.y + (targetY - self.viewportHeight / 2 - self.y) * lerpFactor

    -- Directly follow (less smooth)
    -- self.x = targetX - self.viewportWidth / 2
    -- self.y = targetY - self.viewportHeight / 2
end

function Camera:attach()
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera