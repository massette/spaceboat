local trans = require("src.util.trans")
local anim = require("src.mush.anim")

-- mandatory progression: cooling > power > comms
-- optional upgrades: navigation (route)
local player = {
    Thrust = 100,
    MaxVelocity = 500,

    image = anim.Sprite.new { "assets/images/objects/boat.png", 32 }
        :addAnimation("idle")
            :addFrame(1)
        :addAnimation("fly")
            :addFrame(2)
            :addFrame(3)
            :addFrame(4)
            :addFrame(5, 4)
        :addAnimation("brake")
            :addFrame(4)
            :addFrame(3)
            :addFrame(2)
            :addFrame(1, "idle"),

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
    self.image:setAnimation("idle")

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

player.image:setAnimation("idle")

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
    if self.disabled then
        return
    end

    lg.push()

    self.image.settings.r = self.heading
    self.image:draw(self.x, self.y)

    lg.pop()
end

return player