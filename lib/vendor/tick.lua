-- tick.lua - Micro timer and tick library for Love2D
local tick = {
    _timers = {}
}

function tick.delay(fn, delay)
    local t = { fn = fn, time = delay, timer = 0, recur = false }
    table.insert(tick._timers, t)
    return t
end

function tick.recur(fn, interval)
    local t = { fn = fn, time = interval, timer = 0, recur = true }
    table.insert(tick._timers, t)
    return t
end

function tick.remove(t)
    for i, timer in ipairs(tick._timers) do
        if timer == t then
            table.remove(tick._timers, i)
            break
        end
    end
end

function tick.clear()
    tick._timers = {}
end

function tick.update(dt)
    for i = #tick._timers, 1, -1 do
        local t = tick._timers[i]
        t.timer = t.timer + dt
        if t.timer >= t.time then
            t.fn(t.timer)
            if t.recur then
                t.timer = t.timer - t.time
            else
                table.remove(tick._timers, i)
            end
        end
    end
end

return tick
