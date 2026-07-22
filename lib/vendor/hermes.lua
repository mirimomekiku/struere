-- hermes.lua - Event Pub/Sub Dispatcher for Lua/Love2D
local hermes = {
    _listeners = {}
}

function hermes:on(event, fn)
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    table.insert(self._listeners[event], fn)
end

function hermes:off(event, fn)
    if not self._listeners[event] then return end
    for i, callback in ipairs(self._listeners[event]) do
        if callback == fn then
            table.remove(self._listeners[event], i)
            break
        end
    end
end

function hermes:emit(event, ...)
    local listeners = self._listeners[event]
    if listeners then
        for _, fn in ipairs(listeners) do
            fn(...)
        end
    end
end

function hermes:clear()
    self._listeners = {}
end

return hermes
