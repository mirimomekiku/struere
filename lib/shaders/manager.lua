-- Shader Manager for TetriX
local ShaderManager = {}

ShaderManager.enabled = true

-- CRT distortion width bounded between 3.0 and 5.5
ShaderManager.crt_enabled = true
ShaderManager.curvature = 3.5

-- Chromatic shift offset discrete values: 0.5 / 0.75 / 1.0 / 1.25 / 1.5 / 2.0 / 2.25
ShaderManager.chromatic_enabled = true
ShaderManager.chromatic_values = { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.25 }
ShaderManager.chromatic_idx = 3
ShaderManager.chromatic_strength = 0.001 -- (chromatic_values[3] / 1000)

ShaderManager.scanlines_enabled = true
ShaderManager.scanline_count = 240.0
ShaderManager.scanline_intensity = 0.3

-- Pixel matrix discrete cell scales: 1.25 / 1.5 / 1.75 / 2.0 / 2.25 / 2.5
ShaderManager.pixel_matrix_enabled = false
ShaderManager.pixel_size_values = { 1.25, 1.5, 1.75, 2.0, 2.25, 2.5 }
ShaderManager.pixel_size_idx = 4
ShaderManager.pixel_size = 2.0
ShaderManager.matrix_grid = 0.5

ShaderManager.motion_blur_enabled = false
ShaderManager.motion_blur_strength = 0.75

-- Grain noise intensity bounded between 10% (0.10) and 60% (0.60)
ShaderManager.noise_enabled = false
ShaderManager.noise_intensity = 0.25

ShaderManager.phosphor_enabled = false
ShaderManager.phosphor_decay = 0.85

-- Horizontal jitter amplitude discrete values: 5% / 7.5% / 10% / 15% / 20%
ShaderManager.jitter_enabled = false
ShaderManager.jitter_values = { 0.05, 0.075, 0.10, 0.15, 0.20 }
ShaderManager.jitter_idx = 3
ShaderManager.jitter_strength = 0.10

ShaderManager.vhs_enabled = false
ShaderManager.vhs_intensity = 0.4

ShaderManager.bloom_enabled = true
ShaderManager.bloom_strength = 0.5

ShaderManager.palette_enabled = false
ShaderManager.palette_mode = 0
ShaderManager.dither_strength = 0.4

ShaderManager.ntsc_enabled = false
ShaderManager.artifact_strength = 1.0

ShaderManager.time = 0

function ShaderManager.init()
    local function load_s(path)
        local ok, s = pcall(love.graphics.newShader, path)
        return ok and s or nil
    end

    ShaderManager.shader_palette = load_s("lib/shaders/palette.glsl")
    ShaderManager.shader_scanlines = load_s("lib/shaders/scanlines.glsl")
    ShaderManager.shader_crt = load_s("lib/shaders/crt.glsl")
    ShaderManager.shader_chromatic = load_s("lib/shaders/chromatic.glsl")
    ShaderManager.shader_pixel_matrix = load_s("lib/shaders/pixel_matrix.glsl")
    ShaderManager.shader_grain_jitter = load_s("lib/shaders/grain_jitter.glsl")
    ShaderManager.shader_vhs = load_s("lib/shaders/vhs.glsl")
    ShaderManager.shader_bloom = load_s("lib/shaders/bloom.glsl")
    ShaderManager.shader_ntsc = load_s("lib/shaders/ntsc.glsl")

    local w, h = love.graphics.getDimensions()
    ShaderManager.canvas_raw = love.graphics.newCanvas(w, h)
    ShaderManager.canvas_proc = love.graphics.newCanvas(w, h)
    ShaderManager.canvas_persistence = love.graphics.newCanvas(w, h)
end

function ShaderManager.update(dt)
    ShaderManager.time = ShaderManager.time + dt
end

function ShaderManager.start_capture()
    if not ShaderManager.enabled then return end
    love.graphics.setCanvas(ShaderManager.canvas_raw)
    love.graphics.clear()
end

function ShaderManager.end_capture_and_draw()
    if not ShaderManager.enabled then return end
    love.graphics.setCanvas()

    local W, H = love.graphics.getDimensions()
    local current_src = ShaderManager.canvas_raw
    local current_dst = ShaderManager.canvas_proc

    local function swap()
        local tmp = current_src
        current_src = current_dst
        current_dst = tmp
    end

    -- 1. Motion Blur / Phosphor Decay Trail Canvas Pass
    if (ShaderManager.motion_blur_enabled or ShaderManager.phosphor_enabled) and ShaderManager.canvas_persistence then
        love.graphics.setCanvas(ShaderManager.canvas_persistence)
        local decay = math.max(
            ShaderManager.motion_blur_enabled and ShaderManager.motion_blur_strength or 0,
            ShaderManager.phosphor_enabled and ShaderManager.phosphor_decay or 0
        )
        love.graphics.setColor(1, 1, 1, decay)
        love.graphics.draw(current_src, 0, 0)

        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(ShaderManager.canvas_persistence, 0, 0)
        swap()
    end

    -- 2. Pixel Matrix Pass
    if ShaderManager.pixel_matrix_enabled and ShaderManager.shader_pixel_matrix then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_pixel_matrix:send("screen_size", {W, H})
        ShaderManager.shader_pixel_matrix:send("pixel_size", ShaderManager.pixel_size)
        ShaderManager.shader_pixel_matrix:send("matrix_grid", ShaderManager.matrix_grid)
        love.graphics.setShader(ShaderManager.shader_pixel_matrix)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 3. VHS Pass
    if ShaderManager.vhs_enabled and ShaderManager.shader_vhs then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_vhs:send("time", ShaderManager.time)
        ShaderManager.shader_vhs:send("vhs_intensity", ShaderManager.vhs_intensity)
        love.graphics.setShader(ShaderManager.shader_vhs)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 4. Grain & Horizontal Jitter Pass
    if (ShaderManager.noise_enabled or ShaderManager.jitter_enabled) and ShaderManager.shader_grain_jitter then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_grain_jitter:send("time", ShaderManager.time)
        ShaderManager.shader_grain_jitter:send("noise_intensity", ShaderManager.noise_enabled and ShaderManager.noise_intensity or 0.0)
        ShaderManager.shader_grain_jitter:send("jitter_strength", ShaderManager.jitter_enabled and ShaderManager.jitter_strength or 0.0)
        love.graphics.setShader(ShaderManager.shader_grain_jitter)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 5. Palette Pass
    if ShaderManager.palette_enabled and ShaderManager.shader_palette then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_palette:send("palette_mode", ShaderManager.palette_mode)
        ShaderManager.shader_palette:send("dither_strength", ShaderManager.dither_strength)
        love.graphics.setShader(ShaderManager.shader_palette)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 6. NTSC Pass
    if ShaderManager.ntsc_enabled and ShaderManager.shader_ntsc then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_ntsc:send("time", ShaderManager.time)
        ShaderManager.shader_ntsc:send("artifact_strength", ShaderManager.artifact_strength)
        love.graphics.setShader(ShaderManager.shader_ntsc)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 7. Scanlines Pass
    if ShaderManager.scanlines_enabled and ShaderManager.shader_scanlines then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_scanlines:send("scanline_count", ShaderManager.scanline_count)
        ShaderManager.shader_scanlines:send("scanline_intensity", ShaderManager.scanline_intensity)
        love.graphics.setShader(ShaderManager.shader_scanlines)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 8. Bloom Pass
    if ShaderManager.bloom_enabled and ShaderManager.shader_bloom then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_bloom:send("bloom_strength", ShaderManager.bloom_strength)
        love.graphics.setShader(ShaderManager.shader_bloom)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 9. Chromatic Aberration Pass (Separate from Distortion!)
    if ShaderManager.chromatic_enabled and ShaderManager.shader_chromatic then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_chromatic:send("chromatic_strength", ShaderManager.chromatic_strength)
        love.graphics.setShader(ShaderManager.shader_chromatic)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- 10. CRT Distortion Pass
    if ShaderManager.crt_enabled and ShaderManager.shader_crt then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_crt:send("curvature", ShaderManager.curvature)
        love.graphics.setShader(ShaderManager.shader_crt)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(current_src, 0, 0)
        love.graphics.setShader()
        swap()
    end

    -- Render final processed canvas to screen
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(current_src, 0, 0)
end

function ShaderManager.toggle()
    ShaderManager.enabled = not ShaderManager.enabled
    return ShaderManager.enabled
end

function ShaderManager.get_active_name()
    if not ShaderManager.enabled then
        return "Disabled"
    end
    local active = {}
    if ShaderManager.crt_enabled then table.insert(active, "CRT") end
    if ShaderManager.chromatic_enabled then table.insert(active, "Chromatic") end
    if ShaderManager.pixel_matrix_enabled then table.insert(active, "Matrix") end
    if ShaderManager.motion_blur_enabled then table.insert(active, "Blur") end
    if ShaderManager.noise_enabled then table.insert(active, "Grain") end
    if ShaderManager.phosphor_enabled then table.insert(active, "Phosphor") end
    if ShaderManager.jitter_enabled then table.insert(active, "Jitter") end
    if ShaderManager.vhs_enabled then table.insert(active, "VHS") end
    if ShaderManager.scanlines_enabled then table.insert(active, "Scanlines") end
    if ShaderManager.bloom_enabled then table.insert(active, "Bloom") end
    if ShaderManager.palette_enabled then table.insert(active, "Palette") end
    if ShaderManager.ntsc_enabled then table.insert(active, "NTSC") end
    if #active == 0 then return "Enabled" end
    return table.concat(active, " + ")
end

return ShaderManager
