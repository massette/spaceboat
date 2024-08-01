
local err = require "src.mush.error"

local g = love.graphics

local trans = require("src.util.trans")

--[[ DEFINITIONS ]] -------------------------------------------
--- @class Animation
--- @field sprite Sprite
--- @field defaultDelay number
--- @field frames table<integer, table>
--- @field next table<integer, integer | string>
--- @field timer number
--- @field progress number
--- @field frame integer
--- @field data table<string, any>
local Animation = { type = "Animation" }

--- @class Sprite
--- @field filename? string
--- @field image love.Image
--- @field spriteWidth number
--- @field spriteHeight number
--- @field sheetWidth number
--- @field sheetHeight number
--- @field animations table<string, Animation>
--- @field animation string
--- @field quad love.Quad
--- @field r number
--- @field sx number
--- @field sy number
--- @field ox number
--- @field oy number
--- @field defaults table<string, any>
--- @field settings table<string, any>
local Sprite = { type = "Sprite" }

--[[ ANIMATION ]] ---------------------------------------------
-- Create a new Animation.
--- @param options table
--- @return Animation
function Animation.new(options)
    options.sprite = options[1] or options.sprite
    err.expect(options.sprite, "sprite", "Sprite")

    options.defaultDelay = options[2] or options.defaultDelay or 0.1

    options[1] = nil
    options[2] = nil

    options.frames = options.frames or {}
    options.next = options.next or {}

    options.timer = options.timer or 0
    options.progress = options.progress or 0.0

    options.frame = options.frame or 0
    options.data = options.frames[options.frame] or {}

    return setmetatable(options, { __index = Animation })
end

-- Add a frame.
--- @param frame number @ An index in the spritesheet to draw.
--- @param next_frame? number | string
--- @param delay? number
--- @param data? table
function Animation:add(frame, next_frame, delay, data)
    err.expect(frame, "frame", "number")
    self.next[self.frame] = frame
    self.next[frame] = next_frame or nil

    data = data or {}
    data.delay = delay or self.defaultDelay

    self.frames[frame] = data
    self.frame = frame

    return self
end

-- Jump to a frame.
--- @param frame? integer
function Animation:set(frame)
    --- @type integer
    --- @diagnostic disable-next-line: assign-type-mismatch
    frame = frame or self.next[0]

    self.frame = frame or self.frame
    self.data = self.frames[self.frame]
    self.timer = 0
end

-- Loop the animation.
--- @param n? number
function Animation:loop(n)

end

-- Update the animation.
--- @param dt number @ Time since last update.
function Animation:animate(dt)
    if self.timer < self.data.delay then
        self.timer = self.timer + dt
    else
        local next_frame = self.next[self.frame]

        if type(next_frame) == "string" then
            self.sprite:setAnimation(next_frame)
        else
            self:set(next_frame or self.frame)
        end
    end

    self.progress = self.timer / self.data.delay
end

--[[ SPRITE ]] ------------------------------------------------
-- Create a new Sprite.
--- @param options table
function Sprite.new(options)
    options.filename = options[1] or options.filename
    options.spriteWidth = options[2] or options.spriteWidth
    options.spriteHeight = options[3] or options.spriteHeight or options.spriteWidth

    options[1] = nil
    options[2] = nil
    options[3] = nil

    if options.image == nil then
        err.expect(options.filename, "filename", "string")
        options.image = g.newImage(options.filename)
    end

    err.expect(options.spriteWidth, "spriteWidth", "number")
    err.expect(options.spriteHeight, "spriteHeight", "number")

    options.sheetWidth, options.sheetHeight = options.image:getDimensions()
    assert(options.sheetWidth % options.spriteWidth == 0, "Sheet width must be divisible by sprite width.")
    assert(options.sheetHeight % options.spriteHeight == 0, "Sheet height must be divisible by sprite height.")

    options.animations = options.animations or {}
    options.animation = options.animation or nil

    options.quad = options.quad or g.newQuad(0,0, options.spriteWidth, options.spriteHeight, options.sheetWidth, options.sheetHeight)

    options.r = options.r or 0

    options.sx = options.sx or 1
    options.sy = options.sy or 1

    options.ox = options.ox or (options.spriteWidth / 2)
    options.oy = options.oy or (options.spriteHeight / 2)
    
    options.defaults = {
        color = { 1, 1, 1, 1 },

        r = 0,

        sx = 1,
        sy = 1,

        ox = options.ox or (options.spriteWidth / 2),
        oy = options.oy or (options.spriteHeight / 2),
    }

    options.settings = {}
    for k, default in pairs(options.defaults) do
        options.settings[k] = default
    end

    return setmetatable(options, { __index = Sprite })
end

-- Create a new sprite from a preloaded image.
--- @param image userdata
--- @param w integer
--- @param h? integer
function Sprite.fromImage(image, w, h)
    return Sprite.new {
        image = image,
        [2] = w,
        [3] = h,
    }
end

-- Change the active sprite.
--- @param n integer @ An index in the spritesheet
function Sprite:setQuad(n)
    local w = self.sheetWidth / self.spriteWidth
    local h = self.sheetHeight / self.spriteHeight

    err.expect(n, "n", "number")
    err.bound(n, 1, w * h)
    n = n - 1

    local i = n % w
    local j = math.floor(n / w)

    self.quad:setViewport(i * self.spriteWidth, j * self.spriteHeight, self.spriteWidth, self.spriteHeight, self.sheetWidth, self.sheetHeight)
end

-- Add an animation.
-- Sets the new animation as active.
--- @param name string
--- @param options? table
function Sprite:addAnimation(name, options)
    err.expect(name, "name", "string")
    assert(self.animations[name] == nil, "Animation '" .. name .. "' already exists.")

    options = options or {}
    options.sprite = self
    self.animations[name] = Animation.new(options)
    self:setAnimation(name)

    return self
end

-- Change the active animation.
--- @param name string
--- @param frame? integer
function Sprite:setAnimation(name, frame)
    assert(self.animations[name] ~= nil, "Animation '" .. name .. "' does not exist.")

    if frame ~= nil then
        err.bound(frame, 1, #self.animations[name].frames, "Frame")
    end

    self.animation = name
    self.animations[name]:set(frame)
end

function Sprite:addFrame(...)
    self.animations[self.animation]:add(...)

    return self
end

function Sprite:update(dt)
    local animation = self.animations[self.animation]
    animation:animate(dt)

    self:setQuad(animation.frame)

    for k, old in ipairs(self.settings) do
        local new = animation.data[k] or self.defaults[k]

        self.settings[k] = trans.tween(old, new, animation.progress)
    end
end

function Sprite:draw(x, y)
    g.setColor(self.settings.color)
    g.draw(self.image, self.quad,
        math.floor(x),
        math.floor(y),
        self.r + self.settings.r,
        self.sx * self.settings.sx,
        self.sy * self.settings.sy,
        self.settings.ox, self.settings.oy)
end

--[[ EXPORT ]] ------------------------------------------------
return {
    Animation = Animation,
    Sprite = Sprite,
}