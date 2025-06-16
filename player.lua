-- player.lua
local Player = {}
Player.__index = Player

-- Player properties
local PLAYER_WIDTH = 20
local PLAYER_HEIGHT = 40
local MOVE_SPEED = 150
local JUMP_POWER = -600
local GRAVITY = 800
local INITIAL_SLIDE_SPEED = 50  -- Initial slow slide speed
local MAX_SLIDE_SPEED = 400     -- Maximum slide speed
local SLIDE_ACCELERATION = 150  -- How fast slide speed increases per second
local WALL_JUMP_POWER = -500    -- Slightly less than normal jump

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
        committedJumpVx = 0,
        prevX = x,
        prevY = y,
        -- Wall sliding properties
        isOnWall = false,
        wallSide = 0, -- -1 for left wall, 1 for right wall
        isSliding = false,
        slideSpeed = INITIAL_SLIDE_SPEED,
        slideTime = 0,
        lastJumpDirection = 0, -- Track the last horizontal jump direction
    }
    setmetatable(o, self)
    return o
end

function Player:update(dt, platforms)
    self.prevX = self.x
    self.prevY = self.y

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Check if we're touching a wall
    local touchingWall = false
    local wallPlatform = nil
    
    -- First, check for wall contact before moving
    for _, platform in ipairs(platforms) do
        if platform.type == "vertical" then
            -- Check if we're touching the wall from either side
            local touchingFromLeft = (self.x + self.width >= platform.x and 
                                    self.x + self.width <= platform.x + 5) and
                                   (self.y + self.height > platform.y and 
                                    self.y < platform.y + platform.height)
            
            local touchingFromRight = (self.x <= platform.x + platform.width and 
                                     self.x >= platform.x + platform.width - 5) and
                                    (self.y + self.height > platform.y and 
                                     self.y < platform.y + platform.height)
            
            if touchingFromLeft or touchingFromRight then
                touchingWall = true
                wallPlatform = platform
                self.wallSide = touchingFromLeft and 1 or -1
                break
            end
        end
    end

    -- Update wall state
    self.isOnWall = touchingWall and not self.onGround

    -- Handle wall sliding
    if self.isOnWall and love.keyboard.isDown("w") and self.vy > 0 and not self.isChargingJump then
        if not self.isSliding then
            -- Just started sliding
            self.isSliding = true
            self.slideTime = 0
            self.slideSpeed = INITIAL_SLIDE_SPEED
        else
            -- Continue sliding, increase speed over time
            self.slideTime = self.slideTime + dt
            self.slideSpeed = math.min(INITIAL_SLIDE_SPEED + SLIDE_ACCELERATION * self.slideTime, MAX_SLIDE_SPEED)
        end
        
        -- Apply slide speed (limit downward velocity)
        self.vy = math.min(self.vy, self.slideSpeed)
        
        -- Keep player attached to wall
        if wallPlatform then
            if self.wallSide == 1 then
                self.x = wallPlatform.x - self.width
            else
                self.x = wallPlatform.x + wallPlatform.width
            end
        end
    else
        -- Stop sliding if: not on wall, not holding W, or started charging jump
        if self.isSliding and (not self.isOnWall or not love.keyboard.isDown("w") or self.isChargingJump) then
            self.isSliding = false
            self.slideTime = 0
        end
    end

    -- Debug prints
    print(string.format("--- Update Start --- dt: %.3f", dt))
    print(string.format("States: Charging=%s, Jumping=%s, OnGround=%s, OnWall=%s, Sliding=%s",
                        tostring(self.isChargingJump), tostring(self.isJumping), 
                        tostring(self.onGround), tostring(self.isOnWall), tostring(self.isSliding)))
    print(string.format("Current VX: %.2f, Committed VX: %.2f", self.vx, self.committedJumpVx))

    -- Determine horizontal movement based on states
    if self.isChargingJump then
        print("State: CHARGING JUMP")
        self.vx = 0 -- Player STOPS horizontally while charging

        -- Special handling for wall jumps
        if self.isOnWall then
            -- Force jump direction away from wall
            self.committedJumpVx = -self.wallSide * MOVE_SPEED
            print("Wall jump commitment: " .. (self.wallSide == -1 and "RIGHT" or "LEFT"))
        else
            -- Normal ground jump direction selection
            if love.keyboard.isDown("a") then
                self.committedJumpVx = -MOVE_SPEED
                print("Updated commitment: LEFT (-" .. MOVE_SPEED .. ")")
            elseif love.keyboard.isDown("d") then
                self.committedJumpVx = MOVE_SPEED
                print("Updated commitment: RIGHT (" .. MOVE_SPEED .. ")")
            else
                self.committedJumpVx = 0
                print("Updated commitment: VERTICAL (0)")
            end
        end

    elseif self.isJumping then
        print("State: JUMPING")
        self.vx = self.committedJumpVx

    else
        print("State: ON GROUND (or falling without jump)")
        -- Don't allow horizontal movement while sliding (but still allow while charging on wall)
        if not self.isSliding or self.isChargingJump then
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
        else
            self.vx = 0 -- No horizontal movement while sliding
        end
        
        if self.onGround then
            self.committedJumpVx = 0
        end
    end

    -- Move and check collisions
    -- 1. Horizontal movement
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
            if self.isJumping then
                self.committedJumpVx = 0
            end
        end
    end

    -- 2. Vertical movement
    self.y = self.y + self.vy * dt

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
                    self.committedJumpVx = 0
                end
            elseif self.vy < 0 then
                -- Hitting platform from below
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

    -- Track last jump direction for wall jump logic
    if self.isJumping and self.committedJumpVx ~= 0 then
        self.lastJumpDirection = self.committedJumpVx > 0 and 1 or -1
    end
end

function Player:draw()
    -- Draw player with different color if sliding
    if self.isSliding then
        love.graphics.setColor(0.2, 0.4, 0.8, 1) -- Blue when sliding
    else
        love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green normally
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Draw slide speed indicator when sliding
    if self.isSliding then
        local speedRatio = (self.slideSpeed - INITIAL_SLIDE_SPEED) / (MAX_SLIDE_SPEED - INITIAL_SLIDE_SPEED)
        local barHeight = 3
        local barWidth = self.width * speedRatio
        love.graphics.setColor(1, 0.5, 0, 0.8) -- Orange for slide speed
        love.graphics.rectangle("fill", self.x, self.y - barHeight - 2, barWidth, barHeight)
    end

    if self.isChargingJump then
        local barHeight = 5
        local barWidth = self.width * self.jumpStrengthMultiplier
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle("fill", self.x, self.y - barHeight - 5, barWidth, barHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", self.x, self.y - barHeight - 5, self.width, barHeight)

        -- Visual indicator for jump direction
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

    -- Debug text
    -- Debug text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("VX: " .. string.format("%.0f", self.vx) .. " CommittedVX: " .. string.format("%.0f", self.committedJumpVx), self.x - 50, self.y - 30)
    if self.isSliding then
        love.graphics.print("Slide Speed: " .. string.format("%.0f", self.slideSpeed), self.x - 50, self.y - 45)
    end
end

function Player:keypressed(key)
    print("\n=== KEYPRESSED: " .. key .. " ===")
    -- Allow jumping while sliding by checking isOnWall OR isSliding
    if key == "space" and (self.onGround or self.isOnWall or self.isSliding) and not self.isJumping then
        self.isChargingJump = true
        self.jumpChargeTime = 0

        -- Wall jump always goes away from wall
        if self.isOnWall or self.isSliding then
            self.committedJumpVx = -self.wallSide * MOVE_SPEED
            print("WALL JUMP COMMIT: " .. (self.wallSide == -1 and "RIGHT" or "LEFT"))
        else
            -- Ground jump - check for direction
            if not (love.keyboard.isDown("a") or love.keyboard.isDown("d")) then
                self.committedJumpVx = 0
                print("INITIAL COMMIT: VERTICAL (0) - No A/D held on space press")
            else
                print("INITIAL COMMIT: Direction will be updated in update while charging.")
            end
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

    self.vx = self.committedJumpVx
    
    -- Use different jump power for wall jumps
    if self.isOnWall or self.isSliding then
        self.vy = WALL_JUMP_POWER * (0.5 + 0.5 * self.jumpStrengthMultiplier)
        self.isSliding = false -- Stop sliding when jumping
        self.slideTime = 0
    else
        self.vy = JUMP_POWER * (0.5 + 0.5 * self.jumpStrengthMultiplier)
    end
    
    self.onGround = false
    self.isOnWall = false
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