local bitser = require("lib.vendor.bitser")

local Save = {}

Save.path = "save_data.bin"
Save.run_path = "active_run.bin"
Save.data = {}

local default_data = {
    high_scores = {
        marathon = { score = 0, level = 0, lines = 0, date = "" },
        blitz = { score = 0, pieces = 0, date = "" },
        sprint = { score = 0, time = 0, date = "" },
    },
    sprint_bests = {},
    settings = {
        master_volume = 0.8,
        sfx_volume = 1.0,
        music_volume = 0.5,
        theme = "retro",
        up_mode = "rotate_cw",
        shader_enabled = false,  -- shaders off by default for performance
        palette_enabled = true,
        palette_mode = 0,
        scanlines_enabled = true,
        crt_enabled = true,
        ntsc_enabled = false,
        resolution_idx = 3,  -- 1280x720
    },
    controls = "",
}

function Save.load()
    local info = love.filesystem.getInfo(Save.path)
    if info then
        local contents, _ = love.filesystem.read(Save.path)
        if contents then
            local ok, data = pcall(bitser.loads, contents)
            if ok and type(data) == "table" then
                Save.data = data
                Save.defaults()
                return
            end
        end
    end
    Save.data = {}
    Save.defaults()
end

function Save.defaults()
    for k, v in pairs(default_data) do
        if Save.data[k] == nil then
            Save.data[k] = Save.deep_copy(v)
        elseif type(v) == "table" then
            for k2, v2 in pairs(v) do
                if Save.data[k][k2] == nil then
                    Save.data[k][k2] = v2
                end
            end
        end
    end
end

function Save.deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Save.deep_copy(v)
    end
    return copy
end

function Save.save()
    local serialized = bitser.dumps(Save.data)
    love.filesystem.write(Save.path, serialized)
end

-- Apply all saved settings to live subsystems (fixes settings vanishing on restart)
function Save.apply_all_settings()
    local Audio = require("lib.audio")
    local Themes = require("lib.themes")
    local Input = require("lib.input")
    local ShaderManager = require("lib.shaders.manager")
    local shack = require("lib.vendor.shack")
    local constants = require("lib.constants")

    local s = Save.data.settings or {}

    -- Audio (save stores master_volume, audio module uses setMasterVolume API)
    if s.master_volume ~= nil then Audio.setMasterVolume(s.master_volume) end
    if s.sfx_volume ~= nil    then Audio.setSFXVolume(s.sfx_volume)    end
    if s.music_volume ~= nil  then Audio.setMusicVolume(s.music_volume)  end

    -- Theme
    if s.theme then Themes.set(s.theme) end

    -- Input up mode
    Input.apply_up_button_mode(s.up_mode or "rotate_cw")

    -- Shaders
    ShaderManager.enabled         = s.shader_enabled ~= false
    ShaderManager.palette_enabled = s.palette_enabled ~= false
    ShaderManager.palette_mode    = s.palette_mode or 0
    ShaderManager.scanlines_enabled = s.scanlines_enabled ~= false
    ShaderManager.crt_enabled     = s.crt_enabled ~= false
    ShaderManager.ntsc_enabled    = s.ntsc_enabled == true

    -- Resolution
    local res_idx = s.resolution_idx or 3
    local resolutions = constants.RESOLUTIONS
    if resolutions[res_idx] then
        local r = resolutions[res_idx]
        love.window.setMode(r.w, r.h)
        constants.RESOLUTION_IDX = res_idx
        ShaderManager.init()
        shack:setDimensions(r.w, r.h)
    end
    constants.recompute_layout()
end

function Save.saveActiveRun(run_state)
    local serialized = bitser.dumps(run_state)
    love.filesystem.write(Save.run_path, serialized)
end

function Save.loadActiveRun()
    local info = love.filesystem.getInfo(Save.run_path)
    if info then
        local contents = love.filesystem.read(Save.run_path)
        if contents then
            local ok, run_state = pcall(bitser.loads, contents)
            if ok and type(run_state) == "table" then
                return run_state
            end
        end
    end
    return nil
end

function Save.clearActiveRun()
    if love.filesystem.getInfo(Save.run_path) then
        love.filesystem.remove(Save.run_path)
    end
end

function Save.get(...)
    local keys = {...}
    local val = Save.data
    for _, k in ipairs(keys) do
        if type(val) ~= "table" then return nil end
        val = val[k]
    end
    return val
end

function Save.set(...)
    local keys = {...}
    local val = table.remove(keys)
    local t = Save.data
    for i = 1, #keys - 1 do
        if type(t[keys[i]]) ~= "table" then
            t[keys[i]] = {}
        end
        t = t[keys[i]]
    end
    t[keys[#keys]] = val
end

function Save.updateHighScore(mode, score_data)
    local current = Save.get("high_scores", mode)
    if not current or score_data.score > (current.score or 0) then
        Save.set("high_scores", mode, score_data)
        Save.save()
        return true
    end
    return false
end

function Save.updateSprintBest(lines, time)
    local current = Save.get("sprint_bests", lines)
    if not current or time < (current.time or math.huge) then
        Save.set("sprint_bests", lines, {time = time, date = os.date("%Y-%m-%d")})
        Save.save()
        return true
    end
    return false
end

function Save.updateSettings(settings)
    Save.set("settings", settings)
    Save.save()
end

function Save.updateControls(bindings_str)
    Save.set("controls", bindings_str)
    Save.save()
end

return Save
