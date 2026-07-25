local roomy = require("lib.vendor.roomy")
local Audio = require("lib.audio")

local StateMgr = {}
StateMgr.manager = roomy.Manager()
StateMgr.registered = {}

StateMgr.transition = {
    active = false,
    timer = 0,
    duration = 0.45,
    switched = false,
    pending_switch = nil,
}

function StateMgr.register(name, state_module)
    StateMgr.registered[name] = state_module
end

function StateMgr.switch(name, ...)
    local state = StateMgr.registered[name]
    if state then
        StateMgr.manager:switch(state, ...)
    end
end

function StateMgr.switch_with_swoosh(name, ...)
    local state = StateMgr.registered[name]
    if not state then return end

    local args = {...}
    Audio.play("swoosh")
    StateMgr.transition.active = true
    StateMgr.transition.timer = 0
    StateMgr.transition.duration = 0.42
    StateMgr.transition.switched = false
    StateMgr.transition.pending_switch = function()
        StateMgr.manager:switch(state, unpack(args))
    end
end

function StateMgr.push(name, ...)
    local state = StateMgr.registered[name]
    if state then
        StateMgr.manager:push(state, ...)
    end
end

function StateMgr.pop(...)
    return StateMgr.manager:pop(...)
end

function StateMgr.update(dt)
    if StateMgr.transition.active then
        StateMgr.transition.timer = StateMgr.transition.timer + dt
        local half = StateMgr.transition.duration * 0.45
        if not StateMgr.transition.switched and StateMgr.transition.timer >= half then
            StateMgr.transition.switched = true
            if StateMgr.transition.pending_switch then
                StateMgr.transition.pending_switch()
            end
        end
        if StateMgr.transition.timer >= StateMgr.transition.duration then
            StateMgr.transition.active = false
        end
    end

    StateMgr.manager:update(dt)
end

function StateMgr.draw()
    StateMgr.manager:draw()

    if StateMgr.transition.active then
        local W = love.graphics.getWidth()
        local H = love.graphics.getHeight()
        local t = math.min(1, StateMgr.transition.timer / StateMgr.transition.duration)

        -- Smooth swoosh wipe animation with neon sweep banner
        local progress = t
        local ease = progress < 0.5 and (4 * progress * progress * progress) or (1 - math.pow(-2 * progress + 2, 3) / 2)

        local cx = (ease * 2.4 - 0.7) * W
        local band_w = W * 0.65
        local alpha = math.sin(progress * math.pi)

        love.graphics.push()
        -- Dark fade curtain
        love.graphics.setColor(0.02, 0.03, 0.06, alpha * 0.92)
        love.graphics.rectangle("fill", 0, 0, W, H)

        -- Angled glowing stripes
        local points = {
            cx - band_w * 0.5, 0,
            cx + band_w * 0.5, 0,
            cx + band_w * 0.2, H,
            cx - band_w * 0.8, H
        }

        love.graphics.setColor(0.15, 0.85, 1.00, alpha * 0.85)
        love.graphics.polygon("fill", points)

        local inner_points = {
            cx - band_w * 0.2, 0,
            cx + band_w * 0.4, 0,
            cx + band_w * 0.1, H,
            cx - band_w * 0.5, H
        }
        love.graphics.setColor(0.85, 0.25, 1.00, alpha * 0.75)
        love.graphics.polygon("fill", inner_points)

        -- Bright center streak line
        love.graphics.setColor(1, 1, 1, alpha * 0.95)
        love.graphics.setLineWidth(4)
        love.graphics.line(cx + band_w * 0.1, 0, cx - band_w * 0.2, H)
        love.graphics.setLineWidth(1)

        love.graphics.pop()
    end
end

function StateMgr.keypressed(key)
    StateMgr.manager:emit("keypressed", key)
end

function StateMgr.keyreleased(key)
    StateMgr.manager:emit("keyreleased", key)
end

return StateMgr
