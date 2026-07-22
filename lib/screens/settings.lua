local Themes = require("lib.themes")
local Audio = require("lib.audio")
local Input = require("lib.input")
local Save = require("lib.save")
local ShaderManager = require("lib.shaders.manager")
local constants = require("lib.constants")
local shack = require("lib.vendor.shack")

local Settings = {}

Settings.tab = 1
Settings.selected = 1
Settings.tabs = {"CONTROLS", "RETRO SHADERS", "AUDIO & THEMES", "DISPLAY"}

Settings.up_modes = {"rotate_cw", "hard_drop", "rotate_ccw", "off"}
Settings.up_mode_labels = {
    rotate_cw = "Rotate CW",
    hard_drop = "Hard Drop",
    rotate_ccw = "Rotate CCW",
    off = "Unmapped / Off"
}
Settings.up_idx = 1

Settings.palettes = {"GameBoy Green", "Cyberpunk Neon", "NES Classic", "CGA Mode 1", "Monochromatic", "Vaporwave"}

Settings.res_idx = 3  -- working copy for display

function Settings:enter(previous)
    Settings.tab = 1
    Settings.selected = 1
    Settings.loadValues()
end

function Settings.loadValues()
    local saved_up = Save.get("settings", "up_mode") or "rotate_cw"
    for i, m in ipairs(Settings.up_modes) do
        if m == saved_up then Settings.up_idx = i; break end
    end

    ShaderManager.enabled           = Save.get("settings", "shader_enabled") ~= false
    ShaderManager.palette_enabled   = Save.get("settings", "palette_enabled") ~= false
    ShaderManager.palette_mode      = Save.get("settings", "palette_mode") or 0
    ShaderManager.scanlines_enabled = Save.get("settings", "scanlines_enabled") ~= false
    ShaderManager.crt_enabled       = Save.get("settings", "crt_enabled") ~= false
    ShaderManager.bloom_enabled     = Save.get("settings", "bloom_enabled") ~= false
    ShaderManager.ntsc_enabled      = Save.get("settings", "ntsc_enabled") == true

    Settings.res_idx = Save.get("settings", "resolution_idx") or 3
end

function Settings.saveValues()
    local up_mode = Settings.up_modes[Settings.up_idx]
    Input.apply_up_button_mode(up_mode)

    -- Apply resolution if changed
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
        theme = Themes.current_name or "retro",
        shader_enabled = ShaderManager.enabled,
        palette_enabled = ShaderManager.palette_enabled,
        palette_mode = ShaderManager.palette_mode,
        scanlines_enabled = ShaderManager.scanlines_enabled,
        crt_enabled = ShaderManager.crt_enabled,
        bloom_enabled = ShaderManager.bloom_enabled,
        ntsc_enabled = ShaderManager.ntsc_enabled,
        resolution_idx = Settings.res_idx,
    })
end

function Settings:update(dt)
end

function Settings:draw()
    local theme = Themes.get()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    local px = math.floor(W * 0.05)
    local py = math.floor(H * 0.04)
    local pw = W - px * 2
    local ph = H - py * 2

    -- Dark Modal Overlay
    love.graphics.setColor(0.02, 0.02, 0.05, 0.95)
    love.graphics.rectangle("fill", px, py, pw, ph, 16, 16)
    love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 16, 16)
    love.graphics.setLineWidth(1)

    -- Header
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS & OPTIONS", px, py + 14, pw, "center")

    -- Tab Headers
    local tab_w = math.floor(pw / #Settings.tabs) - 8
    for i, title in ipairs(Settings.tabs) do
        local tx = px + 8 + (i - 1) * (tab_w + 8)
        local ty = py + 52
        local is_curr = (i == Settings.tab)
        if is_curr then
            love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 0.9)
            love.graphics.rectangle("fill", tx, ty, tab_w, 32, 6, 6)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.15, 0.15, 0.25, 0.8)
            love.graphics.rectangle("fill", tx, ty, tab_w, 32, 6, 6)
            love.graphics.setColor(0.7, 0.7, 0.8)
        end
        love.graphics.setFont(love.graphics.newFont(11))
        love.graphics.printf(title, tx, ty + 10, tab_w, "center")
    end

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.line(px + 8, py + 92, px + pw - 8, py + 92)

    local body_y = py + 100
    local body_h = ph - 120

    -- Tab Body
    if Settings.tab == 1 then
        Settings.drawControlsTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 2 then
        Settings.drawShadersTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 3 then
        Settings.drawAudioTab(px, body_y, pw, body_h, theme)
    elseif Settings.tab == 4 then
        Settings.drawDisplayTab(px, body_y, pw, body_h, theme)
    end

    -- Footer instructions
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.printf("TAB/L/R: Switch Tab  |  UP/DOWN: Select  |  LEFT/RIGHT/ENTER: Change  |  ESC: Save & Close",
        px, py + ph - 22, pw, "center")
end

local function draw_row(i, sel_i, label, val, base_x, base_y, row_w, row_h, theme)
    local y = base_y + (i - 1) * (row_h + 6)
    local sel = (i == sel_i)
    if sel then
        love.graphics.setColor(1, 0.85, 0.1, 0.95)
        love.graphics.rectangle("fill", base_x + 8, y, row_w - 16, row_h, 8, 8)
        love.graphics.setColor(0, 0, 0)
    else
        love.graphics.setColor(0.1, 0.1, 0.18, 0.7)
        love.graphics.rectangle("fill", base_x + 8, y, row_w - 16, row_h, 8, 8)
        love.graphics.setColor(0.9, 0.9, 0.9)
    end
    love.graphics.setFont(love.graphics.newFont(13))
    love.graphics.print(label, base_x + 22, y + math.floor(row_h / 2) - 7)
    love.graphics.printf(tostring(val), base_x + 8, y + math.floor(row_h / 2) - 7, row_w - 30, "right")
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
    }
    local rh = math.floor((bh - 20) / #options - 6)
    for i, opt in ipairs(options) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end
end

function Settings.drawShadersTab(px, by, pw, bh, theme)
    local opts = {
        { label = "Master Shaders",                val = ShaderManager.enabled and "ENABLED" or "DISABLED" },
        { label = "Palette Limiting & Dither",     val = ShaderManager.palette_enabled and "ENABLED" or "DISABLED" },
        { label = "Active Palette Preset",         val = Settings.palettes[ShaderManager.palette_mode + 1] or "GameBoy" },
        { label = "CRT Horizontal Scanlines",      val = ShaderManager.scanlines_enabled and "ENABLED" or "DISABLED" },
        { label = "CRT Geometry & Distortion",     val = ShaderManager.crt_enabled and "ENABLED" or "DISABLED" },
        { label = "Bloom & Glow",                  val = ShaderManager.bloom_enabled and "ENABLED" or "DISABLED" },
        { label = "NTSC Composite Artifacts",      val = ShaderManager.ntsc_enabled and "ENABLED" or "DISABLED" },
    }
    local rh = math.floor((bh - 20) / #opts - 6)
    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end
end

function Settings.drawAudioTab(px, by, pw, bh, theme)
    local opts = {
        { label = "Master Volume", val = string.format("%.0f%%", (Audio.master_vol or 0.8) * 100) },
        { label = "SFX Volume",    val = string.format("%.0f%%", (Audio.sfx_vol or 1.0) * 100) },
        { label = "Music Volume",  val = string.format("%.0f%%", (Audio.music_vol or 0.5) * 100) },
        { label = "Visual Theme",  val = Themes.current_name or "retro" },
    }
    local rh = math.floor((bh - 20) / 8 - 6)
    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 10, pw, rh, theme)
    end
end

function Settings.drawDisplayTab(px, by, pw, bh, theme)
    local res = constants.RESOLUTIONS
    local opts = {}
    for _, r in ipairs(res) do
        table.insert(opts, { label = "Resolution: " .. r.label, val = (Settings.res_idx == _ and "SELECTED" or "") })
    end
    -- Rebuild with correct check
    opts = {}
    for i, r in ipairs(res) do
        table.insert(opts, {
            label = r.label,
            val = (Settings.res_idx == i) and "● ACTIVE" or "○"
        })
    end

    local rh = math.floor((bh - 20) / 8 - 6)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.5, 0.7, 1.0, 0.8)
    love.graphics.printf("Select a resolution then press ESC to apply", px, by, pw, "center")

    for i, opt in ipairs(opts) do
        draw_row(i, Settings.selected, opt.label, opt.val, px, by + 30, pw, rh, theme)
    end
end

function Settings:keypressed(key)
    local state_mgr = require("lib.state_mgr")

    if key == "tab" or key == "l" or key == "r" then
        if key == "tab" or key == "r" then
            Settings.tab = (Settings.tab % #Settings.tabs) + 1
        else
            Settings.tab = Settings.tab - 1
            if Settings.tab < 1 then Settings.tab = #Settings.tabs end
        end
        Settings.selected = 1
        Audio.play("move")
        return
    end

    local max_items = Settings.tab == 1 and 8
        or Settings.tab == 2 and 7
        or Settings.tab == 3 and 4
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
            end
        elseif Settings.tab == 2 then
            if Settings.selected == 1 then ShaderManager.enabled = not ShaderManager.enabled
            elseif Settings.selected == 2 then ShaderManager.palette_enabled = not ShaderManager.palette_enabled
            elseif Settings.selected == 3 then
                ShaderManager.palette_mode = (ShaderManager.palette_mode + dir) % #Settings.palettes
            elseif Settings.selected == 4 then ShaderManager.scanlines_enabled = not ShaderManager.scanlines_enabled
            elseif Settings.selected == 5 then ShaderManager.crt_enabled = not ShaderManager.crt_enabled
            elseif Settings.selected == 6 then ShaderManager.bloom_enabled = not ShaderManager.bloom_enabled
            elseif Settings.selected == 7 then ShaderManager.ntsc_enabled = not ShaderManager.ntsc_enabled
            end
        elseif Settings.tab == 3 then
            if Settings.selected == 1 then
                Audio.setMasterVolume(math.max(0, math.min(1, (Audio.master_vol or 0.8) + dir * 0.1)))
            elseif Settings.selected == 2 then
                Audio.setSFXVolume(math.max(0, math.min(1, (Audio.sfx_vol or 1.0) + dir * 0.1)))
            elseif Settings.selected == 3 then
                Audio.setMusicVolume(math.max(0, math.min(1, (Audio.music_vol or 0.5) + dir * 0.1)))
            elseif Settings.selected == 4 then
                local cur = 1
                for idx, name in ipairs(Themes.order) do if name == Themes.current_name then cur = idx end end
                cur = cur + dir
                if cur < 1 then cur = #Themes.order end
                if cur > #Themes.order then cur = 1 end
                Themes.set(Themes.order[cur])
            end
        elseif Settings.tab == 4 then
            -- Select resolution
            Settings.res_idx = Settings.selected
        end
    elseif key == "escape" then
        Settings.saveValues()
        state_mgr.pop()
    end
end

return Settings
