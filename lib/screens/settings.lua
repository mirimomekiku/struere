local Themes = require("lib.themes")
local Audio = require("lib.audio")
local Input = require("lib.input")
local Save = require("lib.save")
local ShaderManager = require("lib.shaders.manager")
local constants = require("lib.constants")
local shack = require("lib.vendor.shack")
local GameplayOpts = require("lib.gameplay_opts")
local Fonts = require("lib.fonts")

local function rr(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r or 6, r or 6)
end

local function rl(x, y, w, h, r)
    love.graphics.rectangle("line", x, y, w, h, r or 6, r or 6)
end

local Settings = {}

Settings.ALL_TABS = {"CONTROLS", "SHADERS", "AUDIO", "DISPLAY", "GAMEPLAY"}
Settings.PAUSE_TABS = {"CONTROLS", "SHADERS", "AUDIO", "DISPLAY"}
Settings.from_pause = false

Settings.up_modes = {"rotate_cw", "hard_drop", "rotate_ccw", "off"}
Settings.up_mode_labels = {
    rotate_cw = "Rotate CW",
    hard_drop = "Hard Drop",
    rotate_ccw = "Rotate CCW",
    off = "Unmapped / Off"
}
Settings.up_idx = 1

Settings.palettes = {
    "GameBoy Green", "Cyberpunk Neon", "NES Classic", "CGA Mode 1",
    "Monochromatic",  "Vaporwave",
    "GameBoy Pocket", "Amber LCD",     "Sega Master System",
    "ZX Spectrum",    "Famicom Disk",  "Arctic Ice",
}

Settings.res_idx = 3

Settings.cpu_difficulties  = {"easy", "medium", "hard", "boss"}
Settings.cpu_diff_labels   = {easy = "Easy", medium = "Medium", hard = "Hard", boss = "Boss ★"}
Settings.cpu_diff_idx      = 2

Settings.gp_next_queue      = 3
Settings.gp_hold            = true
Settings.gp_rand_keys       = {"7bag","classic","gameboy","8bag","tgm1","tgm2","tgm3"}
Settings.gp_rand_names      = {"7-Bag","Classic","Game Boy","8-Bag","TGM1","TGM2","TGM3"}
Settings.gp_rand_idx        = 1
Settings.gp_srs             = true
Settings.gp_softdrop_keys   = {"slow","normal","fast","instant"}
Settings.gp_softdrop_labels = {"Slow","Normal","Fast","Instant"}
Settings.gp_softdrop_idx    = 2
Settings.gp_ghost           = true

Settings.shader_scroll_top  = 0

function Settings.get_active_tabs()
    return Settings.from_pause and Settings.PAUSE_TABS or Settings.ALL_TABS
end

function Settings:enter(previous, opts)
    opts = opts or {}
    Settings.from_pause = (opts.from_pause == true)
    Settings.tab = 1
    Settings.selected = 1
    Settings.shader_scroll_top = 0
    Settings.loadValues()
end

function Settings.loadValues()
    local saved_up = Save.get("settings", "up_mode") or "rotate_cw"
    for i, m in ipairs(Settings.up_modes) do
        if m == saved_up then Settings.up_idx = i; break end
    end

    ShaderManager.enabled           = Save.get("settings", "shader_enabled") ~= false
    ShaderManager.crt_enabled       = Save.get("settings", "crt_enabled") ~= false
    ShaderManager.curvature         = math.max(3.0, math.min(5.5, Save.get("settings", "curvature") or 3.5))
    
    ShaderManager.chromatic_enabled = Save.get("settings", "chromatic_enabled") ~= false
    ShaderManager.chromatic_idx     = Save.get("settings", "chromatic_idx") or 3
    if ShaderManager.chromatic_idx < 1 or ShaderManager.chromatic_idx > #ShaderManager.chromatic_values then ShaderManager.chromatic_idx = 3 end
    ShaderManager.chromatic_strength= ShaderManager.chromatic_values[ShaderManager.chromatic_idx] / 1000.0

    ShaderManager.pixel_matrix_enabled=Save.get("settings", "pixel_matrix_enabled") == true
    ShaderManager.pixel_size_idx    = Save.get("settings", "pixel_size_idx") or 4
    if ShaderManager.pixel_size_idx < 1 or ShaderManager.pixel_size_idx > #ShaderManager.pixel_size_values then ShaderManager.pixel_size_idx = 4 end
    ShaderManager.pixel_size        = ShaderManager.pixel_size_values[ShaderManager.pixel_size_idx]
    ShaderManager.matrix_grid       = Save.get("settings", "matrix_grid") or 0.5

    ShaderManager.motion_blur_enabled=Save.get("settings", "motion_blur_enabled") == true
    ShaderManager.motion_blur_strength=Save.get("settings", "motion_blur_strength") or 0.75

    ShaderManager.noise_enabled     = Save.get("settings", "noise_enabled") == true
    ShaderManager.noise_intensity   = math.max(0.10, math.min(0.60, Save.get("settings", "noise_intensity") or 0.25))

    ShaderManager.phosphor_enabled   = Save.get("settings", "phosphor_enabled") == true
    ShaderManager.phosphor_decay    = Save.get("settings", "phosphor_decay") or 0.85

    ShaderManager.jitter_enabled    = Save.get("settings", "jitter_enabled") == true
    ShaderManager.jitter_idx        = Save.get("settings", "jitter_idx") or 3
    if ShaderManager.jitter_idx < 1 or ShaderManager.jitter_idx > #ShaderManager.jitter_values then ShaderManager.jitter_idx = 3 end
    ShaderManager.jitter_strength   = ShaderManager.jitter_values[ShaderManager.jitter_idx]

    ShaderManager.vhs_enabled       = Save.get("settings", "vhs_enabled") == true
    ShaderManager.vhs_intensity     = Save.get("settings", "vhs_intensity") or 0.4

    ShaderManager.scanlines_enabled = Save.get("settings", "scanlines_enabled") ~= false
    ShaderManager.scanline_intensity= Save.get("settings", "scanline_intensity") or 0.3

    ShaderManager.bloom_enabled     = Save.get("settings", "bloom_enabled") ~= false
    ShaderManager.bloom_strength    = Save.get("settings", "bloom_strength") or 0.5

    ShaderManager.palette_enabled   = Save.get("settings", "palette_enabled") ~= false
    ShaderManager.palette_mode      = Save.get("settings", "palette_mode") or 0

    ShaderManager.ntsc_enabled      = Save.get("settings", "ntsc_enabled") == true

    Settings.res_idx     = Save.get("settings", "resolution_idx") or 3

    local saved_diff = Save.get("settings", "cpu_difficulty") or "medium"
    for i, d in ipairs(Settings.cpu_difficulties) do
        if d == saved_diff then Settings.cpu_diff_idx = i; break end
    end

    local gp = Save.get("gameplay_opts") or {}
    Settings.gp_next_queue = gp.next_queue_size or 3
    Settings.gp_hold       = gp.hold_enabled ~= false
    Settings.gp_srs        = gp.srs_enabled  ~= false
    Settings.gp_ghost      = gp.ghost_enabled ~= false
    local saved_rand = gp.randomizer or "7bag"
    Settings.gp_rand_idx = 1
    for i, k in ipairs(Settings.gp_rand_keys) do
        if k == saved_rand then Settings.gp_rand_idx = i; break end
    end
    local saved_sd = gp.soft_drop_speed or "normal"
    Settings.gp_softdrop_idx = 2
    for i, k in ipairs(Settings.gp_softdrop_keys) do
        if k == saved_sd then Settings.gp_softdrop_idx = i; break end
    end
end

function Settings.saveValues()
    local up_mode = Settings.up_modes[Settings.up_idx]
    Input.apply_up_button_mode(up_mode)

    local res = constants.RESOLUTIONS[Settings.res_idx]
    if res then
        local cur_w, cur_h = love.graphics.getDimensions()
        if cur_w ~= res.w or cur_h ~= res.h then
            love.window.setMode(res.w, res.h)
            ShaderManager.init()
            shack:setDimensions(res.w, res.h)
        end
        constants.RESOLUTION_IDX = Settings.res_idx
        constants.recompute_layout()
    end

    Save.updateSettings({
        up_mode = up_mode,
        master_volume = Audio.master_vol or 0.8,
        sfx_volume = Audio.sfx_vol or 1.0,
        music_volume = Audio.music_vol or 0.5,
        shader_enabled = ShaderManager.enabled,
        crt_enabled = ShaderManager.crt_enabled,
        curvature = ShaderManager.curvature,
        chromatic_enabled = ShaderManager.chromatic_enabled,
        chromatic_idx = ShaderManager.chromatic_idx,
        pixel_matrix_enabled = ShaderManager.pixel_matrix_enabled,
        pixel_size_idx = ShaderManager.pixel_size_idx,
        matrix_grid = ShaderManager.matrix_grid,
        motion_blur_enabled = ShaderManager.motion_blur_enabled,
        motion_blur_strength = ShaderManager.motion_blur_strength,
        noise_enabled = ShaderManager.noise_enabled,
        noise_intensity = ShaderManager.noise_intensity,
        phosphor_enabled = ShaderManager.phosphor_enabled,
        phosphor_decay = ShaderManager.phosphor_decay,
        jitter_enabled = ShaderManager.jitter_enabled,
        jitter_idx = ShaderManager.jitter_idx,
        vhs_enabled = ShaderManager.vhs_enabled,
        vhs_intensity = ShaderManager.vhs_intensity,
        scanlines_enabled = ShaderManager.scanlines_enabled,
        scanline_intensity = ShaderManager.scanline_intensity,
        bloom_enabled = ShaderManager.bloom_enabled,
        bloom_strength = ShaderManager.bloom_strength,
        palette_enabled = ShaderManager.palette_enabled,
        palette_mode = ShaderManager.palette_mode,
        ntsc_enabled = ShaderManager.ntsc_enabled,
        resolution_idx = Settings.res_idx,
    })

    GameplayOpts.next_queue_size = Settings.gp_next_queue
    GameplayOpts.hold_enabled    = Settings.gp_hold
    GameplayOpts.randomizer      = Settings.gp_rand_keys[Settings.gp_rand_idx]
    GameplayOpts.srs_enabled     = Settings.gp_srs
    GameplayOpts.soft_drop_speed = Settings.gp_softdrop_keys[Settings.gp_softdrop_idx]
    GameplayOpts.ghost_enabled   = Settings.gp_ghost
    GameplayOpts.save()
end

function Settings.get_shader_options()
    return {
        {
            label = "Master Shaders",
            type = "toggle",
            val = ShaderManager.enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.enabled = not ShaderManager.enabled end,
            desc = "Master ON/OFF switch for all post-processing GPU shader effects"
        },
        {
            label = "CRT Distortion",
            type = "toggle",
            val = ShaderManager.crt_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.crt_enabled = not ShaderManager.crt_enabled end,
            desc = "Retro curved screen barrel distortion & corner curvature"
        },
        {
            label = "Distortion Curvature Width",
            type = "slider",
            val = string.format("%.2f (Width)", ShaderManager.curvature),
            pct = (ShaderManager.curvature - 3.0) / 2.5,
            action = function(dir)
                ShaderManager.curvature = math.max(3.0, math.min(5.5, ShaderManager.curvature + dir * 0.25))
            end,
            desc = "Adjust screen curvature width (limited from 3.0 min to 5.5 max)"
        },
        {
            label = "Chromatic Aberration",
            type = "toggle",
            val = ShaderManager.chromatic_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.chromatic_enabled = not ShaderManager.chromatic_enabled end,
            desc = "Separate RGB color channel fringe offset"
        },
        {
            label = "Chromatic Shift Offset",
            type = "slider",
            val = string.format("%.2f px", ShaderManager.chromatic_values[ShaderManager.chromatic_idx]),
            pct = (ShaderManager.chromatic_idx - 1) / (#ShaderManager.chromatic_values - 1),
            action = function(dir)
                ShaderManager.chromatic_idx = math.max(1, math.min(#ShaderManager.chromatic_values, ShaderManager.chromatic_idx + dir))
                ShaderManager.chromatic_strength = ShaderManager.chromatic_values[ShaderManager.chromatic_idx] / 1000.0
            end,
            desc = "RGB color channel fringe distance: 0.5 / 0.75 / 1 / 1.25 / 1.5 / 2 / 2.25 px"
        },
        {
            label = "Pixel Matrix",
            type = "toggle",
            val = ShaderManager.pixel_matrix_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.pixel_matrix_enabled = not ShaderManager.pixel_matrix_enabled end,
            desc = "Retro dot matrix pixel grid overlay"
        },
        {
            label = "Pixel Matrix Scale",
            type = "slider",
            val = string.format("%.2f px", ShaderManager.pixel_size_values[ShaderManager.pixel_size_idx]),
            pct = (ShaderManager.pixel_size_idx - 1) / (#ShaderManager.pixel_size_values - 1),
            action = function(dir)
                ShaderManager.pixel_size_idx = math.max(1, math.min(#ShaderManager.pixel_size_values, ShaderManager.pixel_size_idx + dir))
                ShaderManager.pixel_size = ShaderManager.pixel_size_values[ShaderManager.pixel_size_idx]
            end,
            desc = "Pixel matrix cell scale: 1.25 / 1.5 / 1.75 / 2 / 2.25 / 2.5 px"
        },
        {
            label = "Pixel Matrix Grid Darkness",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.matrix_grid * 100),
            pct = ShaderManager.matrix_grid,
            action = function(dir)
                ShaderManager.matrix_grid = math.max(0, math.min(1.0, ShaderManager.matrix_grid + dir * 0.05))
            end,
            desc = "Intensity of dark grid lines between matrix pixels"
        },
        {
            label = "Motion Blur / Ghosting",
            type = "toggle",
            val = ShaderManager.motion_blur_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.motion_blur_enabled = not ShaderManager.motion_blur_enabled end,
            desc = "Smooth frame persistence ghosting effect for fast piece movements"
        },
        {
            label = "Motion Blur Persistence",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.motion_blur_strength * 100),
            pct = (ShaderManager.motion_blur_strength - 0.1) / 0.85,
            action = function(dir)
                ShaderManager.motion_blur_strength = math.max(0.1, math.min(0.95, ShaderManager.motion_blur_strength + dir * 0.05))
            end,
            desc = "Duration & opacity of motion blur ghost trails"
        },
        {
            label = "Signal Noise / Grain",
            type = "toggle",
            val = ShaderManager.noise_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.noise_enabled = not ShaderManager.noise_enabled end,
            desc = "Analog TV signal static noise grain"
        },
        {
            label = "Grain Noise Intensity",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.noise_intensity * 100),
            pct = (ShaderManager.noise_intensity - 0.10) / 0.50,
            action = function(dir)
                ShaderManager.noise_intensity = math.max(0.10, math.min(0.60, ShaderManager.noise_intensity + dir * 0.05))
            end,
            desc = "Static signal noise overlay intensity (limited between 10% and 60%)"
        },
        {
            label = "Phosphor Decay",
            type = "toggle",
            val = ShaderManager.phosphor_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.phosphor_enabled = not ShaderManager.phosphor_enabled end,
            desc = "Vintage arcade CRT phosphor screen luminescence trail"
        },
        {
            label = "Phosphor Trail Factor",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.phosphor_decay * 100),
            pct = (ShaderManager.phosphor_decay - 0.1) / 0.85,
            action = function(dir)
                ShaderManager.phosphor_decay = math.max(0.1, math.min(0.95, ShaderManager.phosphor_decay + dir * 0.05))
            end,
            desc = "Afterglow decay persistence factor for glowing phosphor"
        },
        {
            label = "Horizontal Jitter",
            type = "toggle",
            val = ShaderManager.jitter_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.jitter_enabled = not ShaderManager.jitter_enabled end,
            desc = "Random horizontal line scan sync jitter distortion"
        },
        {
            label = "Horizontal Jitter Amplitude",
            type = "slider",
            val = string.format("%.1f%%", ShaderManager.jitter_values[ShaderManager.jitter_idx] * 100),
            pct = (ShaderManager.jitter_idx - 1) / (#ShaderManager.jitter_values - 1),
            action = function(dir)
                ShaderManager.jitter_idx = math.max(1, math.min(#ShaderManager.jitter_values, ShaderManager.jitter_idx + dir))
                ShaderManager.jitter_strength = ShaderManager.jitter_values[ShaderManager.jitter_idx]
            end,
            desc = "Horizontal jitter amplitude: 5% / 7.5% / 10% / 15% / 20%"
        },
        {
            label = "VHS Tape Filter",
            type = "toggle",
            val = ShaderManager.vhs_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.vhs_enabled = not ShaderManager.vhs_enabled end,
            desc = "VCR VHS tape tracking lines, tape noise & color bleed"
        },
        {
            label = "VHS Tape Noise & Tracking",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.vhs_intensity * 100),
            pct = ShaderManager.vhs_intensity,
            action = function(dir)
                ShaderManager.vhs_intensity = math.max(0, math.min(1.0, ShaderManager.vhs_intensity + dir * 0.05))
            end,
            desc = "Intensity of VCR tracking bar distortions and tape static"
        },
        {
            label = "CRT Horizontal Scanlines",
            type = "toggle",
            val = ShaderManager.scanlines_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.scanlines_enabled = not ShaderManager.scanlines_enabled end,
            desc = "Classic horizontal CRT cathode scanline overlay"
        },
        {
            label = "Scanlines Intensity",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.scanline_intensity * 100),
            pct = ShaderManager.scanline_intensity,
            action = function(dir)
                ShaderManager.scanline_intensity = math.max(0, math.min(1.0, ShaderManager.scanline_intensity + dir * 0.05))
            end,
            desc = "Darkness opacity of horizontal scanline stripes"
        },
        {
            label = "Bloom & Glow",
            type = "toggle",
            val = ShaderManager.bloom_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.bloom_enabled = not ShaderManager.bloom_enabled end,
            desc = "Soft neon light bloom & glowing block highlights"
        },
        {
            label = "Bloom Strength",
            type = "slider",
            val = string.format("%.0f%%", ShaderManager.bloom_strength * 100),
            pct = ShaderManager.bloom_strength,
            action = function(dir)
                ShaderManager.bloom_strength = math.max(0, math.min(1.0, ShaderManager.bloom_strength + dir * 0.05))
            end,
            desc = "Intensity & radius of neon bloom aura"
        },
        {
            label = "Palette Limiting & Dither",
            type = "toggle",
            val = ShaderManager.palette_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.palette_enabled = not ShaderManager.palette_enabled end,
            desc = "Restrict colors to retro handheld/arcade color palettes with dithering"
        },
        {
            label = "Active Palette Preset",
            type = "choice",
            val = Settings.palettes[ShaderManager.palette_mode + 1] or "GameBoy Green",
            action = function(dir)
                ShaderManager.palette_mode = (ShaderManager.palette_mode + dir) % #Settings.palettes
            end,
            desc = "Select retro color palette preset (GameBoy, Neon, NES, Monochrome, etc.)"
        },
        {
            label = "NTSC Composite Artifacts",
            type = "toggle",
            val = ShaderManager.ntsc_enabled and "ENABLED" or "DISABLED",
            action = function(dir) ShaderManager.ntsc_enabled = not ShaderManager.ntsc_enabled end,
            desc = "NTSC TV composite video signal fringing & RF artifacts"
        },
    }
end

function Settings:draw(theme)
    theme = theme or Themes.get()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    local px = math.floor(W * 0.05)
    local py = math.floor(H * 0.04)
    local pw = W - px * 2
    local ph = H - py * 2

    love.graphics.setColor(0.02, 0.02, 0.05, 0.95)
    rr(px, py, pw, ph, 16)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.6)
    love.graphics.setLineWidth(2)
    rl(px, py, pw, ph, 16)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(Fonts.get(26))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS & OPTIONS", px, py + 16, pw, "center")

    local active_tabs = Settings.get_active_tabs()
    if Settings.tab > #active_tabs then Settings.tab = 1 end
    local tab_w = math.floor(pw / #active_tabs) - 8
    for i, title in ipairs(active_tabs) do
        local tx = px + 8 + (i - 1) * (tab_w + 8)
        local ty = py + 56
        local is_curr = (i == Settings.tab)
        if is_curr then
            love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
            rr(tx, ty, tab_w, 40, 6)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
            rr(tx, ty, tab_w, 40, 6)
            love.graphics.setColor(0.7, 0.7, 0.8)
        end
        love.graphics.setFont(Fonts.get(13))
        love.graphics.printf(title, tx, ty + 12, tab_w, "center")
    end

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.line(px + 8, py + 104, px + pw - 8, py + 104)

    local body_y = py + 112
    local body_h = ph - 144

    if Settings.tab == 1 then
        Settings.drawControlsTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 2 then
        Settings.drawShadersTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 3 then
        Settings.drawAudioTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 4 then
        Settings.drawDisplayTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 5 then
        Settings.drawGameplayTab(px, body_y, pw, body_h, theme)
    end

    love.graphics.setFont(Fonts.get(13))
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.printf("TAB/L/R: Switch Tab  |  UP/DOWN: Select  |  LEFT/RIGHT/ENTER: Change  |  ESC: Save & Close",
        px, py + ph - 26, pw, "center")
end

local function draw_row(i, sel_i, label, val, base_x, base_y, row_w, row_h, theme, opt_type, pct)
    local y = base_y + (i - 1) * (row_h + 6)
    local sel = (i == sel_i)
    if sel then
        local pulse = (math.sin(love.timer.getTime() * 7) + 1) * 0.5
        love.graphics.setColor(1.0, 0.82 + pulse * 0.1, 0.1, 0.95)
        rr(base_x + 8, y, row_w - 16, row_h, 8)
        love.graphics.setColor(1.0, 1.0, 0.5, 0.8 + pulse * 0.2)
        love.graphics.setLineWidth(2)
        rl(base_x + 8, y, row_w - 16, row_h, 8)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0)
    else
        love.graphics.setColor(0.08, 0.10, 0.18, 0.75)
        rr(base_x + 8, y, row_w - 16, row_h, 8)
        love.graphics.setColor(0.18, 0.22, 0.35, 0.35)
        rl(base_x + 8, y, row_w - 16, row_h, 8)
        love.graphics.setColor(0.9, 0.92, 0.98)
    end
    love.graphics.setFont(Fonts.get(13))
    love.graphics.print(label, base_x + 24, y + math.floor(row_h / 2) - 8)

    if opt_type == "slider" and pct then
        local sw = 90
        local sx = base_x + row_w - sw - 150
        local sy = y + math.floor(row_h / 2) - 3
        love.graphics.setColor(0.12, 0.16, 0.28, sel and 0.9 or 0.6)
        rr(sx, sy, sw, 6, 3)
        if sel then
            love.graphics.setColor(0.1, 0.1, 0.1, 1.0)
        else
            love.graphics.setColor(0.2, 0.75, 1.0, 0.9)
        end
        rr(sx, sy, math.floor(sw * math.max(0, math.min(1, pct))), 6, 3)
    end

    love.graphics.printf(tostring(val), base_x + 8, y + math.floor(row_h / 2) - 8, row_w - 32, "right")
end

function Settings.drawControlsTab(px, by, pw, bh, theme)
    local options = {
        { label = "UP Button Behavior", val = Settings.up_mode_labels[Settings.up_modes[Settings.up_idx]] },
        { label = "Move Left Key",      val = Input.get_key_for_action("MOVE_LEFT") },
        { label = "Move Right Key",     val = Input.get_key_for_action("MOVE_RIGHT") },
        { label = "Soft Drop Key",      val = Input.get_key_for_action("SOFT_DROP") },
        { label = "Hard Drop Key",      val = Input.get_key_for_action("HARD_DROP") },
        { label = "Rotate CW Key",      val = Input.get_key_for_action("ROTATE_CW") },
        { label = "Rotate CCW Key",     val = Input.get_key_for_action("ROTATE_CCW") },
        { label = "Hold Piece Key",     val = Input.get_key_for_action("HOLD") },
        { label = "VS CPU Difficulty",  val = Settings.cpu_diff_labels[Settings.cpu_difficulties[Settings.cpu_diff_idx]] or "Medium" },
    }
    local rh = math.floor((bh - 20) / #options - 6)
    for i, opt in ipairs(options) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end
end

function Settings.drawShadersTab(px, by, pw, bh, theme)
    local opts = Settings.get_shader_options()
    local visible_count = 6
    local rh = math.floor((bh - 35) / visible_count - 6)

    if Settings.selected > (Settings.shader_scroll_top + visible_count) then
        Settings.shader_scroll_top = Settings.selected - visible_count
    elseif Settings.selected <= Settings.shader_scroll_top then
        Settings.shader_scroll_top = Settings.selected - 1
    end
    if Settings.shader_scroll_top < 0 then Settings.shader_scroll_top = 0 end

    for row = 1, visible_count do
        local idx = Settings.shader_scroll_top + row
        if idx <= #opts then
            local opt = opts[idx]
            draw_row(row, Settings.selected - Settings.shader_scroll_top, opt.label, opt.val, px, by + 5, pw, rh, theme, opt.type, opt.pct)
        end
    end

    local desc_y = by + 5 + visible_count * (rh + 6) + 4
    local sel_opt = opts[Settings.selected]
    if sel_opt and sel_opt.desc then
        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(0.55, 0.70, 0.85, 0.85)
        love.graphics.printf("★ " .. sel_opt.desc, px + 20, desc_y, pw - 40, "left")
    end
end

function Settings.drawAudioTab(px, by, pw, bh, theme)
    local opts = {
        { label = "Master Volume", val = string.format("%.0f%%", (Audio.master_vol or 0.8) * 100) },
        { label = "SFX Volume",    val = string.format("%.0f%%", (Audio.sfx_vol or 1.0) * 100) },
        { label = "Music Volume",  val = string.format("%.0f%%", (Audio.music_vol or 0.5) * 100) },
    }
    local rh = math.floor((bh - 20) / 6 - 6)
    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end
end

function Settings.drawDisplayTab(px, by, pw, bh, theme)
    local res = constants.RESOLUTIONS
    local opts = {}
    for i, r in ipairs(res) do
        table.insert(opts, {
            label = r.label,
            val = (Settings.res_idx == i) and "● ACTIVE" or "○"
        })
    end

    local rh = math.floor((bh - 20) / 8 - 6)
    love.graphics.setFont(Fonts.get(12))
    love.graphics.setColor(0.5, 0.7, 1.0, 0.8)
    love.graphics.printf("Select a resolution then press ESC to apply", px, by, pw, "center")

    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 30, pw, rh, theme)
    end
end

function Settings.drawGameplayTab(px, by, pw, bh, theme)
    local rand_desc = {
        ["7-Bag"]    = "Standard modern Tetris — no droughts",
        ["Classic"]  = "Pure random — can repeat, can drought",
        ["Game Boy"] = "No immediate repeats (1-slot history)",
        ["8-Bag"]    = "7-Bag + 1 bonus random piece per cycle",
        ["TGM1"]     = "4-slot history, 4 rerolls — balanced",
        ["TGM2"]     = "TGM1 + S/Z drought avoidance",
        ["TGM3"]     = "35-roll, 6-slot history — most predictable",
    }
    local sdr_desc = {
        ["Slow"]    = "0.15s per row",
        ["Normal"]  = "0.05s per row (default)",
        ["Fast"]    = "0.018s per row",
        ["Instant"] = "Effectively instant drop",
    }
    local opts = {
        { label = "Next Queue Size",        val = tostring(Settings.gp_next_queue) .. " piece" .. (Settings.gp_next_queue > 1 and "s" or "") },
        { label = "Hold Piece (Shift)",     val = Settings.gp_hold and "ENABLED" or "DISABLED" },
        { label = "Randomizer",             val = Settings.gp_rand_names[Settings.gp_rand_idx] or "7-Bag" },
        { label = "Super Rotation System",  val = Settings.gp_srs and "ENABLED" or "DISABLED" },
        { label = "Soft Drop Speed",        val = Settings.gp_softdrop_labels[Settings.gp_softdrop_idx] or "Normal" },
        { label = "Ghost Piece",            val = Settings.gp_ghost and "ENABLED" or "DISABLED" },
    }

    local rh = math.floor((bh - 50) / #opts - 6)
    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end

    local desc_y = by + 10 + #opts * (rh + 6) + 8
    local desc
    if Settings.selected == 3 then
        desc = rand_desc[opts[3].val]
    elseif Settings.selected == 5 then
        desc = sdr_desc[opts[5].val]
    elseif Settings.selected == 1 then
        desc = "Number of upcoming pieces shown in the NEXT panel (1—3)"
    elseif Settings.selected == 2 then
        desc = "When DISABLED, the Shift/C hold key has no effect in-game"
    elseif Settings.selected == 4 then
        desc = Settings.gp_srs and "Wall-kicks ON — pieces can rotate in tight spaces"
                                 or "Wall-kicks OFF — classic rotation behaviour"
    elseif Settings.selected == 6 then
        desc = Settings.gp_ghost and "Shadow shows where the active piece will land"
                                   or "No ghost shadow — rely on pure judgement!"
    end
    if desc then
        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(0.55, 0.70, 0.85, 0.85)
        love.graphics.printf("★ " .. desc, px + 20, desc_y, pw - 40, "left")
    end
end

function Settings:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    local active_tabs = Settings.get_active_tabs()
    if Settings.tab > #active_tabs then Settings.tab = 1 end

    if key == "tab" or key == "l" or key == "r" then
        if key == "tab" or key == "r" then
            Settings.tab = (Settings.tab % #active_tabs) + 1
        else
            Settings.tab = Settings.tab - 1
            if Settings.tab < 1 then Settings.tab = #active_tabs end
        end
        Settings.selected = 1
        Settings.shader_scroll_top = 0
        Audio.play("move")
        return
    end

    local max_items = Settings.tab == 1 and 9
        or Settings.tab == 2 and #Settings.get_shader_options()
        or Settings.tab == 3 and 3
        or Settings.tab == 5 and 6
        or #constants.RESOLUTIONS

    if key == "up" then
        Settings.selected = Settings.selected - 1
        if Settings.selected < 1 then Settings.selected = max_items end
        Audio.play("move")
    elseif key == "down" then
        Settings.selected = Settings.selected + 1
        if Settings.selected > max_items then Settings.selected = 1 end
        Audio.play("move")
    elseif key == "return" or key == "space" or key == "right" or key == "left" then
        local dir = (key == "left") and -1 or 1
        Audio.play("rotate")

        if Settings.tab == 1 then
            if Settings.selected == 1 then
                Settings.up_idx = Settings.up_idx + dir
                if Settings.up_idx < 1 then Settings.up_idx = #Settings.up_modes end
                if Settings.up_idx > #Settings.up_modes then Settings.up_idx = 1 end
            elseif Settings.selected == 9 then
                Settings.cpu_diff_idx = Settings.cpu_diff_idx + dir
                if Settings.cpu_diff_idx < 1 then Settings.cpu_diff_idx = #Settings.cpu_difficulties end
                if Settings.cpu_diff_idx > #Settings.cpu_difficulties then Settings.cpu_diff_idx = 1 end
            end
        elseif Settings.tab == 2 then
            local shader_opts = Settings.get_shader_options()
            if shader_opts[Settings.selected] and shader_opts[Settings.selected].action then
                shader_opts[Settings.selected].action(dir)
            end
        elseif Settings.tab == 3 then
            if Settings.selected == 1 then
                Audio.setMasterVolume(math.max(0, math.min(1, (Audio.master_vol or 0.8) + dir * 0.1)))
            elseif Settings.selected == 2 then
                Audio.setSFXVolume(math.max(0, math.min(1, (Audio.sfx_vol or 1.0) + dir * 0.1)))
            elseif Settings.selected == 3 then
                Audio.setMusicVolume(math.max(0, math.min(1, (Audio.music_vol or 0.5) + dir * 0.1)))
            end
        elseif Settings.tab == 4 then
            Settings.res_idx = Settings.selected
        elseif Settings.tab == 5 then
            if Settings.selected == 1 then
                Settings.gp_next_queue = Settings.gp_next_queue + dir
                if Settings.gp_next_queue < 1 then Settings.gp_next_queue = 3 end
                if Settings.gp_next_queue > 3 then Settings.gp_next_queue = 1 end
            elseif Settings.selected == 2 then
                Settings.gp_hold = not Settings.gp_hold
            elseif Settings.selected == 3 then
                Settings.gp_rand_idx = Settings.gp_rand_idx + dir
                if Settings.gp_rand_idx < 1 then Settings.gp_rand_idx = #Settings.gp_rand_keys end
                if Settings.gp_rand_idx > #Settings.gp_rand_keys then Settings.gp_rand_idx = 1 end
            elseif Settings.selected == 4 then
                Settings.gp_srs = not Settings.gp_srs
            elseif Settings.selected == 5 then
                Settings.gp_softdrop_idx = Settings.gp_softdrop_idx + dir
                if Settings.gp_softdrop_idx < 1 then Settings.gp_softdrop_idx = #Settings.gp_softdrop_keys end
                if Settings.gp_softdrop_idx > #Settings.gp_softdrop_keys then Settings.gp_softdrop_idx = 1 end
            elseif Settings.selected == 6 then
                Settings.gp_ghost = not Settings.gp_ghost
            end
        end
    elseif key == "escape" then
        Settings.saveValues()
        state_mgr.pop()
    end
end

return Settings
