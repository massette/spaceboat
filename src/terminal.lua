local trans = require("src/util/trans")

-- if i have time i want to add:
--  up/down to move through command history
--  autocomplete? if its not too ambitiouss

local valid_text = {
    [" "] = true,
    ["a"] = true,
    ["b"] = true,
    ["c"] = true,
    ["d"] = true,
    ["e"] = true,
    ["f"] = true,
    ["g"] = true,
    ["h"] = true,
    ["i"] = true,
    ["j"] = true,
    ["k"] = true,
    ["l"] = true,
    ["m"] = true,
    ["n"] = true,
    ["o"] = true,
    ["p"] = true,
    ["q"] = true,
    ["r"] = true,
    ["s"] = true,
    ["t"] = true,
    ["u"] = true,
    ["v"] = true,
    ["w"] = true,
    ["x"] = true,
    ["y"] = true,
    ["z"] = true,
    ["A"] = true,
    ["B"] = true,
    ["C"] = true,
    ["D"] = true,
    ["E"] = true,
    ["F"] = true,
    ["G"] = true,
    ["H"] = true,
    ["I"] = true,
    ["J"] = true,
    ["K"] = true,
    ["L"] = true,
    ["M"] = true,
    ["N"] = true,
    ["O"] = true,
    ["P"] = true,
    ["Q"] = true,
    ["R"] = true,
    ["S"] = true,
    ["T"] = true,
    ["U"] = true,
    ["V"] = true,
    ["W"] = true,
    ["X"] = true,
    ["Y"] = true,
    ["Z"] = true,
    ["0"] = true,
    ["1"] = true,
    ["2"] = true,
    ["3"] = true,
    ["4"] = true,
    ["5"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
    ["."] = true,
    [","] = true,
    ["!"] = true,
    ["?"] = true,
    ["_"] = true,
    [":"] = true,
    [";"] = true,
    ["+"] = true,
    ["-"] = true,
    ["="] = true,
    ["'"] = true,
    ['"'] = true,
    ["("] = true,
    [")"] = true,
    ["["] = true,
    ["]"] = true,
}

local terminal = {
    Width = 200,
    Height = 190,
    Padding = 8,
    Duration = 0.5,

    --- @type (string | table)[]
    text = {},
    history = {},
    input = "",
    vars = {
        ["north"] = {
            type = "number",
            constant = true,
            value = 0.0
        },
        ["northeast"] = {
            type = "number",
            constant = true,
            value = 45.0
        },
        ["east"] = {
            type = "number",
            constant = true,
            value = 90.0
        },
        ["southeast"] = {
            type = "number",
            constant = true,
            value = 135.0
        },
        ["south"] = {
            type = "number",
            constant = true,
            value = 180.0
        },
        ["southwest"] = {
            type = "number",
            constant = true,
            value = -135.0
        },
        ["west"] = {
            type = "number",
            constant = true,
            value = -90.0
        },
        ["northwest"] = {
            type = "number",
            constant = true,
            value = -45.0
        },

        ["heading"] = {
            type = "number",
            range = { -360.0, 360.0 },
            value = 0.0,
        },
        ["thrust"] = {
            type = "number",
            range = { 0.0, 1.0 },
            value = 0.0,
        },
    },
    input_y = 0,

    open = true,
    scroll = 0,
    recall_line = nil,
    cursor_pos = 0,
    open_timer = 0.0,

    first_ping = false,
    first_connect = false,
    systems_remaining = { "nav", "cooling", "power", "comm" },

    queue = { current_message = nil },
    type_timer = 0.0,
}

function terminal:reset()
    self.text = {}
    self.history = {}
    self.input = ""
    
    self.vars["heading"].value = 0
    self.vars["thrust"].value = 0

    self.input_y = 0

    self.open = true
    self.scroll = 0
    self.recall_line = nil
    self.open_timer = 0.0

    self.first_ping = false
    self.first_connect = false
    self.systems_remaining = { "nav", "cooling", "power", "comm" }

    self.queue = {}
    self.type_timer = 0.0
end

local bloop = la.newSource("assets/sounds/bloop.wav", "static")
local ping = la.newSource("assets/sounds/ping.wav", "static")

-- Argument parsing stuff -------------------------------------
function terminal:type_eval(str)
    str = string.lower(str)

    if str == "true" or str == "on" or str == "false" or str == "off" then
        return "boolean"
    elseif string.match(str, "^-?[0-9]+%.?[0-9]*%%?$") then
        return "number"
    elseif string.match(str, "^[\"\'][^\"]*[\"\']$") then
        return "string"
    elseif self.vars[str] ~= nil then
        return "variable"
    else
        return "malformed"
    end
end

function terminal:eval(str)
    local lower_str = string.lower(str)
    
    if lower_str == "true" or lower_str == "on" then
        return true
    elseif lower_str == "false" or lower_str == "off" then
        return false
    elseif string.match(str, "^-?[0-9]+%.?[0-9]*$") then
        return tonumber(str)
    elseif string.match(str, "^[\"\'][^\"]*[\"\']$") then
        return str;
    elseif self.vars[lower_str] ~= nil then
        return self.vars[lower_str]
    end
end

-- Command Definitions ----------------------------------------
terminal.commands = {}
terminal.help = {
    ["help"]       = [[== CMD: Help =======
Syntax: help [command]
Returns information on the specified command.]],
    ["list"]       = [[== CMD: List =======
Syntax: list
Returns all system variables.]],
    ["set"]        = [[== CMD: Set ========
Syntax: set (key) (value)
Assign a system variable a new value.]],
    ["stop"]       = [[== CMD: Stop =======
Syntax: stop
Macro for 'set thrust 0.0'.]],
    ["cargo"]      = [[== CMD: Cargo ======
Syntax: cargo
Lists all items on the ship, including scrap.]],
    ["connect"]    = [[== CMD: Connect ====
Syntax: connect (station)
Connect to the specified station if in range.
Allows use of station systems and amenities.]],
    ["disconnect"] = [[== CMD: Disconnect =
Syntax: disconnect
Disconnect from current station.
Allows free movement in space.]],
    ["ping"]       = [[== CMD: Ping =======
Syntax: ping [station]
Ouputs the distance to a station.
Defaults to the nearest station.]],
    ["map"]        = [[== CMD: Map ========
Returns a map of scrap and stations within the system.
Can be used at stations, or with a fully repaired nav system.]],
    ["info"]       = [[== CMD: Info =======
Returns information about connected station.]],
    ["buy"]        = [[== CMD: Buy ========
Exchange scrap with the current station for cargo.]],
    ["install"]    = [[== CMD: Install ====
Installs the current system.
Installing the comm system will end the game.]],
}

function terminal.commands:help(caller, args)
    if #args == 0 then
        return [[== Commands ===========
help, list

SHIP: set, cargo, stop
STATION: info, buy, disconnect
NAV: ping

Type 'help [command]' for specific information.
]]
    elseif self.help[args[1].raw] then
        return self.help[args[1].raw] .. "\n"
    else
        return "Expected command name, received " .. args[1].raw .. ".\n", Color.TerminalError
    end
end

function terminal.commands:list(caller, args)
    local out = "== Variables ==========="
    for key, var in pairs(self.vars) do
        if var.constant then
            out = out .. "\n(READ-ONLY) " .. key .. " = " .. var.value
        else
            out = out .. "\n" .. key .. " = " .. var.value
        end
    end

    if next(caller.discovered) ~= nil then
        out = out .. "\n\n== Discovered =========="
    end

    for i, _ in pairs(caller.discovered) do
        if World.stations[i].name then
            out = out .. "\nSurvey Station " .. i .. " \"" .. World.stations[i].name .. "\""
        else
            out = out .. "\nSurvey Station " .. i
        end
    end
    out = out .. "\n"

    return out
end

function terminal.commands:set(caller, args)
    if #args < 2 then
        return Error.MissingArgs(#args, 2), Color.TerminalError
    elseif args[2].type == "variable" then
        args[2] = {
            raw = args[2].raw,
            type = args[2].value.type,
            value = args[2].value.value,
        }
    end

    if args[1].type ~= "variable" then
        return Error.TypeMismatch(args[1].type, "variable"), Color.TerminalError
    elseif args[2].type ~= args[1].value.type then
        return Error.TypeMismatch(args[2].type, args[1].value.type), Color.TerminalError
    elseif args[1].value.constant then
        return Error.ReassignConstant, Color.TerminalError
    elseif args[1].value.range and (args[2].value < args[1].value.range[1] or args[2].value > args[1].value.range[2]) then
        return Error.OutOfRange(args[2].value, args[1].value.range[1], args[1].value.range[2]), Color.TerminalError
    end

    args[1].value.value = args[2].value
end

--[[
function terminal.commands:toggle(caller, args)
    if #args < 1 then
        return Error.MissingArgs(#args, 1), Color.TerminalError
    elseif args[1].type ~= "variable" then
        return Error.TypeMismatch(args[1].type, "variable"), Color.TerminalError
    elseif args[1].value.type ~= "boolean" then
        return "Cannot toggle non-boolean variable.", Color.TerminalError
    elseif args[1].value.constant then
        return Error.ReassignConstant, Color.TerminalError
    end

    local on_off
    if args[1].value.value then
        on_off = "off"
    else
        on_off = "on"
    end

    self:submit(nil, "set " .. args[1].raw .. " " .. on_off)
end
--]]

function terminal.commands:stop(caller, args)
    self:submit(nil, "set thrust 0.0")
end

function terminal.commands:cargo(caller, args)
    local out = "== Cargo ===============\n"

    for item, _ in pairs(caller.items) do
        out = out .. World.Items[item] .. "\n"
    end
    out = out .. "\n"

    local scrap = math.floor(caller.scrap * 100) / 100
    out = out .. scrap .. " lb. of scrap.\n"

    return out
end

-- station functions
function terminal.commands:connect(caller, args)
    ping:seek(0)
    ping:play()

    if #args < 1 then
        return Error.MissingArgs(#args, 1)
    elseif args[1].type == "variable" then
        args[1] = {
            raw = args[1].raw,
            type = args[1].value.type,
            value = args[1].value.value,
        }
    end

    if args[1].type ~= "number" then
        return Error.TypeMismatch(args[1].type, "number")
    elseif caller.connected == args[1].value then
        return Error.Connected(args[1].value), Color.TerminalError
    elseif World.stations[args[1].value] == nil then
        return "Station " ..args[1].value .. " does not exist.", Color.TerminalError
    end

    local station = World.stations[args[1].value]
    local dist = math.sqrt((station.x - caller.x)^2 + (station.y - caller.y)^2)

    if dist > 150 then
        return "Station " .. args[1].value .. " out of range! Must be within 150m to dock.", Color.TerminalError
    end

    caller.connected = args[1].value

    caller.x = World.stations[args[1].value].x
    caller.y = World.stations[args[1].value].y

    caller.disabled = true

    if not caller.discovered[args[1].value] then
caller.discovered[args[1].value] = true
        caller.total_discoveries = caller.total_discoveries + 1

        if caller.total_discoveries == 1 then
            return "Connected!\nNew functions available.\nThere is nothing to repair the ship with here, but their radar is much more powerful than yours.\nTry using 'ping' to find your next destination before leaving.\n"
        elseif caller.total_discoveries == 2 or caller.total_discoveries == 4 or caller.total_discoveries == 6 or caller.total_discoveries == 7 then
            World.stations[args[1].value].item = table.remove(self.systems_remaining, lm.random(#self.systems_remaining))
    
            return "Connected!\nNew functions available.\nNew item available for purchase!\nUse 'info' to find out more, and 'buy' to make a purchase.\n"
        end
    end

    return "Connected!\nNew functions available.\n"
end

function terminal.commands:info(caller, args)
    if caller.connected == nil then
        return Error.NotConnected("info"), Color.TerminalError
    end

    local station = World.stations[caller.connected]
    local info = station.info

    if station.item then
        local cost = 0
        if caller.total_items == 1 then
            cost = 200
        elseif caller.total_items == 2 then
            cost = 500
        elseif caller.total_items == 3 then
            cost = 2000
        end

        info = info .. "Selling: " .. World.Items[station.item] ..  " for " .. cost .. " scrap.\n"
    end

    return info
end

function terminal.commands:buy(caller, args)
    if caller.connected == nil then
        return Error.NotConnected("buy"), Color.TerminalError
    end

    local station = World.stations[caller.connected]
    
    if station.item == nil then
        return "There is nothing for sale.\n"
    end

    local cost = 0
    if caller.total_items == 1 then
        cost = 200
    elseif caller.total_items == 2 then
        cost = 500
    elseif caller.total_items == 3 then
        cost = 2000
    end

    if caller.scrap < cost then
        return "Not enough scrap. Try collecting debris on the way to your next station.\n", Color.TerminalError
    else
        caller.items[station.item] = true
        caller.just_got = station.item
        caller.total_items = caller.total_items + 1
        caller.scrap = caller.scrap - cost
        station.item = nil
        return "Success!", Color.TerminalDefault
    end
end

function terminal.commands:disconnect(caller, args)
    if caller.connected == nil then
        return Error.NotConnected("disconnect"), Color.TerminalError
    end

    local station = World.stations[caller.connected]

    caller.x = station.x + (station.type.size + 32) / 2 * math.cos(caller.heading - math.pi/2)
    caller.y = station.y + (station.type.size + 32) / 2 * math.sin(caller.heading - math.pi/2)

    caller.disabled = false
    caller.connected = nil

    return "Disconnected."
end

-- nav functions
function terminal.commands:ping(caller, args)
    ping:seek(0)
    ping:play()

    local nearest, i, dist
    if args[1] == nil then
        nearest, i, dist = World.nearestStation(caller.x, caller.y)
    elseif args[1].type == "number" and World.stations[args[1].value] then
        i = args[1].value
        nearest = World.stations[args[1].value]
        dist = math.sqrt((nearest.x - caller.x)^2 + (nearest.y - caller.y)^2)
    elseif args[1].type == "number" then
        return "Station " .. args[1].value .. " does not exist.\n"
    else
        return Error.TypeMismatch(args[1].type, "number"), Color.TerminalError
    end 

    local dir = math.ceil(
        math.atan2(nearest.x - caller.x,  caller.y - nearest.y) * (180 / math.pi) * 100
    ) / 100
    dist = math.ceil(dist * 100) / 100
    
    local rel_dir
    if dir <= -158 or dir > 158 then
        rel_dir = "south"
    elseif dir < -112 then
        rel_dir = "southwest"
    elseif dir >= 112 then
        rel_dir = "southeast"
    elseif dir <= -67.5 then
        rel_dir = "west"
    elseif dir > 67.5 then
        rel_dir = "east"
    elseif dir < -22.5 then
        rel_dir = "northwest"
    elseif dir >= 22.5 then
        rel_dir = "northeast"
    else
        rel_dir = "north"
    end

    if caller.connected or caller.items["nav"] or caller.discovered[i] then
        return "Station " .. i .. " is " .. dist .. "u away, at a heading of " .. dir .. " degrees.\n"
    elseif self.first_ping then
        return "Station " .. i .. " is " .. dist .. "u " .. rel_dir .. ".\n"
    else
        self.first_ping = true

        self.text[#self.text + 1] = Color.TerminalInfo
        self.text[#self.text + 1] = "Repairing the navigation systems will allow more precise directions."

        return "Station " .. i .. " is " .. dist .. "u " .. rel_dir .. ".\n"
    end
end

-- Input -----------------------------------------------
function terminal:submit(caller, text)
    if caller ~= nil then
        bloop:seek(0)
        bloop:play()
    end

    self.text[#self.text + 1] = Color.TerminalInput
    self.text[#self.text + 1] = text
    
    local res, res_color = self:parse(caller, text)
    self.text[#self.text + 1] = res_color
    self.text[#self.text + 1] = res
end

function terminal:parse(caller, text)
    local cmd, parts = string.match(text, "^(%w+)%s?(.*)$")

    if cmd == nil then
        return
    end
    
    cmd = string.lower(cmd)
    if self.commands[cmd] == nil then
        return "ERR: Command '" .. cmd .. "' not recognized.\n", Color.TerminalError
    end

    local args = {}
    local next_arg = nil
    for part in parts:gmatch("%S+") do
        if part:sub(1,2) == "--" then
            next_arg = part:sub(3)
        elseif next_arg ~= nil then
            args[next_arg] = part
            next_arg = nil
        else
            args[#args + 1] = part
        end
    end

    for k, arg in pairs(args) do
        args[k] = {
            raw = arg,
            type = self:type_eval(arg),
            value = self:eval(arg),
        }
    end

    return self.commands[cmd](self, caller, args)
end

function terminal:textinput(t)
    if valid_text[t] == nil then
        return
    end

    if self.open and #self.text >= 26 then
        terminal:focus()
        terminal.input = terminal.input:sub(1, terminal.cursor_pos) .. t .. terminal.input:sub(terminal.cursor_pos + 1, #terminal.input)
        terminal.cursor_pos = terminal.cursor_pos + 1
    end
end

function terminal:notify(...)
    for _, message in ipairs({ ... }) do
        self.queue[#self.queue + 1] = message
    end
end

function terminal:skip()
    if self.queue[1] == nil then
        return
    end

    if self.queue.current_message == nil then
        self.text[#self.text + 1] = self.queue[1]
    else
        self.text[self.queue.current_message] = self.text[self.queue.current_message] .. self.queue[1]
    end

    table.remove(self.queue, 1)
    self.queue.current_message = nil
end

function terminal:focus()
    if self.scroll < self.input_y - self.Height + Font.Terminal:getHeight() + self.Padding + 3 then
        self.scroll = self.input_y - self.Height + Font.Terminal:getHeight() + self.Padding * 2
    end
end

-- Love callbacks ---------------------------------------------
function terminal:wheelmoved(sx, sy)
    self.scroll = trans.clamp(
        self.scroll - sy * Font.Terminal:getHeight(),
        0, self.input_y - self.Padding)
end

-- Draw loop -------------------------------------------------
function terminal:update(dt)
    if self.open then
        self.open_timer = math.min(self.open_timer + dt, self.Duration)
    else
        self.open_timer = math.max(self.open_timer - dt, 0.0)
    end

    while #self.queue > 0 and type(self.queue[1]) ~= "string" do
        self.text[#self.text + 1] = table.remove(self.queue, 1)
    end

    if self.queue[1] ~= nil then        
        if self.queue.current_message == nil then
            self.text[#self.text + 1] = ""
            self.queue.current_message = #self.text
        end

        if self.type_timer > 0.0 then
            self.type_timer = self.type_timer - dt
        else
            self.text[self.queue.current_message] = self.text[self.queue.current_message] .. string.sub(self.queue[1], 1, 1)
            self.queue[1] = string.sub(self.queue[1], 2, #self.queue[1])

            local char = string.sub(self.queue[1], 1, 1)
            if #char == 0 then
                table.remove(self.queue, 1)
                self.queue.current_message = nil

                self.type_timer = 0.3
            elseif char == "`" then
                self.type_timer = 0.3
            else
                self.type_timer = 0.01
            end
        end
    end
end

function terminal:draw(window_width, window_height)
    lg.push()
    lg.translate(
        math.floor(trans.tween(self.open_timer / self.Duration, self.Width + 10, 0, trans.func.ease)),
        0
    )

    lg.setColor(Color.TerminalBG)
    lg.rectangle("fill", window_width - self.Width - 5, 5, self.Width, window_height - 10)

    lg.setColor(Color.TerminalOutline)
    lg.setLineWidth(2)
    lg.rectangle("line", window_width - self.Width - 5, 5, self.Width, window_height - 10)

    lg.setScissor(window_width - self.Width - 4 + trans.tween(self.open_timer / self.Duration, self.Width + 10, 0, trans.func.ease), 6, self.Width - 2, window_height - 12)
    lg.translate(window_width - self.Width + self.Padding - 4, 6 + self.Padding - self.scroll)

    lg.setFont(Font.Terminal)
    local y = 0
    for _, line in ipairs(self.text) do
        if type(line) == "table" then
            lg.setColor(line)
        else
            lg.printf(line, 0,y, self.Width - self.Padding*3)

            local lines = select(2, Font.Terminal:getWrap(line, self.Width - self.Padding*3))
            y = y + #lines * Font.Terminal:getHeight()
        end
    end

    lg.setColor(Color.TerminalInput)
    if 4 * (Timer % 1) < 3 and #self.text >= 26 then
        lg.printf(self.input:sub(1, self.cursor_pos) .. "_" .. self.input:sub(self.cursor_pos + 1, #self.input), 0,y, self.Width - self.Padding*3)
    else
        lg.printf(self.input:sub(1, self.cursor_pos) .. " " .. self.input:sub(self.cursor_pos + 1, #self.input), 0,y, self.Width - self.Padding*3)
    end
    local old_input_y = self.input_y
    self.input_y = y + Font.Terminal:getHeight()

    if old_input_y ~= self.input_y then
        self:focus()
    end
    lg.setScissor()
    lg.pop()
end

return terminal