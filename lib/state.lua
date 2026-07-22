local State = {}

State.screens = {}
State.current = nil
State.current_name = nil
State.stack = {}

function State.register(name, screen)
    State.screens[name] = screen
end

function State.switch(name, params)
    State.stack = {}
    State.current_name = name
    State.current = State.screens[name]
    if State.current and State.current.load then
        State.current.load(params)
    end
end

function State.push(name, params)
    table.insert(State.stack, {
        name = State.current_name,
        screen = State.current,
    })
    State.current_name = name
    State.current = State.screens[name]
    if State.current and State.current.load then
        State.current.load(params)
    end
end

function State.pop()
    if #State.stack > 0 then
        local prev = table.remove(State.stack)
        State.current_name = prev.name
        State.current = prev.screen
        if State.current and State.current.resume then
            State.current.resume()
        end
    end
end

function State.update(dt)
    if State.current and State.current.update then
        State.current.update(dt)
    end
end

function State.draw()
    for _, entry in ipairs(State.stack) do
        if entry.screen and entry.screen.draw then
            entry.screen.draw()
        end
    end
    if State.current and State.current.draw then
        State.current.draw()
    end
end

function State.keypressed(key)
    if State.current and State.current.keypressed then
        State.current.keypressed(key)
    end
end

function State.keyreleased(key)
    if State.current and State.current.keyreleased then
        State.current.keyreleased(key)
    end
end

return State
