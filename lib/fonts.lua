-- lib/fonts.lua
-- Centralized Font Manager to cache Font objects by size.
-- Eliminates per-frame font allocations in draw() calls across screens.

local Fonts = {}
local cache = {}

function Fonts.get(size)
    size = math.max(6, math.floor(size or 12))
    if not cache[size] then
        cache[size] = love.graphics.newFont(size)
    end
    return cache[size]
end

function Fonts.clear()
    cache = {}
end

return Fonts
