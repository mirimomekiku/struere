-- lib/gameplay_opts.lua
-- Runtime singleton for all gameplay configuration options.
-- Loaded from save on game start / settings save, read each frame by gameplay/battle.

local Save = require("lib.save")

local GameplayOpts = {
    next_queue_size  = 3,          -- 1 / 2 / 3 pieces shown in NEXT panel
    hold_enabled     = true,       -- SHIFT hold piece on/off
    randomizer       = "7bag",     -- "7bag"/"classic"/"gameboy"/"8bag"/"tgm1"/"tgm2"/"tgm3"
    srs_enabled      = true,       -- Super Rotation System wall-kicks on/off
    soft_drop_speed  = "5x",       -- "1x"/"5x"/"10x"/"20x"/"instant"
    dcd_frames       = 0,          -- DCD (DAS Cut Delay): 0 (Off), 1, 2, 3, 4 frames
    ghost_enabled    = true,       -- ghost piece shadow on/off
    ghost_style      = "tint",     -- "tint"/"outline"/"solid"/"disabled"
    grid_opacity     = 0.6,        -- 0.0 to 1.0 (0% to 100%)
    grid_pattern     = "lines",    -- "lines"/"check"/"dots"
    bgm_pack         = "chiptune", -- "chiptune"/"synthwave"/"classical"
    pitch_scaling    = true,       -- dynamic music pitch scaling on/off
}

-- Soft-drop interval table (seconds per row)
local SOFT_DROP_INTERVALS = {
    ["1x"]      = 0.20,
    ["5x"]      = 0.04,
    ["10x"]     = 0.02,
    ["20x"]     = 0.01,
    ["instant"] = 0.0001,
    -- Backward compatibility fallbacks:
    slow    = 0.20,
    normal  = 0.04,
    fast    = 0.02,
}

function GameplayOpts.get_soft_drop_interval()
    return SOFT_DROP_INTERVALS[GameplayOpts.soft_drop_speed] or 0.04
end

function GameplayOpts.get_dcd_seconds()
    return (GameplayOpts.dcd_frames or 0) * (1 / 60)
end

function GameplayOpts.load()
    local gp = Save.get("gameplay_opts") or {}
    GameplayOpts.next_queue_size = gp.next_queue_size or 3
    GameplayOpts.hold_enabled    = gp.hold_enabled ~= false   -- default true
    GameplayOpts.randomizer      = gp.randomizer      or "7bag"
    GameplayOpts.srs_enabled     = gp.srs_enabled    ~= false  -- default true
    GameplayOpts.soft_drop_speed = gp.soft_drop_speed or "5x"
    if GameplayOpts.soft_drop_speed == "normal" then GameplayOpts.soft_drop_speed = "5x" end
    if GameplayOpts.soft_drop_speed == "slow" then GameplayOpts.soft_drop_speed = "1x" end
    if GameplayOpts.soft_drop_speed == "fast" then GameplayOpts.soft_drop_speed = "10x" end
    GameplayOpts.dcd_frames      = gp.dcd_frames or 0
    GameplayOpts.ghost_enabled   = gp.ghost_enabled  ~= false  -- default true
    GameplayOpts.ghost_style     = gp.ghost_style or "tint"
    GameplayOpts.grid_opacity    = gp.grid_opacity or 0.6
    GameplayOpts.grid_pattern    = gp.grid_pattern or "lines"
    GameplayOpts.bgm_pack        = gp.bgm_pack or "chiptune"
    GameplayOpts.pitch_scaling   = gp.pitch_scaling ~= false  -- default true
end

function GameplayOpts.save()
    Save.set("gameplay_opts", {
        next_queue_size  = GameplayOpts.next_queue_size,
        hold_enabled     = GameplayOpts.hold_enabled,
        randomizer       = GameplayOpts.randomizer,
        srs_enabled      = GameplayOpts.srs_enabled,
        soft_drop_speed  = GameplayOpts.soft_drop_speed,
        dcd_frames       = GameplayOpts.dcd_frames,
        ghost_enabled    = GameplayOpts.ghost_enabled,
        ghost_style      = GameplayOpts.ghost_style,
        grid_opacity     = GameplayOpts.grid_opacity,
        grid_pattern     = GameplayOpts.grid_pattern,
        bgm_pack         = GameplayOpts.bgm_pack,
        pitch_scaling    = GameplayOpts.pitch_scaling,
    })
    Save.save()
end

return GameplayOpts
