--- A module for creating and managing transitions.
local trans = {}

-- UTILITY FUNCTIONS

-- Constrain a value between to a range [a,b]
--- @return number
--- @param value number
--- @param a number
--- @param b number?
function trans.clamp(value, a,b)
    if b == nil then
        return math.min(math.max(value, -a), a)
    end

    return math.min(math.max(value, a), b)
end

-- Interpolate between two values with an arbitrary transition function.
--- @return number
--- @param t number
--- @param a number
--- @param b number
--- @param f? fun(t: number): number
function trans.tween(t, a,b, f)
    f = f or trans.func.linear

    return a + f(t) * (b - a)
end

-- TRANSITION FUNCTIONS
trans.func = {}

-- Generic transition function
--- @return number
--- @param t number
function trans.func.linear(t)
    t = trans.clamp(t, 0.0, 1.0)

    return t
end

-- A transition function that moves slower at the beginning and end
--- @return number
--- @param t number
function trans.func.ease(t)
    t = trans.clamp(t, 0.0, 1.0)

    if t < 0.5 then
        return 4 * t ^ 3
    else
        return 1 - (2 - 2 * t)^3 / 2
    end
end

-- A transition function that moves slower at the beginning 
--- @return number
--- @param t number
function trans.func.ease_in(t)
    t = trans.clamp(t, 0.0, 1.0)

    return t ^ 3
end

-- A transition function that moves slower at the end
--- @return number
--- @param t number
function trans.func.ease_out(t)
    t = trans.clamp(t, 0.0, 1.0)

    return 1 - (1 - t)^3
end

return trans