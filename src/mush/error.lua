local format = require("src.util.format")

local err = {}

-- Throws an error if the argument passed is nil.
--- @param param any
--- @param paramName string @ (optional) Name to use in error messages.
--- @param ... string | table @ (optional) Types to check the param against.
err.expect = function(param, paramName, ...)
    if paramName == nil then
        paramName = ""
    else
        paramName = " '" .. paramName .. "'"
    end
    
    if param == nil then
        error("Expected required argument" .. paramName .. ", received nil.", 3)
    end
    
    if #paramName ~= 0 then
        paramName = " at" .. paramName
    end

    local types = { ... }
    for _, t in ipairs(types) do
        if type(param) == t
        or (type(param) == "table" and param.type == t)
        or (type(param) == "userdata" and param:typeOf(t)) then
            return
        end
    end

    error("Type mismatch" .. paramName .. ". Expected type " .. table.concat(types, "|") .. ", received " .. type(param) .. ".", 3)
end

-- Throws an error if the argument passed is outside the given range.
--- @param param number
--- @param a number @ lower bound
--- @param b number @ upper bound
--- @param typeName string? @ Name to use in error message.
function err.bound(param, a, b, typeName)
    if typeName == nil then
        typeName = ""
    else
        typeName = format.capitalize(typeName) .. " "
    end

    if (param < a) or (param > b) then
        error(typeName .. param .. " out of bounds. Expected a number between " .. a .. " and " .. b .. ".", 3)
    end
end

return err