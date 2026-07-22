-- roomy.lua - Screen/State manager for Love2D
local roomy = {}

local Manager = {}
Manager.__index = Manager

function Manager.new()
    local self = setmetatable({}, Manager)
    self.stack = {}
    return self
end

function Manager:current()
    return self.stack[#self.stack]
end

function Manager:push(state, ...)
    local cur = self:current()
    if cur and cur.pause then cur:pause() end
    table.insert(self.stack, state)
    if state.enter then state:enter(cur, ...) end
end

function Manager:pop(...)
    local cur = table.remove(self.stack)
    if cur and cur.leave then cur:leave(...) end
    local next_state = self:current()
    if next_state and next_state.resume then next_state:resume(...) end
    return cur
end

function Manager:switch(state, ...)
    if #self.stack > 0 then
        local cur = table.remove(self.stack)
        if cur and cur.leave then cur:leave() end
    end
    table.insert(self.stack, state)
    if state.enter then state:enter(nil, ...) end
end

function Manager:emit(event, ...)
    local cur = self:current()
    if cur and cur[event] then
        cur[event](cur, ...)
    end
end

function Manager:update(dt)
    self:emit("update", dt)
end

function Manager:draw()
    for _, state in ipairs(self.stack) do
        if state.draw then state:draw() end
    end
end

function roomy.Manager()
    return Manager.new()
end

return roomy
