-- Shader Manager for TetriX
local ShaderManager = {}

ShaderManager.enabled = true
ShaderManager.palette_enabled = true
ShaderManager.palette_mode = 0 -- 0: GameBoy, 1: Cyberpunk, 2: NES, 3: CGA, 4: Mono, 5: Vaporwave
ShaderManager.dither_strength = 0.4

ShaderManager.scanlines_enabled = true
ShaderManager.scanline_count = 240.0
ShaderManager.scanline_intensity = 0.3

ShaderManager.crt_enabled = true
ShaderManager.curvature = 4.0
ShaderManager.chromatic_aberration = 0.002
ShaderManager.bloom_strength = 0.5

ShaderManager.ntsc_enabled = false
ShaderManager.artifact_strength = 1.0

ShaderManager.time = 0

function ShaderManager.init()
    local status_p, s_palette = pcall(love.graphics.newShader, "lib/shaders/palette.glsl")
    if status_p then ShaderManager.shader_palette = s_palette end

    local status_sc, s_scanlines = pcall(love.graphics.newShader, "lib/shaders/scanlines.glsl")
    if status_sc then ShaderManager.shader_scanlines = s_scanlines end

    local status_crt, s_crt = pcall(love.graphics.newShader, "lib/shaders/crt.glsl")
    if status_crt then ShaderManager.shader_crt = s_crt end

    local status_ntsc, s_ntsc = pcall(love.graphics.newShader, "lib/shaders/ntsc.glsl")
    if status_ntsc then ShaderManager.shader_ntsc = s_ntsc end

    local w, h = love.graphics.getDimensions()
    ShaderManager.canvas_raw = love.graphics.newCanvas(w, h)
    ShaderManager.canvas_proc = love.graphics.newCanvas(w, h)
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

    local current_src = ShaderManager.canvas_raw
    local current_dst = ShaderManager.canvas_proc

    local function swap()
        local tmp = current_src
        current_src = current_dst
        current_dst = tmp
    end

    -- 1. Palette Pass
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

    -- 2. NTSC Pass
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

    -- 3. Scanlines Pass
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

    -- 4. CRT Curvature & Bloom Pass
    if ShaderManager.crt_enabled and ShaderManager.shader_crt then
        love.graphics.setCanvas(current_dst)
        love.graphics.clear()
        ShaderManager.shader_crt:send("curvature", ShaderManager.curvature)
        ShaderManager.shader_crt:send("chromatic_aberration", ShaderManager.chromatic_aberration)
        ShaderManager.shader_crt:send("bloom_strength", ShaderManager.bloom_strength)
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

return ShaderManager
