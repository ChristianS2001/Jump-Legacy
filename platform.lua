-- platform.lua
local Platform = {}
Platform.__index = Platform

function Platform:new(x, y, width, height, type) -- Added 'type' parameter
    local o = {
        x = x,
        y = y,
        width = width,
        height = height,
        type = type or "normal" -- Default to "normal" if not specified
    }
    setmetatable(o, self)
    return o
end

function Platform:draw()
    if self.type == "vertical" then
        love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Red for vertical platforms
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Gray for normal platforms
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Platform