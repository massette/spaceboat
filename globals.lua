-- this is an awful shorthand that i regret adopting, i blame love.window
lk = love.keyboard
lw = love.window
lg = love.graphics
lm = love.math
la = love.audio

lg.setDefaultFilter("nearest")

Error = {
    ReassignConstant = "Attempted to modify a read-only value.\n",
    OutOfRange = function(a, b,c)
        return "Out of range. Expected value between " .. b .. " and " .. c .. ", received " .. a .. ".\n"
    end,
    MissingArgs = function (a,b)
        return "Expected " .. b .. " positional argument(s), received " .. a .. ".\n"
    end,
    TypeMismatch = function (a, b)
        return "Type mismatch. Expected " .. b .. ", received " .. a .. ".\n"
    end,
    Connected = function (a)
        return "Already connected to station " .. a .. "\n"
    end,
    NotConnected = function (a)
        return "Cannot " .. a .. ". Not connected to any station.\n"
    end,
}

Font = {
    Terminal = lg.newImageFont("assets/images/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?_:;+-=\'\"()[]", 1)
}

Color = {
    BG              = { 0.00, 0.05, 0.20, 1.00 },

    TerminalBG      = { 0.00, 0.05, 0.20, 0.70 },
    TerminalOutline = { 1.00, 1.00, 1.00, 1.00 },

    TerminalDefault = { 0.67, 0.67, 1.00, 1.00 },
    TerminalInput   = { 1.00, 1.00, 1.00, 1.00 },
    TerminalInfo    = { 1.0, 1.0, 1.00, 1.00 },
    TerminalError   = { 1.00, 0.00, 0.20, 1.00 },

    StationDefault  = { 0.67, 0.67, 1.00, 1.00 },
    StationFound    = { 0.87, 0.87, 1.00, 1.00 },

    Debris          = { 1.00, 1.00, 1.00, 1.00 }
}

World = {
    width = 300 * 50,
    height = 200 * 50,
    stations = {},
    Items = {
        ["nav"] = "Navigation subsystem",
        ["cooling"] = "Cooling subsystem",
        ["power"] = "Power subsystem",
        ["comm"] = "Communication subsystem",
    }
}

function World.nearestStation(tx, ty)
    local nearest, nearest_i, nearest_dist
    for i, station in ipairs(World.stations) do
        local dist = math.sqrt((station.x - tx)^2 + (station.y - ty)^2)
        
        if dist > 0.001 and  (nearest_dist == nil or dist < nearest_dist) then
            nearest = station
            nearest_dist = dist
            nearest_i = i
        end
    end

    return nearest, nearest_i, nearest_dist
end

Timer = 0

function print_table(t, indent)
    indent = indent or 0

    for key, value in pairs(t) do
        if type(value) == "table" then
            if next(value) == nil then
                print(string.rep("  ", indent) .. "[\"" .. tostring(key) .. "\"] = {},")
            else
                print(string.rep("  ", indent) .. "[\"" .. tostring(key) .. "\"] = {")
                print_table(value, indent + 1)
                print(string.rep("  ", indent) .. "},")
            end
        else
            print(string.rep("  ", indent) .. "[\"" .. tostring(key) .. "\"] = (" .. tostring(value) .. "),")
        end
    end
end