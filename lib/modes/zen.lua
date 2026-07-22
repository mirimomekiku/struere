local BaseMode = require("lib.modes.base")
local Board = require("lib.board")
local Queue = require("lib.queue")

local Zen = {}
Zen.__index = Zen
setmetatable(Zen, { __index = BaseMode })

function Zen.new(config)
    config = config or {}
    config.name = config.name or "Zen"
    config.fixed_gravity = true
    config.start_level = config.start_level or 1
    config.can_lose = false
    return BaseMode.new(config)
end

function Zen:checkGameOver(state)
    return false
end

function Zen:resetBoard(state)
    state.board = Board.new()
    Queue.init(state.randomizer, 5)
    state.game_over = false
    state.current_piece = nil
end

function Zen:onStart(state)
    state.level = self.start_level
end

function Zen:drawHUD(state, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE", x, y)
    love.graphics.print(tostring(state.score), x, y + 20)

    love.graphics.print("LINES", x, y + 60)
    love.graphics.print(tostring(state.lines), x, y + 80)

    love.graphics.print("TIME", x, y + 130)
    love.graphics.setColor(0, 1, 1)
    love.graphics.print(self:getTimeFormatted(), x, y + 150)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Mode: Zen", x, y + 210)
    love.graphics.print("R: Clear Board", x, y + 230)
end

return Zen
