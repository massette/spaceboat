--[[
    mush.cam
    A simple game camera for löve with a focus on pixel art.
--]]

local g = love.graphics
local m = love.math

local mush = require("src.mush.types")
local trans = require("src.util.trans")

--- @class (exact) mush.Camera
--- @field private canvas love.Canvas? @ Camera canvas.
--- @field scale number                @ Canvas scale, applied after each draw. (>= 1)
--- @field world love.Transform        @ World transform, updated before each draw.
--- @field pos mush.Point              @ Center of the visible region.
--- @field off mush.Point              @ Positional offset from cam.pos.
--- @field dir number                  @ Rotation of the visible region.
--- @field zoom number                 @ World scale, applied before each draw.
--- @field min mush.Size               @ Minimum size of the visible region.
--- @field size mush.Size              @ Size of the visible region.
--- @field dest mush.Size              @ Size of the canvas after scaling.
local cam = {
    canvas = nil,
    scale = 1,

    world = m.newTransform(),
    pos = mush.Point { 0, 0 },
    off = mush.Point { 0, 0 },
    dir = 0,
    zoom = 1,

    min = mush.Size { 0, 0 },
    size = mush.Size { 0, 0 },
    dest = mush.Size { 0, 0 },
}

--[[ Setup ]]--------------------------------------------------
--- Initialize the camera canvas.
--- @param width number
--- @param height number
--- @param scale number?
--- @return mush.Camera
function cam:init(width, height, scale)
    self.canvas = g.newCanvas(width, height)
    self.scale = scale or 1

    self.pos = mush.Point { 0, 0 }
    self.off = mush.Point { 0, 0 }
    self.dir = 0
    self.zoom = 1

    self.min = mush.Size { width, height }
    self.size = mush.Size { width, height }
    self.dest = mush.Size { width * self.scale, height * self.scale }

    return self
end

--- Resize camera canvas to fit within the given dimensions.
--- @param width number
--- @param height number
--- @param keep_int boolean?
--- @param keep_ratio boolean?
--- @return mush.Camera
function cam:resize(width, height, keep_int, keep_ratio)
    self.dest = mush.Size { width, height }
    self.scale = math.min(width / self.min.width, height / self.min.height)
    self.scale = math.max(self.scale, 1)

    if keep_int ~= false then -- treat nil as true
        self.scale = math.floor(self.scale)
    end

    if not keep_ratio then -- treat nil as false
        -- based on [alterae's screen manager](https://github.com/alterae/hello-love/blob/main/lib/screen.lua)
        self.size.width = math.ceil(width / self.scale)
        self.size.height = math.ceil(height / self.scale)

        -- only need to create newproxy canvas if aspect ratio changes
        self.canvas = g.newCanvas(self.size.width, self.size.height)
    end

    return self
end

--[[ Update ]]-------------------------------------------------
local follow_dist = 0

--- Follow a point in world-space at a fixed distance.
--- @param x number
--- @param y number
--- @param d number
function cam:follow(x, y, d)
    -- TODO: fix jittering

    local dir = math.atan2(self.pos.y - y, self.pos.x - x)

    if d ~= 1.00 then
        local dist = math.sqrt( (self.pos.x - x)^2 + (self.pos.y - y)^2 )
        follow_dist = 0.98 * dist
    end

    self.pos.x = x + follow_dist * math.cos(dir)
    self.pos.y = y + follow_dist * math.sin(dir)
end

--[[ Draw ]]---------------------------------------------------
--- Start drawing to canvas, must be followed by a cam:unset call.
function cam:set()
    g.push("all")

    g.setCanvas(self.canvas)
    g.clear()
end

--- Apply transforms before drawing world.
function cam:transform()
    -- update transform
    self.world:reset()
        :translate(
            math.floor(self.size.width / 2),
            math.floor(self.size.height / 2)
        )
        :scale(self.zoom)
        :rotate(self.dir)
        :translate(
            -math.floor(self.pos.x - self.off.x),
            -math.floor(self.pos.y - self.off.y)
        )
    
    -- apply transform
    g.replaceTransform(self.world)
end

--- Stop drawing to canvas, must follow a cam:set call.
function cam:unset()
    g.pop()

    g.push("all")
    g.setColor(1, 1, 1, 1)
    g.setBlendMode("alpha", "premultiplied")

    -- TODO: smooth camera movement
    g.draw(self.canvas,
        (self.dest.width - self.size.width * self.scale) / 2,
        (self.dest.height - self.size.height * self.scale) / 2,
        0, self.scale)
    
    g.pop()
end

--[[ Export ]]-------------------------------------------------
return cam