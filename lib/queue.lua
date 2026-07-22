local Randomizer = require("lib.randomizer")
local Renderer = require("lib.renderer")

local Queue = {}

Queue.next_queue = {}
Queue.hold = nil
Queue.hold_used = false
Queue.HOLD_X = 320
Queue.HOLD_Y = 20
Queue.NEXT_X = 320
Queue.NEXT_Y = 120
Queue.MINI_CELL = 20

function Queue.init(randomizer, count)
    Queue.next_queue = {}
    Queue.hold = nil
    Queue.hold_used = false
    for _ = 1, (count or 5) do
        table.insert(Queue.next_queue, Randomizer.next(randomizer))
    end
end

function Queue.pop(randomizer)
    local piece_type = table.remove(Queue.next_queue, 1)
    table.insert(Queue.next_queue, Randomizer.next(randomizer))
    Queue.hold_used = false
    return piece_type
end

function Queue.hold_piece(type)
    if Queue.hold_used then return nil end
    Queue.hold_used = true
    local held = Queue.hold
    Queue.hold = type
    return held
end

function Queue.can_hold()
    return not Queue.hold_used
end

function Queue.peek()
    return Queue.next_queue[1]
end

function Queue.draw(theme)
    local mini = Queue.MINI_CELL

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("HOLD", Queue.HOLD_X, Queue.HOLD_Y - 15)
    love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3])
    love.graphics.rectangle("line", Queue.HOLD_X, Queue.HOLD_Y, mini * 5, mini * 4)

    if Queue.hold then
        if Queue.hold_used then
            love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
        else
            love.graphics.setColor(1, 1, 1)
        end
        Renderer.draw_mini_piece(Queue.hold, Queue.HOLD_X, Queue.HOLD_Y, mini, theme)
    end

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("NEXT", Queue.NEXT_X, Queue.NEXT_Y - 15)

    for i = 1, math.min(5, #Queue.next_queue) do
        local y_off = Queue.NEXT_Y + (i - 1) * (mini * 4 + 10)
        love.graphics.setColor(theme.grid_border[1], theme.grid_border[2], theme.grid_border[3])
        love.graphics.rectangle("line", Queue.NEXT_X, y_off, mini * 5, mini * 4)
        Renderer.draw_mini_piece(Queue.next_queue[i], Queue.NEXT_X, y_off, mini, theme)
    end
end

return Queue
