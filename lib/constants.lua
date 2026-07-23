-- Resolution-aware constants for TetriX
-- Base resolution: 1280x720. Layout is dynamically centered in gameplay.

local C = {
    GRID_COLS = 10,
    GRID_ROWS = 20,
    BUFFER_ROWS = 20,
    TOTAL_ROWS = 40,
    CELL_SIZE = 30,    -- recalculated at runtime based on window height

    PIECE_TYPES = {"I", "O", "T", "S", "Z", "J", "L"},

    COLORS = {
        I = {0, 240, 240},
        O = {240, 240, 0},
        T = {160, 0, 240},
        S = {0, 240, 0},
        Z = {240, 0, 0},
        J = {0, 0, 240},
        L = {240, 160, 0},
    },

    BASE_DROP_INTERVAL = 1.0,
    SOFT_DROP_INTERVAL = 0.05,
    LOCK_DELAY = 0.5,
    LOCK_MOVES_MAX = 15,

    DAS_DELAY = 0.5,
    ARR_DELAY = 0.05,

    LINES_PER_LEVEL = 10,
    SCORE_TABLE = {
        [1] = 100,
        [2] = 300,
        [3] = 500,
        [4] = 800,
    },

    -- Window defaults (overridden by saved resolution)
    WINDOW_WIDTH = 1280,
    WINDOW_HEIGHT = 720,

    -- Board position: dynamically computed in gameplay
    BOARD_X = 0,
    BOARD_Y = 0,

    -- Available resolutions
    RESOLUTIONS = {
        {w = 640,  h = 480,  label = "640×480"},
        {w = 1024, h = 768,  label = "1024×768"},
        {w = 1280, h = 720,  label = "1280×720"},
        {w = 1366, h = 768,  label = "1366×768"},
    },
    RESOLUTION_IDX = 3,  -- default: 1280x720

    SHAKE_INTENSITY = 6,
    SHAKE_DURATION = 0.15,
    FLASH_DURATION = 0.3,
    PARTICLE_COUNT = 20,
    NEXT_QUEUE_SIZE = 5,

    DEFAULT_MASTER_VOLUME = 0.8,
    DEFAULT_SFX_VOLUME = 1.0,
    DEFAULT_MUSIC_VOLUME = 0.5,
    SAVE_FILE = "save_data.bin",
}

-- Helper: recompute board position and cell size from current window
function C.recompute_layout()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    -- Cell size: fit 20-row board into 90% of window height
    C.CELL_SIZE = math.floor(h * 0.9 / 20)
    -- Center board horizontally, small top margin
    local board_w = C.GRID_COLS * C.CELL_SIZE
    local board_h = C.GRID_ROWS * C.CELL_SIZE
    C.BOARD_X = math.floor((w - board_w) / 2)
    C.BOARD_Y = math.floor((h - board_h) / 2)
    C.WINDOW_WIDTH = w
    C.WINDOW_HEIGHT = h
end

return C
