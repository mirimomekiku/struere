local roomy = require("lib.vendor.roomy")

local StateMgr = {}
StateMgr.manager = roomy.Manager()
StateMgr.registered = {}

function StateMgr.register(name, state_module)
    StateMgr.registered[name] = state_module
end

function StateMgr.switch(name, ...)
    local state = StateMgr.registered[name]
    if state then
        StateMgr.manager:switch(state, ...)
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
    StateMgr.manager:update(dt)
end

function StateMgr.draw()
    StateMgr.manager:draw()
end

function StateMgr.keypressed(key)
    StateMgr.manager:emit("keypressed", key)
end

function StateMgr.keyreleased(key)
    StateMgr.manager:emit("keyreleased", key)
end

return StateMgr
