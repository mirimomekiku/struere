local Scoring = require("lib.scoring")

local BaseMode = {}
BaseMode.__index = BaseMode

function BaseMode.new(config)
    local self = setmetatable({}, BaseMode)
    self.name = config.name or "Base"
    self.start_level = config.start_level or 1
    self.lines_per_level = config.lines_per_level or 10
    self.max_level = config.max_level or 20
    self.line_goal = config.line_goal or nil
    self.time_limit = config.time_limit or nil
    self.lock_delay = config.lock_delay or 0.5
    self.fixed_gravity = config.fixed_gravity or false
    self.can_lose = config.can_lose ~= false
    self.timer = 0
    self.combo = 0
    self.max_combo = 0
    self.pieces_placed = 0
    self.lines_cleared = 0
    return self
end

function BaseMode:onStart(state)
    state.level = self.start_level
end

function BaseMode:onTick(state, dt)
    self.timer = self.timer + dt
    if self.time_limit and self.timer >= self.time_limit then
        state.game_over = true
    end
end

function BaseMode:onLineClear(state, lines_cleared, rows)
    self.lines_cleared = self.lines_cleared + lines_cleared
    if lines_cleared > 0 then
        self.combo = self.combo + 1
        if self.combo > self.max_combo then
            self.max_combo = self.combo
        end
        if not self.fixed_gravity then
            state.lines = state.lines + lines_cleared
            state.level = math.min(
                math.floor(state.lines / self.lines_per_level) + 1,
                self.max_level
            )
        end
        if self.line_goal and self.lines_cleared >= self.line_goal then
            state.game_over = true
            state.victory = true
        end
    else
        self.combo = 0
    end
end

function BaseMode:onPieceLock(state)
    self.pieces_placed = self.pieces_placed + 1
end

function BaseMode:onGameOver(state)
end

function BaseMode:checkGameOver(state)
    return state.game_over
end

function BaseMode:getDropInterval(state)
    if self.fixed_gravity then
        return Scoring.drop_interval(self.start_level)
    end
    return Scoring.drop_interval(state.level)
end

function BaseMode:getScoringMultiplier()
    return 1
end

function BaseMode:getTimeFormatted()
    local minutes = math.floor(self.timer / 60)
    local seconds = self.timer % 60
    return string.format("%d:%05.2f", minutes, seconds)
end

function BaseMode:drawHUD(state, x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SCORE", x, y)
    love.graphics.print(tostring(state.score), x, y + 20)
    love.graphics.print("LEVEL", x, y + 60)
    love.graphics.print(tostring(state.level), x, y + 80)
    love.graphics.print("LINES", x, y + 120)
    love.graphics.print(tostring(state.lines), x, y + 140)
    love.graphics.print("TIME", x, y + 180)
    love.graphics.print(self:getTimeFormatted(), x, y + 200)
end

return BaseMode
