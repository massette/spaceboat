local g = love.graphics

--- @class camera
--- @field canvas love.Canvas?
--- @field width number
--- @field height number
--- @field scale number
--- @field x number
--- @field y number
--- @field angle number
--- @field zoom number
local camera = {
    canvas = nil,
    width = 0, height = 0,
    scale = 1,

    x = 0, y = 0,
    angle = 0,
    zoom = 1,
}

local minw, minh = 0, 0

--[[ Setup Functions ]]----------------------------------------
--- Initialize camera canvas.
--- Can be chained.
--- @param width number
--- @param height number
function camera:setup(width, height)
    minw, minh = width, height

    self.canvas = g.newCanvas(width, height)
    self.width, self.height = width, height

    return self
end

--- Resize camera canvas to fit within the given dimensions.
--- Can be chained.
--- @param width number
--- @param height number
--- @param keep_ratio boolean?
--- @param keep_int boolean?
function camera:resize(width, height, keep_ratio, keep_int)
    self.scale = math.min(
        width / minw,
        height / minh
    )

    if not keep_ratio then
        self.width = math.ceil(width / self.scale)
        self.height = math.ceil(height / self.scale)

        self.canvas = g.newCanvas(self.width, self.height)
    end

    if keep_int then
        self.scale = math.floor(self.scale)
    end

    return self
end

--[[ Transform Functions ]]-------------------------------------
--- Apply camera transforms.
--- @param no_pos boolean?
--- @param no_zoom boolean?
--- @param no_center boolean?
function camera:transform(no_pos, no_zoom, no_center)
    if not no_center then
        g.translate(self.width / 2, self.height / 2)
    end

    if not no_zoom then
        g.scale(self.zoom)
    end

    -- TODO: add rotation

    if not no_pos then
        g.translate(-self.x, -self.y)
    end
end

--- Center the camera on a canvas coordinate.
--- @param x number
--- @param y number
--- @param w number?
--- @param h number?
function camera:follow(x, y, w, h)
    local cutoff, strength = 0.1, 0.07
    
    w = w or math.min(self.width, self.height) / 2
    h = h or w

    local dx = x - self.x
    local dy = y - self.y

    if math.abs(dx) < cutoff then
        self.x = x
    elseif dx >  w / 2 then
        self.x = x - w / 2
    elseif dx < -w / 2 then
        self.x = x + w / 2
    end

    if math.abs(dy) < cutoff then
        self.y = y
    elseif dy >  h / 2 then
        self.y = y - h / 2
    elseif dy < -h / 2 then
        self.y = y + h / 2
    end

    self.x = self.x + (x - self.x) * strength
    self.y = self.y + (y - self.y) * strength
end

--[[ Draw Functions ]]-----------------------------------------
--- Start drawing to camera canvas.
function camera:set()
    g.setCanvas(self.canvas)
    g.setColor(1,1,0)
    g.circle("fill", 0,0, 3)
end

--- Stop drawing to camera canvas.
function camera:unset()
    g.setCanvas()
end

--- Draw the camera canvas.
--- @param x number?
--- @param y number?
function camera:draw(x, y)
    g.setColor(1, 1, 1, 1)
    g.draw(self.canvas, x, y, 0, self.scale)
end

--[[ Export ]]-------------------------------------------------
return camera