local bitser = require("lib.vendor.bitser")

local Save = {}

Save.path = "save_data.bin"
Save.run_path = "active_run.bin"
Save.data = {}

local default_data = {
    high_scores = {
        marathon = { score = 0, level = 0, lines = 0, date = "" },
        blitz    = { score = 0, pieces = 0, date = "" },
        sprint   = { score = 0, time = 0, date = "" },
        battle   = { wins = 0 },
    },
    sprint_bests = {},
    stats = {
        total_games    = 0,
        total_score    = 0,
        total_playtime = 0,
        total_lines    = 0,
        total_pieces   = 0,
        singles        = 0,
        doubles        = 0,
        triples        = 0,
        tetrises       = 0,
        t_spins        = 0,
        all_clears     = 0,
        holds_used     = 0,
        hard_drops     = 0,

        marathon = {
            top_score    = 0,
            max_level    = 1,
            max_lines    = 0,
            games_played = 0,
        },
        sprint = {
            best_time    = nil,
            best_pps     = 0,
            games_played = 0,
            completions  = 0,
        },
        blitz = {
            top_score    = 0,
            max_pieces   = 0,
            games_played = 0,
        },
        battle = {
            wins         = 0,
            losses       = 0,
            win_streak   = 0,
            best_streak  = 0,
            garbage_sent = 0,
            garbage_recv = 0,
            games_played = 0,
        },
        zen = {
            total_time   = 0,
            total_lines  = 0,
            games_played = 0,
        },
    },
    settings = {
        master_volume = 0.8,
        sfx_volume = 1.0,
        music_volume = 0.5,
        theme = "retro",
        up_mode = "rotate_cw",
        shader_enabled = true,
        crt_enabled = true,
        curvature = 3.5,
        chromatic_enabled = true,
        chromatic_idx = 3,
        pixel_matrix_enabled = false,
        pixel_size_idx = 4,
        matrix_grid = 0.5,
        motion_blur_enabled = false,
        motion_blur_strength = 0.75,
        noise_enabled = false,
        noise_intensity = 0.25,
        phosphor_enabled = false,
        phosphor_decay = 0.85,
        jitter_enabled = false,
        jitter_idx = 3,
        vhs_enabled = false,
        vhs_intensity = 0.4,
        scanlines_enabled = true,
        scanline_intensity = 0.3,
        bloom_enabled = true,
        bloom_strength = 0.5,
        palette_enabled = false,
        palette_mode = 0,
        ntsc_enabled = false,
        resolution_idx = 3,
        cpu_difficulty = "medium",
    },
    controls = "",
    gameplay_opts = {
        next_queue_size  = 3,
        hold_enabled     = true,
        randomizer       = "7bag",
        srs_enabled      = true,
        soft_drop_speed  = "normal",
        ghost_enabled    = true,
    },
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

    -- Audio
    if s.master_volume ~= nil then Audio.setMasterVolume(s.master_volume) end
    if s.sfx_volume ~= nil    then Audio.setSFXVolume(s.sfx_volume)    end
    if s.music_volume ~= nil  then Audio.setMusicVolume(s.music_volume)  end

    -- Theme
    if s.theme then Themes.set(s.theme) end

    -- Input up mode
    Input.apply_up_button_mode(s.up_mode or "rotate_cw")

    -- Shaders
    if s.shader_enabled ~= nil         then ShaderManager.enabled = (s.shader_enabled == true) end
    if s.crt_enabled ~= nil            then ShaderManager.crt_enabled = (s.crt_enabled == true) end
    if s.curvature ~= nil              then ShaderManager.curvature = s.curvature end

    if s.chromatic_enabled ~= nil      then ShaderManager.chromatic_enabled = (s.chromatic_enabled == true) end
    if s.chromatic_idx ~= nil          then
        ShaderManager.chromatic_idx = s.chromatic_idx
        if ShaderManager.chromatic_values and ShaderManager.chromatic_values[s.chromatic_idx] then
            ShaderManager.chromatic_strength = ShaderManager.chromatic_values[s.chromatic_idx] / 1000.0
        end
    end

    if s.pixel_matrix_enabled ~= nil  then ShaderManager.pixel_matrix_enabled = (s.pixel_matrix_enabled == true) end
    if s.pixel_size_idx ~= nil         then
        ShaderManager.pixel_size_idx = s.pixel_size_idx
        if ShaderManager.pixel_size_values and ShaderManager.pixel_size_values[s.pixel_size_idx] then
            ShaderManager.pixel_size = ShaderManager.pixel_size_values[s.pixel_size_idx]
        end
    end
    if s.matrix_grid ~= nil            then ShaderManager.matrix_grid = s.matrix_grid end

    if s.motion_blur_enabled ~= nil    then ShaderManager.motion_blur_enabled = (s.motion_blur_enabled == true) end
    if s.motion_blur_strength ~= nil   then ShaderManager.motion_blur_strength = s.motion_blur_strength end

    if s.noise_enabled ~= nil          then ShaderManager.noise_enabled = (s.noise_enabled == true) end
    if s.noise_intensity ~= nil        then ShaderManager.noise_intensity = s.noise_intensity end

    if s.phosphor_enabled ~= nil       then ShaderManager.phosphor_enabled = (s.phosphor_enabled == true) end
    if s.phosphor_decay ~= nil         then ShaderManager.phosphor_decay = s.phosphor_decay end

    if s.jitter_enabled ~= nil         then ShaderManager.jitter_enabled = (s.jitter_enabled == true) end
    if s.jitter_idx ~= nil             then
        ShaderManager.jitter_idx = s.jitter_idx
        if ShaderManager.jitter_values and ShaderManager.jitter_values[s.jitter_idx] then
            ShaderManager.jitter_strength = ShaderManager.jitter_values[s.jitter_idx]
        end
    end

    if s.vhs_enabled ~= nil            then ShaderManager.vhs_enabled = (s.vhs_enabled == true) end
    if s.vhs_intensity ~= nil          then ShaderManager.vhs_intensity = s.vhs_intensity end

    if s.scanlines_enabled ~= nil      then ShaderManager.scanlines_enabled = (s.scanlines_enabled == true) end
    if s.scanline_intensity ~= nil     then ShaderManager.scanline_intensity = s.scanline_intensity end

    if s.bloom_enabled ~= nil          then ShaderManager.bloom_enabled = (s.bloom_enabled == true) end
    if s.bloom_strength ~= nil         then ShaderManager.bloom_strength = s.bloom_strength end

    if s.palette_enabled ~= nil        then ShaderManager.palette_enabled = (s.palette_enabled == true) end
    if s.palette_mode ~= nil           then ShaderManager.palette_mode = s.palette_mode end

    if s.ntsc_enabled ~= nil           then ShaderManager.ntsc_enabled = (s.ntsc_enabled == true) end

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
    if type(settings) == "table" then
        if not Save.data.settings then Save.data.settings = {} end
        for k, v in pairs(settings) do
            Save.data.settings[k] = v
        end
    end
    Save.save()
end

function Save.updateControls(bindings_str)
    Save.set("controls", bindings_str)
    Save.save()
end

-- ─── Stat Recording Helper Functions ─────────────────────────────────────────

function Save.record_line_clear(cleared)
    if not cleared or cleared <= 0 then return end
    local s = Save.data.stats or {}
    s.total_lines = (s.total_lines or 0) + cleared

    if cleared == 1 then s.singles = (s.singles or 0) + 1
    elseif cleared == 2 then s.doubles = (s.doubles or 0) + 1
    elseif cleared == 3 then s.triples = (s.triples or 0) + 1
    elseif cleared >= 4 then s.tetrises = (s.tetrises or 0) + 1
    end
    Save.data.stats = s
    Save.save()
end

function Save.record_piece_place(is_hard_drop, is_hold)
    local s = Save.data.stats or {}
    s.total_pieces = (s.total_pieces or 0) + 1
    if is_hard_drop then s.hard_drops = (s.hard_drops or 0) + 1 end
    if is_hold then s.holds_used = (s.holds_used or 0) + 1 end
    Save.data.stats = s
end

function Save.record_game_end(mode_key, score, lines, level, time_spent, extra)
    local s = Save.data.stats or {}
    s.total_games = (s.total_games or 0) + 1
    s.total_score = (s.total_score or 0) + (score or 0)
    s.total_playtime = (s.total_playtime or 0) + (time_spent or 0)

    mode_key = (mode_key or "marathon"):lower()
    if mode_key == "marathon" then
        local m = s.marathon or {}
        m.games_played = (m.games_played or 0) + 1
        m.top_score = math.max(m.top_score or 0, score or 0)
        m.max_level = math.max(m.max_level or 1, level or 1)
        m.max_lines = math.max(m.max_lines or 0, lines or 0)
        s.marathon = m
        Save.updateHighScore("marathon", { score = score, level = level, lines = lines, date = os.date("%Y-%m-%d") })

    elseif mode_key == "sprint" then
        local sp = s.sprint or {}
        sp.games_played = (sp.games_played or 0) + 1
        local pps = extra and extra.pps or 0
        sp.best_pps = math.max(sp.best_pps or 0, pps)
        if extra and extra.victory then
            sp.completions = (sp.completions or 0) + 1
            local cur_best = sp.best_time
            if not cur_best or time_spent < cur_best then
                sp.best_time = time_spent
            end
            Save.updateSprintBest(lines or 40, time_spent)
        end
        s.sprint = sp

    elseif mode_key == "blitz" then
        local b = s.blitz or {}
        b.games_played = (b.games_played or 0) + 1
        b.top_score = math.max(b.top_score or 0, score or 0)
        b.max_pieces = math.max(b.max_pieces or 0, extra and extra.pieces or 0)
        s.blitz = b
        Save.updateHighScore("blitz", { score = score, pieces = extra and extra.pieces or 0, date = os.date("%Y-%m-%d") })

    elseif mode_key == "battle" or mode_key == "battle_ultimate" then
        local bt = s.battle or {}
        bt.games_played = (bt.games_played or 0) + 1
        if extra and extra.won then
            bt.wins = (bt.wins or 0) + 1
            bt.win_streak = (bt.win_streak or 0) + 1
            bt.best_streak = math.max(bt.best_streak or 0, bt.win_streak)
        else
            bt.losses = (bt.losses or 0) + 1
            bt.win_streak = 0
        end
        bt.garbage_sent = (bt.garbage_sent or 0) + (extra and extra.sent or 0)
        bt.garbage_recv = (bt.garbage_recv or 0) + (extra and extra.recv or 0)
        s.battle = bt
        local rec = Save.get("high_scores", "battle") or { wins = 0 }
        rec.wins = bt.wins
        Save.set("high_scores", "battle", rec)

    elseif mode_key == "zen" then
        local z = s.zen or {}
        z.games_played = (z.games_played or 0) + 1
        z.total_time = (z.total_time or 0) + (time_spent or 0)
        z.total_lines = (z.total_lines or 0) + (lines or 0)
        s.zen = z
    end

    if extra then
        if extra.pps and extra.pps > 0 then
            s.best_pps = math.max(s.best_pps or 0, extra.pps)
        end
        if extra.kpp and extra.kpp > 0 and (extra.pieces or 0) >= 5 then
            if not s.best_kpp or extra.kpp < s.best_kpp then
                s.best_kpp = extra.kpp
            end
        end
        if extra.apm and extra.apm > 0 then
            s.best_apm = math.max(s.best_apm or 0, extra.apm)
        end
    end

    Save.data.stats = s
    Save.save()
end

local BELT_TIERS = {
    { rank = "White Belt",   lines_req = 0,    color = {0.85, 0.88, 0.92} },
    { rank = "Yellow Belt",  lines_req = 50,   color = {1.00, 0.82, 0.15} },
    { rank = "Orange Belt",  lines_req = 150,  color = {1.00, 0.52, 0.10} },
    { rank = "Green Belt",   lines_req = 300,  color = {0.15, 0.85, 0.40} },
    { rank = "Blue Belt",    lines_req = 500,  color = {0.15, 0.55, 1.00} },
    { rank = "Purple Belt",  lines_req = 800,  color = {0.75, 0.25, 0.95} },
    { rank = "Brown Belt",   lines_req = 1200, color = {0.60, 0.38, 0.20} },
    { rank = "Red Belt",     lines_req = 2000, color = {0.90, 0.18, 0.20} },
    { rank = "Black Belt",   lines_req = 3500, color = {0.15, 0.15, 0.20} },
}

function Save.get_belt_info()
    local stats = Save.data.stats or {}
    local total_lines = stats.total_lines or 0

    local current_tier = BELT_TIERS[1]
    local next_tier = BELT_TIERS[2]

    for i = #BELT_TIERS, 1, -1 do
        if total_lines >= BELT_TIERS[i].lines_req then
            current_tier = BELT_TIERS[i]
            next_tier = BELT_TIERS[i + 1] or BELT_TIERS[i]
            break
        end
    end

    local pct = 1.0
    if next_tier and next_tier ~= current_tier then
        local span = next_tier.lines_req - current_tier.lines_req
        local prog = total_lines - current_tier.lines_req
        pct = math.min(1.0, math.max(0.0, prog / span))
    end

    return {
        rank              = current_tier.rank,
        color             = current_tier.color,
        next_rank         = next_tier and next_tier.rank or "MAX RANK",
        lines             = total_lines,
        current_req       = current_tier.lines_req,
        next_req          = next_tier and next_tier.lines_req or current_tier.lines_req,
        pct               = pct,
    }
end

return Save
