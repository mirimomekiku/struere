-- lib/gameplay_opts.lua
-- Runtime singleton for all gameplay configuration options.
-- Loaded from save on game start / settings save, read each frame by gameplay/battle.

local Save = require("lib.save")

local GameplayOpts = {
    next_queue_size  = 3,       -- 1 / 2 / 3 pieces shown in NEXT panel
    hold_enabled     = true,    -- SHIFT hold piece on/off
    randomizer       = "7bag",  -- "7bag"/"classic"/"gameboy"/"8bag"/"tgm1"/"tgm2"/"tgm3"
    srs_enabled      = true,    -- Super Rotation System wall-kicks on/off
    soft_drop_speed  = "normal",-- "slow"/"normal"/"fast"/"instant"
    ghost_enabled    = true,    -- ghost piece shadow on/off
}

-- Soft-drop interval table (seconds per row)
local SOFT_DROP_INTERVALS = {
    slow    = 0.15,
    normal  = 0.05,
    fast    = 0.018,
    instant = 0.0005,
}

function GameplayOpts.get_soft_drop_interval()
    return SOFT_DROP_INTERVALS[GameplayOpts.soft_drop_speed] or 0.05
end

function GameplayOpts.load()
    local gp = Save.get("gameplay_opts") or {}
    GameplayOpts.next_queue_size = gp.next_queue_size or 3
    GameplayOpts.hold_enabled    = gp.hold_enabled ~= false   -- default true
    GameplayOpts.randomizer      = gp.randomizer      or "7bag"
    GameplayOpts.srs_enabled     = gp.srs_enabled    ~= false  -- default true
    GameplayOpts.soft_drop_speed = gp.soft_drop_speed or "normal"
    GameplayOpts.ghost_enabled   = gp.ghost_enabled  ~= false  -- default true
end

function GameplayOpts.save()
    Save.set("gameplay_opts", {
        next_queue_size  = GameplayOpts.next_queue_size,
        hold_enabled     = GameplayOpts.hold_enabled,
        randomizer       = GameplayOpts.randomizer,
        srs_enabled      = GameplayOpts.srs_enabled,
        soft_drop_speed  = GameplayOpts.soft_drop_speed,
        ghost_enabled    = GameplayOpts.ghost_enabled,
    })
    Save.save()
end

return GameplayOpts
