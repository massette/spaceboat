local m = love.math
local g = love.graphics

local mush = require("src.mush.types")

local im = g.newImage("assets/images/objects/stars.png")
local q = {
    g.newQuad(0,  0, 5, 5, im:getDimensions()),
    g.newQuad(5,  0, 5, 5, im:getDimensions()),
    g.newQuad(10, 0, 5, 5, im:getDimensions()),
    g.newQuad(15, 0, 5, 5, im:getDimensions()),
    g.newQuad(20, 0, 5, 5, im:getDimensions())
}

--- @class (exact) spaceboat.Stars
--- @field private layers love.SpriteBatch[]
--- @field size mush.Size
local stars = {
    layers = {},
    size = mush.Size { 0, 0 }
}

-- initialize layers
for i = 1, #q do
    stars.layers[i] = g.newSpriteBatch(im)
end

function stars:generate(width, height)
    local DENSITY = 0.00012

    stars.size = mush.Size { width, height }

    for size, layer in ipairs(self.layers) do
        layer:clear()

        local layer_width = width * size
        local layer_height = height * size

        for _ = 1, (layer_width * layer_height) * DENSITY do
            local x = m.random(0, layer_width)
            local y = m.random(0, layer_height)
            local a = m.random(15, 95) / 100

            self.layers[size]:setColor(0.50 + 0.50 * a, 0.50 + 0.50 * a, 0.50 + 0.50 * a, a)
            self.layers[size]:add(q[size], x,               y)
            self.layers[size]:add(q[size], x + layer_width, y)
            self.layers[size]:add(q[size], x              , y + layer_height)
            self.layers[size]:add(q[size], x + layer_width, y + layer_height)
        end
    end

    return self
end

function stars:draw(x, y)
    for size, layer in ipairs(self.layers) do
        g.draw(layer,
            math.floor(math.floor(x / stars.size.width)  * stars.size.width  - (size * stars.size.width / 2)  - (size - 1) * (x % stars.size.width)),
            math.floor(math.floor(y / stars.size.height) * stars.size.height - (size * stars.size.height / 2) - (size - 1) * (y % stars.size.height)))
    end
end

--[[ Export ]]-------------------------------------------------
return stars