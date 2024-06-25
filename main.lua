local g = love.graphics
local m = love.math
local w = love.window

g.setDefaultFilter("nearest", "nearest")

--[[ DEFINE GLOBALS ]]------------------------------------------
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

Font = {
    Terminal = g.newImageFont("assets/images/system/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?_:;+-=\'\"()[]", 1)
}

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

--[[ DO THINGS ]]----------------------------------------------
local trans = require("src.util.trans")

local p = require("src.core.player")
local terminal = require("src.core.terminal")
local cam = require("src.mush.cam"):setup(320, 180)

local music = love.audio.newSource("assets/music/bitspace.mp3", "stream")
music:setLooping(true)
music:play()

local game_started = false
local menu_title = g.newImage("assets/images/system/title.png")
local menu_image = g.newImage("assets/images/system/title_boat.png")
local menu_transition = 0
local press_any_button = false

--- @type table[]
-- star field code based loosely on this forum post: https://love2d.org/forums/viewtopic.php?t=73637
local stars = {}
local function generate_stars(n)
    stars[1] = { ox = 0, oy = 0 }
    stars[2] = { ox = 0, oy = 0 }

    for i = 1, n do
        local size = m.random(#stars)

        -- separate the sizes into tables for easy paralaxing
        stars[size][#stars[size] + 1] = {
            brightness = m.random(10) / 10,
            x = m.random(cam.canvas_width),
            y = m.random(cam.canvas_height),
        }
    end
end

local function generate_stations(n)
    World.stations = {
        r = 0,
        Names = {
            [1] = "Leto",
            [2] = "???",
            [3] = "Hels",

            [5] = "Stheno",
            [7] = "Euryale",
            [8] = "???",

            [9] = "Nidhogg",

            [11] = "???",
            [12] = "???"
        },
        Info = {
            default = "A survey station. This one was never named.\n",
            ["???"] = "A damaged survey station. The paint is worn, and its name no longer legible.\n",

            ["Leto"] = "A survey station. The first of many. Named for an ancient god.\n",
            ["Hels"] = "The largest of the stations that ever made it this far. Designed to house a large number of personel, it remains empty.\n",
            ["Stheno"] = "Launched during the peak of humanity's space age, along with sister station 7. Named for the Gorgon.\n",
            ["Euryale"] = "Launched during the peak of humanity's space age, along with sister station 5. Named for the Gorgon.\n",
            ["Nidhogg"] = "The last station launched from Earth. Named for an ending.\n",
        },
        Types = {
            { -- centrifuge
                size = 64,
                image = g.newImage("assets/images/objects/station_ring.png")
            },
            { -- diamond
                size = 64,
                image = g.newImage("assets/images/objects/station_square.png")
            }
            -- satelite?
        },
    }

    for i = 1, n do
        local station = {}
        local safe = false

        while safe ~= true do
            station = {
                name = World.stations.Names[i],
                type = World.stations.Types[m.random(#World.stations.Types)],
                x = m.random(World.width) - World.width / 2,
                y = m.random(World.height) - World.height / 2,
                r = m.random(360) * math.pi / 180
            }

            station.info = World.stations.Info[station.name] or World.stations.Info.default
            safe = math.sqrt((p.x - station.x)^2 + (p.y - station.y)^2) >= 600

            for _, previous_station in ipairs(World.stations) do
                local dist = math.sqrt((station.x - previous_station.x)^2 + (station.y - previous_station.y)^2)
                safe = safe and dist > (station.type.size + previous_station.type.size)

                if not safe then
                    break
                end
            end
        end

        World.stations[#World.stations + 1] = station
    end
end

local debris = {}
local collected = {}
local function generate_debris(sectors, cluster_size)
    debris = {
        Types = {
            {
                image = g.newImage("assets/images/objects/debris_small.png"),
                quads = {
                    g.newQuad( 0,0, 16,16, 48,16),
                    g.newQuad(16,0, 16,16, 48,16),
                    g.newQuad(32,0, 16,16, 48,16),
                },
                size = 16,
            },
            {
                image = g.newImage("assets/images/objects/debris_large.png"),
                quads = {
                    g.newQuad( 0,0, 32,32, 128,32),
                    g.newQuad(32,0, 32,32, 128,32),
                    g.newQuad(64,0, 32,32, 128,32),
                    g.newQuad(96,0, 32,32, 128,32),
                },
                size = 32,
            }
        }
    }

    debris.sector_width = World.width / sectors
    debris.sector_height = World.height / sectors

    for sx = 1, sectors do
        debris[sx] = {}
        for sy = 1, sectors do
            debris[sx][sy] = {}

            for _ = 1, m.random(2,5) do
                local cx = (sx - 1) * debris.sector_width + 64 + m.random(debris.sector_width - 128) - (World.width + cam.canvas_width) / 2
                local cy = (sy - 1) * debris.sector_height + 64 + m.random(debris.sector_height - 128) - (World.height + cam.canvas_height) / 2

                for _ = 1, cluster_size do
                    local ox = m.random(8) * 8
                    local oy = m.random(8) * 8

                    local weight = m.random(5) * 10

                    local node = {
                        x = cx + ox,
                        y = cy + oy,
                        r = m.random(360) * math.pi / 180,
                        weight = weight * trans.tween(1 - 2 * math.abs(cx + ox) / World.width, 1, 2.5, trans.func.ease_out),
                    }

                    if node.weight >= 80 then
                        node.type = debris.Types[2]
                    else
                        node.type = debris.Types[1]
                    end
        
                    local r = m.random(100)
        
                    if r == 100 then
                        node.quad = node.type.quads[#node.type.quads]
                    else
                        node.quad = node.type.quads[m.random(#node.type.quads - 1)]
                    end
            
                    table.insert(debris[sx][sy], node)
                end
            end
        end
    end
end

function love.load()
    p:reset()
    terminal:reset()

    cam.x = 0
    cam.y = 0

    -- game intro
    terminal:notify(
        Color.TerminalInfo,
        [[SeraphOS
Version 12.3.1 "Swallowtail"
Copyright (C) Optera Inc.]],
        "",

        Color.TerminalDefault,
        "3768517.2 days since previous boot.`",
        "Running system checks.",
        "",
        
        Color.TerminalError,
        "Power:` OFFLINE!",
        "Cooling:` OFFLINE!",
        Color.TerminalInfo,
        "Propulsion:` Fully operational.",
        "Navigation:` Needs repairs.",
        Color.TerminalError,
        "Communications:` OFFLINE!",
        "",

        Color.TerminalInfo,
        "Diagnosing```.```.```.``` Ship status critical!",
        Color.TerminalError,
        "Severe structural damage detected!",
        "",

        Color.TerminalDefault,
        "Notifying pilot```.```.```.``` Onboard pilot unresponsive.",
        "Autonomous control authorized.",
        "",
        "",

        Color.TerminalInfo,
        "MISSION: Find a nearby station.",
        Color.TerminalDefault,
        "Type 'help' to see a list of commands.",
        "Change 'heading' and 'thrust' to move.",
        ""
    )

    generate_stars(80)
    generate_stations(12)
    generate_debris(20, 5)
end

function love.resize(w, h)
    cam:fit(w, h)
    generate_stars(80)
end

function love.textinput(t)
    if game_started then
        terminal:textinput(t)
    end
end

function love.keypressed(k)
    if game_started then
        if k == "f11" then
            local f = w.getFullscreen()
            w.setFullscreen(not f)
            love.resize(g.getDimensions())
        elseif k == "/" then
            terminal.open = not terminal.open
        elseif k == "tab" then
            terminal:skip()
        elseif not terminal.open or #terminal.text < 26 then
            return
        end
        
        if k == "return" or k == "kpenter" then
            terminal:submit(p, terminal.input)

            if terminal.recall_line then
                table.remove(terminal.history, terminal.recall_line)
            end
            
            terminal.history[#terminal.history + 1] = terminal.input
            terminal.input = ""
            terminal.cursor_pos = 0
            terminal.recall_line = nil
        elseif k == "backspace" then
            terminal.input = terminal.input:sub(1, terminal.cursor_pos - 1) .. terminal.input:sub(terminal.cursor_pos + 1, #terminal.input)
            terminal.cursor_pos = math.max(terminal.cursor_pos - 1, 0)
        elseif k == "left" then
            terminal.cursor_pos = math.max(terminal.cursor_pos - 1, 0)
        elseif k == "right" then
            terminal.cursor_pos = math.min(terminal.cursor_pos + 1, #terminal.input)
        elseif k == "up" then
            if terminal.recall_line then
                terminal.recall_line = math.max(terminal.recall_line - 1, 1)
            else
                terminal.recall_line = #terminal.history
            end

            if terminal.recall_line and #terminal.history ~= 0 then
                terminal.input = terminal.history[terminal.recall_line]
                terminal.cursor_pos = #terminal.input
            end
        elseif k == "down" then
            if terminal.recall_line == #terminal.history then
                terminal.recall_line = nil
                terminal.input = ""
            elseif terminal.recall_line then
                terminal.recall_line = terminal.recall_line + 1
            end

            if terminal.recall_line and #terminal.history ~= 0 then
                terminal.input = terminal.history[terminal.recall_line]
                terminal.cursor_pos = #terminal.input
            end
        end
    else
        press_any_button = true
    end
end

function love.wheelmoved(sx, sy)
    if game_started then
        terminal:wheelmoved(sx, sy)
    end
end

local old_canvas_x, old_canvas_y = 0, 0
local old_my = 0
function love.update(dt)
    if game_started then
        local mx, my = love.mouse.getPosition()

        if terminal.open and love.mouse.isDown(1)
        and mx / cam.canvas_scale > math.floor(trans.tween(terminal.open_timer / terminal.Duration, terminal.Width + 10, 0, trans.func.ease)) + cam.canvas_width - terminal.Width - 4
        and mx / cam.canvas_scale < cam.canvas_width - 5 then
            terminal.scroll = trans.clamp(
                terminal.scroll - (my - old_my),
                0, terminal.input_y - terminal.Padding)
        end

        old_my = my

        if (p.just_got == "comm" or p.just_got == "power" or p.just_got == "cooling")
        and p.items["comm"] and (p.items["power"] or p.items["cooling"]) then
            terminal.text[#terminal.text + 1] = Color.TerminalDefault
            terminal.text[#terminal.text + 1] = "Communications online.\n\n"

            -- credits
            terminal:notify(
                "Transmitting distress signal```.```.```.``` Received.\n",
                
                "== Credits =============",
                "-- Audio ---------------",
                "HAM Radio Bloop by deadrobotmusic",
                "Dirty_Sonar.wav by Bitbeast",
                "Bit Space (loopable) by Beam Theory\n",

                "-- Art & Code ----------",
                "massette (me :3)",
                "========================\n",

                "This is the end of the game, but you're free to keep exploring. There are 12 stations total, if you haven't found them all (though only 5 of them are named).",
                "Thanks for playing!\n"
            )

            p.just_got = nil
        elseif p.just_got == "comm" then
            terminal.text[#terminal.text + 1] = Color.TerminalDefault
            terminal.text[#terminal.text + 1] = "Communications systems have been fully repaired.\nShip is too damaged to transmit messages.\n\nMISSION: Repair cooling or power systems.\n"

            p.just_got = nil
        elseif p.just_got == "power" then
            terminal.text[#terminal.text + 1] = Color.TerminalDefault
            terminal.text[#terminal.text + 1] = "Power systems have been fully repaired.\nShip will now be able to handle a new communications system without overheating.\n\nMISSION: Repair communications system.\n"

            p.just_got = nil
        elseif p.just_got == "cooling" then
            terminal.text[#terminal.text + 1] = Color.TerminalDefault
            terminal.text[#terminal.text + 1] = "Cooling systems have been fully repaired.\nShip will now be able to handle the strain of a new communications system.\n\nMISSION: Repair the communications system.\n"

            p.just_got = nil
        elseif p.just_got == "nav" then
            terminal.text[#terminal.text + 1] = Color.TerminalDefault
            terminal.text[#terminal.text + 1] = "Navigation systems have been fully repaired.\nPing will now always provide an exact direction.\nMISSION: Find the other subsystems.\n"

            p.just_got = nil
        end

        terminal:update(dt)
        World.stations.r = World.stations.r + dt / 3
        
        local nearest, nearest_i, dist = World.nearestStation(p.x, p.y)
        if dist < 150 and not terminal.first_connect then
            terminal.text[#terminal.text + 1] = "Station " .. nearest_i .. " is nearby!\nUse 'connect " .. nearest_i .. "' to dock there.\n"
            terminal.first_connect = true
        end

        local sx = trans.clamp(
            math.floor((p.x + World.width / 2) / debris.sector_width) + 1,
            2, #debris - 1)

        local sy = trans.clamp(
            math.floor((p.y + World.height / 2) / debris.sector_height) + 1,
            2, #debris[1] - 1)

        for i, node in ipairs(collected) do
            if node.timer >= 1.0 then
                table.remove(collected, i)

                p.scrap = p.scrap + node.weight
            else
                node.timer = node.timer + dt
            end
        end
    
        for i=-1,1 do
            for j = -1,1 do
                for k, node in ipairs(debris[sx + i][sy + j]) do
                    local dist = math.sqrt((p.y - node.y)^2 + (p.x - node.x)^2)

                    if dist <= node.type.size + 16 then
                        collected[#collected+1] = table.remove(debris[sx + i][sy + j], k)
                        collected[#collected].timer = 0
                    end
                end
            end
        end

        p.heading_to = (terminal.vars["heading"].value * math.pi / 180 + math.pi) % (2 * math.pi) - math.pi

        if terminal.vars["thrust"].value > 0.0 then
            p.acc = p.Thrust * terminal.vars["thrust"].value
            
            if p.image.animation == "idle" then
                p.image:setAnimation("fly")
            end
        end

        if p.image.animation == "fly" and terminal.vars["thrust"].value == 0.0 then
            p.acc = 0

            p.image:setAnimation("brake")
        end

        p:update(dt)

        p.x = trans.clamp(p.x, -(World.width + cam.canvas_width) / 2, (World.width + cam.canvas_width) / 2)
        p.y = trans.clamp(p.y, -(World.height + cam.canvas_height) / 2, (World.height + cam.canvas_height) / 2)

        local dx = old_canvas_x - (cam.x + cam.ox) - 0.05 * math.sin(p.heading)
        local dy = old_canvas_y - (cam.y + cam.oy) + 0.05 * math.cos(p.heading)

        old_canvas_x = cam.x + cam.ox
        old_canvas_y = cam.y + cam.oy

        for size, layer in ipairs(stars) do
            layer.ox = (layer.ox + dx / (3 - size / #stars)) % cam.canvas_width
            layer.oy = (layer.oy + dy / (3 - size / #stars)) % cam.canvas_height
        end

        local follow_dist = trans.tween(terminal.open_timer / terminal.Duration, 50, 20, trans.func.ease)
        cam:follow(p.x, p.y, follow_dist, 1)

        cam.ox = trans.tween(terminal.open_timer / terminal.Duration, 0, (terminal.Width + 10) / 2, trans.func.ease)
        
        menu_transition = math.max(menu_transition - dt, 0.0)
    elseif menu_transition == 1.0 then
        game_started = true
    else
        for size, layer in ipairs(stars) do
            layer.ox = (layer.ox - 2 / (3 - size / #stars)) % cam.canvas_width
            layer.oy = (layer.oy + 1 / (3 - size / #stars)) % cam.canvas_height
        end

        if press_any_button then
            menu_transition = math.min(menu_transition + dt, 1.0)
        end
    end

    Timer = Timer + dt
end

---@diagnostic disable-next-line: duplicate-set-field
function cam:prepareStatic()
    for size, layer in ipairs(stars) do
        for _, star in ipairs(layer) do
            g.setColor(1,1,0.5*star.brightness + 0.5, star.brightness)
            g.circle("fill", math.floor(star.x + layer.ox) % (cam.canvas_width), math.floor(star.y + layer.oy) % (cam.canvas_height), size)
        end
    end

    if not game_started then
        g.setColor(1,1,1, 1)
        g.draw(menu_image, (cam.canvas_height - 200) / 2, 8 * math.sin(Timer) + 8)
        g.draw(menu_title, (cam.canvas_width - 300) / 2)

        g.setFont(Font.Terminal)
         g.print("[Press any key to continue]", cam.canvas_width - Font.Terminal:getWidth("[Press any key to continue]") - 5, cam.canvas_height - Font.Terminal:getHeight() - 5)
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function cam:prepare()
    if game_started then
        local sx = trans.clamp(
            math.floor((p.x + World.width / 2) / debris.sector_width) + 1,
            2, #debris - 1)

        local sy = trans.clamp(
            math.floor((p.y + World.height / 2) / debris.sector_height) + 1,
            2, #debris[1] - 1)

        for i=-1,1 do
            for j = -1,1 do
                for k, node in ipairs(debris[sx + i][sy + j]) do
                    g.setColor(Color.Debris)
                    g.draw(node.type.image, node.quad, node.x, node.y, node.r, 1, 1, node.type.size/2, node.type.size/2)
                end
            end
        end

        for i, station in ipairs(World.stations) do
            local label = "Station " .. i
            if p.discovered[i] then
                g.setColor(Color.StationFound)

                if station.name then
                    label = label .. " '" .. station.name .. "'"
                end
            else
                label = "( " .. label .. " )"
                g.setColor(Color.StationDefault)
            end

            g.print(label, station.x - Font.Terminal:getWidth(label)/2, station.y - station.type.size/2 - Font.Terminal:getHeight() - 5)
            love.graphics.draw(station.type.image, station.x, station.y, station.r + World.stations.r, 1, 1, station.type.size/2, station.type.size/2)
        end

        for i, node in ipairs(collected) do
            local r = math.atan2(node.y - p.y, node.x - p.x)
            local dist = math.sqrt((p.x - node.x)^2 + (p.y - node.y)^2) * trans.tween(node.timer, 1.0, 0.0, trans.func.ease)
            local s = trans.tween(node.timer / 1.0, 1.0, 0.25, trans.func.ease_out)

            g.setColor(Color.Debris)
            g.draw(node.type.image, node.quad, p.x + dist * math.cos(r), p.y + dist * math.sin(r), node.r, s, s, node.type.size/2, node.type.size/2)
        end

        p:draw()
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function cam:prepareUI()
    if game_started then
        terminal:draw(cam.canvas_width, cam.canvas_height)
    else
    end
end

function love.draw()
    cam:draw()

    g.setColor(Color.BG[1], Color.BG[2], Color.BG[3], menu_transition)
    g.rectangle("fill", 0, 0, cam.window.width, cam.window.height)
end