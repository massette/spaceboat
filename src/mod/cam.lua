local trans = require("src/util/trans")

local cam = {
    x = 0, y = 0,
    r = 0,
    scale = 1.0,
    ox = 0, oy = 0,

    inner_width = 0,
    inner_height = 0,
    
    canvas = nil,
    canvas_width = 0,
    canvas_height = 0,
    canvas_scale = 1.0,

    window = {
        width = 0, height = 0,
        flags = {
            fullscreen = false,
            fullscreentype = "desktop",
            resizable = true,

            minwidth = 0,
            minheight = 0,
        }
    },

    timer = nil,
}

function cam:setup(src_width, src_height)
    self.src_width = src_width
    self.src_height = src_height

    self.window.flags.minwidth = src_width
    self.window.flags.minheight = src_height
    self.window.width, self.window.height = lg.getDimensions()

    lw.setMode(self.window.width, self.window.height, self.window.flags)
    self:fit(self.window.width, self.window.height)

    return self
end

-- Scales the canvas to fit within the given dimension.
function cam:fit(width, height)
    self.window.width = width
    self.window.height = height

    self.canvas_scale = math.min(
        width / self.src_width,
        height / self.src_height
    )

    self.canvas = lg.newCanvas(math.ceil(width / self.canvas_scale), math.ceil(height / self.canvas_scale))
    self.canvas_width, self.canvas_height = self.canvas:getDimensions()

    return self
end

function cam:follow(x, y, max, min)
    local dir = math.atan2(y - self.y, x - self.x)
    local mag = math.sqrt((y - self.y)^2 + (x - self.x)^2)

    if max ~= nil and mag - max > 0.001 then
        self.x = x - max * math.cos(dir)
        self.y = y - max * math.sin(dir)
    elseif min == nil or mag - min > 0.001 then
        self.x = self.x + mag * math.cos(dir) * 0.03
        self.y = self.y + mag * math.sin(dir) * 0.03
    else
        self.x = x
        self.y = y
    end
end

-- Drawing ---------------------------------------------
function cam:prepare() end
function cam:prepareStatic() end
function cam:prepareUI() end

function cam:draw(x, y)
    lg.setCanvas(self.canvas)
    lg.clear(Color.BG)

    self:prepareStatic()

    -- rotate and scale about the point (x, y) as the origin
    lg.push()
    lg.translate(-self.x - self.ox, -self.y - self.oy)
    lg.scale(self.scale)
    lg.rotate(self.r)

    -- center the view on (x, y)
    lg.translate(self.canvas_width/2, self.canvas_height/2)

    self:prepare()
    lg.pop()

    self:prepareUI()
    lg.setCanvas()

    lg.setColor(1, 1, 1, 1)
    lg.draw(cam.canvas, x or 0, y or 0, 0, self.canvas_scale)
end

-- Export ----------------------------------------------
return cam