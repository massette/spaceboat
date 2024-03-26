local function capitalize(text)
    if text == nil then
        return nil
    end

    return (text:gsub("^%l", string.upper))
end

--[[
local function camel(text)
    if text == nil then
        return nil
    end

    return (text:gsub("%W+%l", string.upper):gsub("%W+", ""):gsub("^%u", string.lower))
end

local function pascal(text)
    if text == nil then
        return nil
    end

    return (text:gsub("%W+%l", string.upper):gsub("%W+", ""):gsub("^%l", string.upper))
end

local function snake(text)
    if text == nil then
        return nil
    end

    return (text:gsub("%W", "_"))
end

local function screamingSnake(text)
    if text == nil then
        return nil
    end

    return string.upper(text:gsub("%W", "_"))
end
--]]

--[[ EXPORT]] -------------------------------------------------
return {
    capitalize = capitalize
}