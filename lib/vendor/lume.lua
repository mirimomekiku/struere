-- lume.lua - Utility library for Lua
local lume = {}

function lume.clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function lume.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function lume.randomchoice(t)
    if #t == 0 then return nil end
    return t[math.random(#t)]
end

function lume.push(t, ...)
    for _, v in ipairs({...}) do
        table.insert(t, v)
    end
    return t
end

function lume.remap(x, min1, max1, min2, max2)
    return min2 + (x - min1) * (max2 - min2) / (max1 - min1)
end

return lume
