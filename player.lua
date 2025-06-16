-- player.lua
local Player = {}
Player.__index = Player

-- Player properties
local PLAYER_WIDTH = 20
local PLAYER_HEIGHT = 40
local MOVE_SPEED = 150
local JUMP_POWER = -600
local GRAVITY = 800

function Player:new(x, y)
    local o = {
        x = x,
        y = y,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT,
        vx = 0,
        vy = 0,
        onGround = false,
        isChargingJump = false,
        jumpChargeTime = 0,
        maxJumpChargeTime = 0.5,
        jumpStrengthMultiplier = 0,
        isJumping = false,
        committedJumpVx = 0, -- This is the key for the committed direction
        prevX = x,
        prevY = y,
    }
    setmetatable(o, self)
    return o
end

function Player:update(dt, platforms)
    self.prevX = self.x
    self.prevY = self.y

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Debug prints (keep for now, remove later)
    print(string.format("--- Update Start --- dt: %.3f", dt))
    print(string.format("States: Charging=%s, Jumping=%s, OnGround=%s",
                        tostring(self.isChargingJump), tostring(self.isJumping), tostring(self.onGround)))
    print(string.format("Current VX: %.2f, Committed VX: %.2f", self.vx, self.committedJumpVx))

    -- Determine horizontal movement based on states
    if self.isChargingJump then
        print("State: CHARGING JUMP")
        self.vx = 0 -- Player STOPS horizontally while charging

        -- NEW LOGIC YOU FOUND: Continuously update committedJumpVx based on current 'a'/'d' input
        if love.keyboard.isDown("a") then
            self.committedJumpVx = -MOVE_SPEED
            print("Updated commitment: LEFT (-" .. MOVE_SPEED .. ")")
        elseif love.keyboard.isDown("d") then
            self.committedJumpVx = MOVE_SPEED
            print("Updated commitment: RIGHT (" .. MOVE_SPEED .. ")")
        else
            -- Only reset to 0 if player explicitly releases all keys while charging,
            -- otherwise, keep the last committed direction.
            -- This ensures that if they press A, release A, then release space,
            -- it still goes left. If they press A, then D, then release D, then release space,
            -- it goes right.
            -- If they press A, then release A, then press D, then release D, then release space,
            -- it goes straight.
            -- The simplest way for Jump King feel is to keep the last held direction,
            -- or default to 0 if nothing held. Your `if self.committedJumpVx ~= 0 then` part is interesting.
            -- For typical JK, if you release A/D during charge, it defaults to vertical (0).
            -- Let's stick with the simpler "last held input commits" for now.
            self.committedJumpVx = 0 -- If no A/D held during charge, it's a vertical jump
            print("Updated commitment: VERTICAL (0)")
        end


    elseif self.isJumping then
        print("State: JUMPING")
        print("Before assignment - VX: " .. self.vx .. ", CommittedVX: " .. self.committedJumpVx)
        self.vx = self.committedJumpVx -- Use the locked committedJumpVx
        print("After assignment - VX: " .. self.vx)

    else
        print("State: ON GROUND (or falling without jump)")
        -- If on ground and not charging/jumping, allow free horizontal movement
        if love.keyboard.isDown("a") then
            self.vx = -MOVE_SPEED
            print("Input: A pressed (free move)")
        elseif love.keyboard.isDown("d") then
            self.vx = MOVE_SPEED
            print("Input: D pressed (free move)")
        else
            self.vx = 0
            print("Input: No horizontal (free move)")
        end
        -- Reset committedJumpVx when on the ground and not charging.
        -- This ensures that the committed jump direction is fresh for the next jump.
        if self.onGround then -- Only reset if truly on ground, not just falling
             self.committedJumpVx = 0
        end
    end

    print(string.format("VX after state logic: %.2f, CommittedVX: %.2f", self.vx, self.committedJumpVx))

    -- Move and check collisions
    -- 1. Horizontal movement
    local oldX = self.x
    self.x = self.x + self.vx * dt

    for _, platform in ipairs(platforms) do
        if self:checkCollision(platform) then
            print("X-COLLISION DETECTED!")
            if self.vx > 0 then
                self.x = platform.x - self.width
            elseif self.vx < 0 then
                self.x = platform.x + platform.width
            end
            self.vx = 0
            if self.isJumping then -- Only reset committedJumpVx if hitting a wall while jumping
                self.committedJumpVx = 0
            end
        end
    end

    -- 2. Vertical movement
    self.y = self.y + self.vy * dt

    local wasOnGround = self.onGround
    self.onGround = false

    for _, platform in ipairs(platforms) do
        if self:checkCollision(platform) then
            print("Y-COLLISION DETECTED! vy=" .. self.vy)
            if self.vy > 0 then
                -- Landing on top of platform
                self.y = platform.y - self.height
                self.vy = 0
                self.onGround = true
                if self.isJumping then
                    print("LANDING - Ending jump state")
                    self.isJumping = false
                    self.committedJumpVx = 0 -- Reset committed direction on landing
                end
            elseif self.vy < 0 then
                -- Hitting platform from below (ceiling)
                self.y = platform.y + platform.height
                self.vy = 0
                print("Hit ceiling - keeping jump state and committedVx")
            end
        end
    end

    -- Jump Charging Logic
    if self.isChargingJump then
        self.jumpChargeTime = self.jumpChargeTime + dt
        if self.jumpChargeTime > self.maxJumpChargeTime then
            self.jumpChargeTime = self.maxJumpChargeTime
        end
        self.jumpStrengthMultiplier = self.jumpChargeTime / self.maxJumpChargeTime
    end

    print(string.format("--- Update End --- Final VX: %.2f, CommittedVX: %.2f", self.vx, self.committedJumpVx))
end

function Player:draw()
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    if self.isChargingJump then
        local barHeight = 5
        local barWidth = self.width * self.jumpStrengthMultiplier
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle("fill", self.x, self.y - barHeight - 5, barWidth, barHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", self.x, self.y - barHeight - 5, self.width, barHeight)

        -- Visual indicator for jump direction (nice addition!)
        if self.committedJumpVx < 0 then
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.polygon("fill",
                self.x - 5, self.y + self.height/2,
                self.x - 15, self.y + self.height/2,
                self.x - 10, self.y + self.height/2 - 5,
                self.x - 5, self.y + self.height/2)
        elseif self.committedJumpVx > 0 then
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.polygon("fill",
                self.x + self.width + 5, self.y + self.height/2,
                self.x + self.width + 15, self.y + self.height/2,
                self.x + self.width + 10, self.y + self.height/2 - 5,
                self.x + self.width + 5, self.y + self.height/2)
        end
    end

    -- Debug text (keep for now)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("VX: " .. string.format("%.0f", self.vx) .. " CommittedVX: " .. string.format("%.0f", self.committedJumpVx), self.x - 50, self.y - 30)
end

function Player:keypressed(key)
    print("\n=== KEYPRESSED: " .. key .. " ===")
    if key == "space" and self.onGround and not self.isJumping then
        self.isChargingJump = true
        self.jumpChargeTime = 0

        -- We no longer capture the initial direction *only* here.
        -- It's now continuously updated in Player:update while charging.
        -- This means if you hold space, then press 'A', then release 'A', it goes vertical.
        -- If you hold space, then press 'A', then press 'D', then release 'D', it goes right.
        -- The last direction held *before* space is released will be the one.
        -- To ensure a "no direction held means vertical" behavior upon initial press
        -- if no A/D is held, we can set committedJumpVx to 0 here.
        if not (love.keyboard.isDown("a") or love.keyboard.isDown("d")) then
            self.committedJumpVx = 0
            print("INITIAL COMMIT: VERTICAL (0) - No A/D held on space press")
        else
            print("INITIAL COMMIT: Direction will be updated in update while charging.")
        end
    end
end

function Player:keyreleased(key)
    print("\n=== KEYRELEASED: " .. key .. " ===")
    if key == "space" and self.isChargingJump then
        print("Space released while charging, committedVx = " .. self.committedJumpVx)
        self:executeJump()
        self.isChargingJump = false
    end
end

function Player:executeJump()
    print("\n=== EXECUTE JUMP ===")
    print("Before jump - VX: " .. self.vx .. ", CommittedVX: " .. self.committedJumpVx)

    self.vx = self.committedJumpVx -- This line applies the *last updated* committed direction
    self.vy = JUMP_POWER * (0.5 + 0.5 * self.jumpStrengthMultiplier)
    self.onGround = false
    self.isJumping = true
    self.jumpChargeTime = 0
    self.jumpStrengthMultiplier = 0

    print(string.format("Jump executed! VX: %.2f, VY: %.2f, CommittedVX: %.2f", self.vx, self.vy, self.committedJumpVx))
end

function Player:checkCollision(other)
    return self.x < other.x + other.width and
           self.x + self.width > other.x and
           self.y < other.y + other.height and
           self.y + self.height > other.y
end

return Player