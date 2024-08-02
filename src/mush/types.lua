--[[
    mush.types
    A collection of lightweight "structs" to organize data in other modules.
]]

--- @class (exact) mush.Types
--- @field Point fun(initializer: [integer, integer]): mush.Point
--- @field Size fun(initializer: [integer, integer]): mush.Size
--- @field Rect fun(initializer: [integer, integer, integer, integer]): mush.Rect
local types = {}

--[[ Definitions ]]--------------------------------------------
--- @class (exact) mush.Point
--- @field x number
--- @field y number

--- @class (exact) mush.Size
--- @field width number
--- @field height number

--- @class (exact) mush.Rect
--- @field x number
--- @field y number
--- @field width integer
--- @field height integer

--[[ Constructors ]]-------------------------------------------
--- Utility function to turn varargs into one value.
--- @param ... any
--- @return table
local function pack(...)
    local args = { ... }
    if #args == 1 then
        return args[1]
    end

    return args
end

--- Utility function to populate a table from an initializer list.
--- @param values [any]
--- @param ... string
--- @return table<string, any>
local function init(values, ...)
    local keys = { ... }
    assert(#keys == #values, "Expected same number keys and values, received " .. #keys .. " keys, but " .. #values .. " values.")

    local new = {}
    for i, key in ipairs(keys) do
        new[key] = values[i]
    end

    return new
end

--- Create Point from initializer.
--- @param ... [number, number]
--- @return mush.Point
function types.Point(...)
    return init(pack(...), "x", "y")
end

--- Create Size from initializer list.
--- @param ... [integer, integer]
--- @return mush.Size
function types.Size(...)
    return init(pack(...), "width", "height")
end

--- Create Rect from initializer list.
--- @param ... [number, number, integer, integer]
--- @return mush.Rect
function types.Rect(...)
    return init(pack(...), "x", "y", "width", "height")
end

--[[ Export ]]-------------------------------------------------
return types