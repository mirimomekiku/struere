local constants = require("lib.constants")

local Scoring = {}

-- Base line-clear scores (multiplied by level)
Scoring.LINE_SCORES = {
    [1] = 100,
    [2] = 300,
    [3] = 500,
    [4] = 800,
}

-- Bonus constants
Scoring.BACK_TO_BACK_BONUS  = 400   -- added on top when consecutive Tetris (4-line) clears
Scoring.ALL_CLEAR_BONUS     = 1000  -- added when board is completely empty after a clear
Scoring.BACK_TO_BACK_MULTIPLIER = 1.5

function Scoring.calculate(lines_cleared, level)
    local base = Scoring.LINE_SCORES[lines_cleared] or 0
    return base * level
end

function Scoring.update(state, lines_cleared)
    state.lines = state.lines + lines_cleared
    state.score = state.score + Scoring.calculate(lines_cleared, state.level)
    state.level = math.floor(state.lines / constants.LINES_PER_LEVEL) + 1
end

function Scoring.drop_interval(level)
    return constants.BASE_DROP_INTERVAL * (0.8 ^ (level - 1))
end

return Scoring
