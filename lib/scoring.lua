local constants = require("lib.constants")

local Scoring = {}

function Scoring.calculate(lines_cleared, level)
    local base = constants.SCORE_TABLE[lines_cleared] or 0
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
