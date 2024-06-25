local g = love.graphics

-- Animation --------------------------------------------
local Anim = {}

function Anim:new(options)
    options.image = options.image or options[1]
    assert(options.image ~= nil, "Expected required argument 'image', received nil.")
    
    options.default_delay = options.default_delay or options[2] or 0.1
    options.timer = options.timer or 0

    options.frames = options.frames or {}
    options.frame = options.frame or 1

    options[1] = nil
    options[2] = nil

    return setmetatable(options, { __index = Anim })
end

-- ...
--- @param x number
--- @param y number
--- @param state table? @ A table specifying changes to the Sprite on this frame of animation.
--- @param next_state table? @ A table specifying changes to the animation state after this frame of animation.
--- @param delay number?
function Anim:addFrame(x, y, state, next_state, delay)
    assert(y ~= nil, "Expected required argument 'x', received nil.")
    assert(x ~= nil, "Expected required argument 'y', received nil.")

    state = state or {}
    state.quad = g.newQuad((x - 1) * self.image.sprite_width, (y - 1) * self.image.sprite_height, self.image.sprite_width, self.image.sprite_height, self.image.width, self.image.height)

    next_state = next_state or {}
    if type(next_state) == "number" then
        next_state = { nil, next_state }
    elseif type(next_state) == "string" then
        next_state = { next_state, nil }
    end

    self.frames[#self.frames + 1] = {
        image = setmetatable(state, { __index = self.image }),
        next_anim = next_state[1],
        next_frame = next_state[2] or (#self.frames + 2),
        delay = delay or self.default_delay,
    }
end

function Anim:next()
    local frame = self.frames[self.frame]

    if frame.next_anim ~= nil then
        self.image:setAnim(frame.next_anim)
    end
    
    self.frame = frame.next_frame or self.frame
    self.frame = (self.frame - 1) % #self.frames + 1

    return self.frame
end

function Anim:animate(dt)
    assert(#self.frames > 0, "Cannot draw an animation with 0 frames. Add frames with Anim:addFrame(...).")

    if self.timer < self.frames[self.frame].delay then
        self.timer = self.timer + dt
    else
        self.timer = 0
        return self:next()
    end
end

-- Sprite -----------------------------------------------
local Sprite = {}

function Sprite:new(options)
    options.filename = options[1] or options.filename
    assert(options.filename ~= nil, "Expected required argument 'filename', received nil.")

    options.image = options.image or g.newImage(options.filename)
    options.color = options.color or { 1, 1, 1, 1 }
    options.quad = options.quad or nil
    options.visible = options.visible or true

    options.width, options.height = options.image:getDimensions()
    options.sprite_width = options[2] or options.sprite_width or options.height
    options.sprite_height = options[3] or options.sprite_height or options.sprite_width

    options.x = options[4] or options.x or 0
    options.y = options[5] or options.y or 0

    options.r = options.r or 0

    options.sx = options.sx or 1.0
    options.sy = options.sy or 1.0

    options.ox = options.ox or (options.sw / 2)
    options.oy = options.oy or (options.sh / 2)

    options.anim = nil
    options.anims = options.anims or {}

    options[1] = nil
    options[2] = nil
    options[3] = nil

    return setmetatable(options, { __index = Sprite })
end

function Sprite.fromImage(image)
    return Sprite {
        filename = "...",
        image = image,
    }
end

function Sprite:addAnim(name, options)
    assert(name ~= nil, "Expected required argument 'name' received nil.")
    assert(self.anims[name] == nil, "Animation '" .. name .. "' already exists.")

    options = options or {}
    options.image = self
    self.anims[name] = Anim:new(options)
    self:setAnim(name)

    return self
end

function Sprite:setAnim(name, frame)
    assert(self.anims[name] ~= nil, "Animation '"..name.."' does not exist.")

    self.anim = name
    self.anims[name].frame = frame or 1
    self.anims[name].timer = 0
end

function Sprite:addFrame(...)
    self.anims[self.anim]:addFrame(...)
    return self
end

function Sprite:update(dt)
    self.anims[self.anim]:animate(dt)
end

function Sprite:draw()
    local im = self
    if self.anim ~= nil then
        local anim = self.anims[self.anim]
        im = anim.frames[anim.frame].image
    end

    if not im.visible then
        return
    end

    love.graphics.setColor(im.color)
    if im.quad == nil then
        g.draw(self.image, im.x, im.y, im.r, im.sx, im.sy, im.ox, im.oy)
    else
        g.draw(self.image, im.quad, im.x, im.y, im.r, im.sx, im.sy, im.ox, im.oy)
    end
end

setmetatable(Sprite, { __call = Sprite.new })

-- LayeredImage -----------------------------------------------
local LayeredImage = {}

function LayeredImage:new(options, ...)
    options = options or {}
    options.images = options.images or { ... }
    options.anim = options.anim or nil

    options.visible = options.visible or true

    options.x = options[1] or options.x or 0
    options.y = options[2] or options.y or 0
    
    options.r = options[3] or options.r or 0
    
    options.sx = options[4] or options.sx or 1.0
    options.sy = options[5] or options.sy or 1.0

    return setmetatable(options, { __index = LayeredImage })
end

function LayeredImage:call(fn, ...)
    for _, image in ipairs(self.images) do
        if type(image[fn]) == "function" then
            image[fn](image, ...)
        end
    end
end

for _, fn in ipairs({ "update", "setAnim" }) do
    LayeredImage[fn] = function(self, ...)
        self:call(fn, ...)
    end
end

function LayeredImage:draw()
    if not self.visible then
        return
    end

    g.push()
    g.rotate(self.r)
    g.translate(self.x, self.y)
    g.scale(self.sx, self.sy)

    for _, image in ipairs(self.images) do
        image:draw()
    end

    g.pop()

    self.anim = self.images[1].anim
end

setmetatable(LayeredImage, {
    __call = LayeredImage.new
})

-- Export -----------------------------------------------------
return {
    LayeredImage = LayeredImage,
    Sprite = Sprite,
}