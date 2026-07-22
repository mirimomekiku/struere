-- flux.lua - Fast, flexible tweening library for Lua
local flux = {
    _tweens = {},
    easing = {}
}

local Tween = {}
Tween.__index = Tween

-- Easing functions
local function linear(p) return p end
local function quadin(p) return p * p end
local function quadout(p) return -(p * (p - 2)) end
local function quadinout(p)
    if p < 0.5 then return 2 * p * p else return -1 + (4 - 2 * p) * p end
end
local function cubicout(p)
    local f = p - 1
    return f * f * f + 1
end

flux.easing = {
    linear = linear,
    quadin = quadin,
    quadout = quadout,
    quadinout = quadinout,
    cubicout = cubicout
}

function Tween.new(obj, time, vars)
    local self = setmetatable({}, Tween)
    self.obj = obj
    self.rate = time > 0 and 1 / time or 0
    self.progress = time > 0 and 0 or 1
    self.keys = {}
    self.ease_fn = quadout
    self.on_complete = nil

    for k, v in pairs(vars) do
        local start = obj[k]
        if type(start) == "number" and type(v) == "number" then
            self.keys[k] = { start = start, diff = v - start }
        end
    end
    return self
end

function Tween:ease(kind)
    if type(kind) == "string" and flux.easing[kind] then
        self.ease_fn = flux.easing[kind]
    elseif type(kind) == "function" then
        self.ease_fn = kind
    end
    return self
end

function Tween:oncomplete(fn)
    self.on_complete = fn
    return self
end

function Tween:stop()
    for i, t in ipairs(flux._tweens) do
        if t == self then
            table.remove(flux._tweens, i)
            break
        end
    end
end

function flux.to(obj, time, vars)
    local t = Tween.new(obj, time, vars)
    table.insert(flux._tweens, t)
    return t
end

function flux.update(dt)
    for i = #flux._tweens, 1, -1 do
        local t = flux._tweens[i]
        t.progress = t.progress + t.rate * dt
        local p = math.min(1, math.max(0, t.progress))
        local ease_p = t.ease_fn(p)
        for k, info in pairs(t.keys) do
            t.obj[k] = info.start + info.diff * ease_p
        end
        if t.progress >= 1 then
            table.remove(flux._tweens, i)
            if t.on_complete then t.on_complete() end
        end
    end
end

function flux.clear()
    flux._tweens = {}
end

return flux
