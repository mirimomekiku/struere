local constants = require("lib.constants")

local Scoring = {}

-- Base line-clear scores (multiplied by level)
Scoring.LINE_SCORES = {
    [1] = 100,
    [2] = 300,
    [3] = 500,
    [4] = 800,
}

-- T-Spin base scores (multiplied by level)
Scoring.T_SPIN_SCORES = {
    full = {
        [0] = 400,
        [1] = 800,
        [2] = 1200,
        [3] = 1600,
    },
    mini = {
        [0] = 100,
        [1] = 200,
        [2] = 400,
    }
}

-- Bonus constants
Scoring.BACK_TO_BACK_BONUS      = 400   -- added on top when consecutive Tetris clears
Scoring.ALL_CLEAR_BONUS         = 1000  -- added when board is completely empty after a clear
Scoring.BACK_TO_BACK_MULTIPLIER = 1.5

function Scoring.calculate(lines_cleared, level, t_spin_type, is_b2b)
    local base = 0
    local is_t_spin = (t_spin_type == "full" or t_spin_type == "mini")
    
    if is_t_spin then
        local tab = Scoring.T_SPIN_SCORES[t_spin_type]
        base = (tab and tab[lines_cleared]) or 400
    else
        base = Scoring.LINE_SCORES[lines_cleared] or 0
    end

    local score = base * level

    -- B2B multiplier applies to Tetris (4 lines) and T-Spins with 1+ lines cleared
    local b2b_eligible = (lines_cleared == 4) or (is_t_spin and lines_cleared > 0)
    if is_b2b and b2b_eligible then
        score = math.floor(score * Scoring.BACK_TO_BACK_MULTIPLIER)
    end

    return score
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
