local trans = require "trans"
local image = require "image"

-- mandatory progression: cooling > power > comms
-- optional upgrades: navigation (route)

local player = {
    Thrust = 100,
    MaxVelocity = 500,

    image = image.LayeredImage:new({},
        image.Sprite { "assets/images/boat_small.png", ox = 16, oy = 16 }
            :addAnim("idle")
                :addFrame(1,1)
            :addAnim("fly")
                :addFrame(2,1)
                :addFrame(3,1)
                :addFrame(4,1)
            :addAnim("brake")
                :addFrame(1,1, nil, "idle"),
        image.Sprite { "assets/images/boat_trail.png", x = -0.5, y = 7, ox = 8, oy = -1 }
            :addAnim("idle")
                :addFrame(1,1, { visible = false })
            :addAnim("fly")
                :addFrame(1,1)
                :addFrame(2,1)
                :addFrame(3,1)
                :addFrame(4,1)
                :addFrame(5,1, nil, 4)
            :addAnim("brake")
                :addFrame(4,1)
                :addFrame(3,1)
                :addFrame(2,1)
                :addFrame(1,1, nil, "idle")

    ),

    scrap = 0,
    items = {},
    total_items = 0,
    discovered = {},
    total_discoveries = 0,

    x = 0, y = 0,
    vel = 0,
    acc = 0,

    heading = 0,
    heading_to = 0,
}

function player:reset()
    self.image:setAnim("idle")

    self.scrap = 0
    self.items = {}
    self.total_items = 0
    self.discovered = {}
    self.total_discoveries = 0

    self.x = 0
    self.y = 0
    self.vel = 0
    self.acc = 0

    self.heading = 0
    self.heading_to = 0
end

player.image:setAnim("idle")

function player:update(dt)
    -- make sure to take the shortest path
    if math.abs(self.heading - self.heading_to) > math.pi then
        if self.heading > self.heading_to then
            self.heading = self.heading - 2 * math.pi
        else
            self.heading = self.heading + 2 * math.pi
        end
    end

    -- smoothish rotation
    if math.abs(self.heading - self.heading_to) >= 2 * math.pi / 180 then
        self.heading = self.heading * 0.98 + self.heading_to * 0.02
    else
        self.heading = self.heading_to
    end


    -- thrust
    if self.disabled then
        self.acc = 0
        self.vel = 0
        self.image.visible = false
    else
        self.image.visible = true
    end

    self.vel = trans.clamp(self.vel + self.acc * dt, -self.MaxVelocity * (self.acc / self.Thrust), self.MaxVelocity * (self.acc / self.Thrust))

    local vx = self.vel * math.cos(self.heading - math.pi/2)
    local vy = self.vel * math.sin(self.heading - math.pi/2)

    -- space friction!
    if self.acc == 0 then
        if self.vel > 50 then
            self.vel = self.vel * 0.99
        else
            self.vel = 0
        end
    end
    
    self.x = self.x + vx * dt
    self.y = self.y + vy * dt

    self.image:update(dt)
end

function player:draw()
    lg.push()
    self.image.r = self.heading
    lg.translate(self.x, self.y)

    self.image:draw()
    lg.pop()
end

return player