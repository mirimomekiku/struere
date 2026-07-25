local constants = require("lib.constants")
local shack = require("lib.vendor.shack")
local hermes = require("lib.vendor.hermes")
local Audio = require("lib.audio")

local Effects = {}

Effects.flash = {
    active = false,
    rows = {},
    timer = 0,
    duration = 0,
}

Effects.particles = {}
Effects.upward_particles = {}
Effects.popups = {}
Effects.bg_particles = {}

-- ─── Board Tilt & Shake Vector State ─────────────────────────────────────────
Effects.board_tilt = 0          -- Angle in radians
Effects.board_tilt_vel = 0      -- Angular velocity
Effects.board_offset_x = 0      -- Horizontal pixel offset
Effects.board_offset_x_vel = 0  -- Horizontal velocity
Effects.board_offset_y = 0      -- Vertical pixel offset
Effects.board_offset_y_vel = 0  -- Vertical velocity

Effects.board_stiffness = 320   -- Dynamic spring stiffness
Effects.board_damping = 17      -- Dynamic spring damping

function Effects.init_bg_particles()
    if #Effects.bg_particles > 0 then return end
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    for _ = 1, 35 do
        table.insert(Effects.bg_particles, {
            x = math.random(0, W),
            y = math.random(0, H),
            vx = (math.random() - 0.5) * 20,
            vy = -math.random(10, 45),
            size = math.random(2, 4),
            phase = math.random() * math.pi * 2,
            alpha = math.random(15, 45) / 100,
        })
    end
end

function Effects.update_bg_particles(dt, theme_name)
    Effects.init_bg_particles()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    for _, p in ipairs(Effects.bg_particles) do
        p.phase = p.phase + dt * 2
        local sway = math.sin(p.phase) * 12
        p.x = p.x + (p.vx + sway) * dt
        p.y = p.y + p.vy * dt

        if p.y < -10 then
            p.y = H + 10
            p.x = math.random(0, W)
        elseif p.x < -10 then
            p.x = W + 10
        elseif p.x > W + 10 then
            p.x = -10
        end
    end
end

function Effects.draw_bg_particles(theme_name)
    theme_name = theme_name or "retro"
    local color = {0.2, 0.7, 1.0}

    if theme_name == "cyberpunk" then
        color = {0.9, 0.0, 0.7}
    elseif theme_name == "ocean" then
        color = {0.1, 0.6, 0.9}
    elseif theme_name == "lava" or theme_name == "sunset" then
        color = {1.0, 0.4, 0.1}
    elseif theme_name == "flat" or theme_name == "pastel" then
        color = {0.5, 0.5, 0.7}
    elseif theme_name == "glass" then
        color = {0.6, 0.8, 1.0}
    end

    for _, p in ipairs(Effects.bg_particles) do
        love.graphics.setColor(color[1], color[2], color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

Effects.update_background_particles = Effects.update_bg_particles
Effects.draw_background_particles   = Effects.draw_bg_particles

function Effects.init()
    shack:setDimensions(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)

    -- Register hermes events for game polish
    hermes:on("hard_drop", function(col, distance)
        shack:shake(7)
        Audio.play("hard_drop")
        Effects.apply_impact(col or 5, distance or 10, true)
    end)

    hermes:on("line_clear", function(count, rows)
        if count == 4 then
            shack:shake(18)
            Effects.apply_impact(5.5, 12, true)
        else
            shack:shake(6 * count)
            Effects.apply_impact(5.5, 4 * count, false)
        end
        if rows then
            Effects.flash_start(rows)
        end
    end)
end

-- ─── Directional Board Impact & Tilt Vector ───────────────────────────────────
function Effects.apply_impact(col, drop_distance, is_hard_drop)
    col = col or 5.5
    drop_distance = drop_distance or 1
    -- Column offset normalized from center (1 = far right +1.0, 10 = far left -1.0)
    local norm_col = (col - 5.5) / 4.5
    norm_col = math.max(-1.0, math.min(1.0, norm_col))

    local dist_weight = math.min(2.2, 0.6 + drop_distance * 0.08)
    local mult = is_hard_drop and 1.0 or 0.45

    -- Angular tilt impulse: far-left tilts board left (- rads), far-right tilts board right (+ rads)
    Effects.board_tilt_vel = Effects.board_tilt_vel + (norm_col * 0.14 * dist_weight * mult)

    -- Vector translation displacement (horizontal & downward jolt)
    Effects.board_offset_x_vel = Effects.board_offset_x_vel + (norm_col * 45 * dist_weight * mult)
    Effects.board_offset_y_vel = Effects.board_offset_y_vel + (140 * dist_weight * mult)
end

function Effects.apply_board_transform(cx, cy)
    shack:apply()
    if math.abs(Effects.board_tilt) > 0.0001 or math.abs(Effects.board_offset_x) > 0.01 or math.abs(Effects.board_offset_y) > 0.01 then
        love.graphics.translate(cx + Effects.board_offset_x, cy + Effects.board_offset_y)
        love.graphics.rotate(Effects.board_tilt)
        love.graphics.translate(-cx, -cy)
    end
end

function Effects.shake_start(intensity, duration)
    shack:shake(intensity or 10)
end

function Effects.shake_update(dt)
    shack:update(dt)
end

function Effects.get_offset()
    return shack.ox, shack.oy
end

function Effects.apply_shake()
    shack:apply()
end

function Effects.flash_start(rows, duration)
    Effects.flash.active = true
    Effects.flash.rows = rows
    Effects.flash.duration = duration or constants.FLASH_DURATION
    Effects.flash.timer = 0
end

function Effects.flash_update(dt)
    if not Effects.flash.active then return end
    Effects.flash.timer = Effects.flash.timer + dt
    if Effects.flash.timer >= Effects.flash.duration then
        Effects.flash.active = false
        Effects.flash.rows = {}
    end
end

function Effects.flash_draw(board_x, board_y, cell_size)
    if not Effects.flash.active then return end
    local alpha = 1 - (Effects.flash.timer / Effects.flash.duration)
    love.graphics.setColor(1, 1, 1, alpha * 0.7)
    for _, row in ipairs(Effects.flash.rows) do
        local y = board_y + (row - 21) * cell_size
        love.graphics.rectangle("fill", board_x, y, 10 * cell_size, cell_size)
    end
end

-- ─── Spring Physics Text Engine ───────────────────────────────────────────────
function Effects.spawn_popup(text, x, y, color, duration, font_size)
    table.insert(Effects.popups, {
        text = text,
        x = x,
        y = y,
        vy = -35,               -- upward drift
        life = duration or 1.2,
        max_life = duration or 1.2,
        color = color or {1.0, 0.85, 0.20},
        font_size = font_size or 20,
        -- Elastic spring interpolation properties
        scale = 0.1,
        scale_target = 1.0,
        scale_vel = 15.0,
        stiffness = 380,
        damping = 18,
        rotation = (math.random() - 0.5) * 0.12,
    })
end

function Effects.all_clear_burst(board_x, board_y, cell_size)
    shack:shake(25)
    Effects.apply_impact(5.5, 15, true)
    local cx = board_x + 5 * cell_size
    local cy = board_y + 10 * cell_size
    
    -- Radial explosion particles
    for i = 1, 60 do
        local angle = (i / 60) * math.pi * 2
        local speed = 120 + math.random() * 220
        table.insert(Effects.particles, {
            x = cx,
            y = cy,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.8 + math.random() * 0.5,
            max_life = 0.8 + math.random() * 0.5,
            color = {0, 240, 255},
            size = 4 + math.random() * 5,
        })
    end

    Effects.spawn_popup("PERFECT CLEAR!", cx, cy - 30, {0.2, 1.0, 0.4}, 2.0, 26)
end

function Effects.particles_spawn(x, y, color, count)
    count = count or constants.PARTICLE_COUNT
    for _ = 1, count do
        table.insert(Effects.particles, {
            x = x,
            y = y,
            vx = (math.random() * 2 - 1) * 150,
            vy = (math.random() * -1 - 0.5) * 120,
            life = 0.5 + math.random() * 0.3,
            max_life = 0.5 + math.random() * 0.3,
            color = color or {255, 255, 255},
            size = 2 + math.random() * 3,
        })
    end
end

function Effects.spawn_line_clear_upward_particles(board_x, board_y, cell_size, cleared_rows, color)
    color = color or {0, 210, 255}
    for _, row in ipairs(cleared_rows) do
        local ry = board_y + (row - 21) * cell_size + cell_size / 2
        local particles_per_row = 14
        for i = 1, particles_per_row do
            local rx = board_x + (i / (particles_per_row + 1)) * (10 * cell_size) + (math.random() * 10 - 5)
            table.insert(Effects.upward_particles, {
                x = rx,
                y = ry,
                vx = (math.random() - 0.5) * 35,
                vy = -110 - math.random() * 110,
                gravity = -50,
                life = 0.45 + math.random() * 0.35,
                max_life = 0.45 + math.random() * 0.35,
                color = color,
                size = 2 + math.random() * 3,
            })
        end
    end
end

function Effects.particles_update(dt)
    for i = #Effects.particles, 1, -1 do
        local p = Effects.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Effects.particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 200 * dt
        end
    end

    for i = #Effects.upward_particles, 1, -1 do
        local p = Effects.upward_particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Effects.upward_particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + p.gravity * dt
        end
    end

    -- ─── Spring physics update for Popups ─────────────────────────────────────
    for i = #Effects.popups, 1, -1 do
        local pop = Effects.popups[i]
        pop.life = pop.life - dt
        if pop.life <= 0 then
            table.remove(Effects.popups, i)
        else
            pop.y = pop.y + pop.vy * dt
            
            -- Damped Spring Harmonic Oscillator
            local displacement = pop.scale - pop.scale_target
            local spring_force = -pop.stiffness * displacement
            local damping_force = -pop.damping * pop.scale_vel
            local accel = spring_force + damping_force
            pop.scale_vel = pop.scale_vel + accel * dt
            pop.scale = pop.scale + pop.scale_vel * dt
        end
    end
end

function Effects.particles_draw()
    for _, p in ipairs(Effects.particles) do
        local alpha = p.life / p.max_life
        love.graphics.setColor(p.color[1] / 255, p.color[2] / 255, p.color[3] / 255, alpha)
        love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    for _, p in ipairs(Effects.upward_particles) do
        local alpha = math.sin((p.life / p.max_life) * math.pi)
        local r, g, b = p.color[1]/255, p.color[2]/255, p.color[3]/255
        love.graphics.setColor(r, g, b, alpha * 0.85)
        love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size, 1, 1)
        love.graphics.setColor(1, 1, 1, alpha * 0.9)
        love.graphics.rectangle("fill", p.x - p.size / 4, p.y - p.size / 4, p.size / 2, p.size / 2)
    end

    -- ─── Spring Text Popup Drawing ────────────────────────────────────────────
    local Fonts = require("lib.fonts")
    for _, pop in ipairs(Effects.popups) do
        local alpha = math.min(1, pop.life / (pop.max_life * 0.25))
        love.graphics.push()
        love.graphics.translate(pop.x, pop.y)
        love.graphics.scale(pop.scale, pop.scale)
        love.graphics.rotate(pop.rotation or 0)

        local font = Fonts.get(pop.font_size or 20)
        love.graphics.setFont(font)
        local tw = font:getWidth(pop.text)
        local th = font:getHeight()

        -- Dynamic Drop Shadow
        love.graphics.setColor(0, 0, 0, alpha * 0.85)
        love.graphics.print(pop.text, -tw / 2 + 2, -th / 2 + 2)

        -- Glowing Main Text
        love.graphics.setColor(pop.color[1], pop.color[2], pop.color[3], alpha)
        love.graphics.print(pop.text, -tw / 2, -th / 2)

        love.graphics.pop()
    end
end

function Effects.update(dt)
    shack:update(dt)

    -- Spring physics update for Board Tilt & Offset Vectors
    local tilt_accel = -Effects.board_stiffness * Effects.board_tilt - Effects.board_damping * Effects.board_tilt_vel
    Effects.board_tilt_vel = Effects.board_tilt_vel + tilt_accel * dt
    Effects.board_tilt = Effects.board_tilt + Effects.board_tilt_vel * dt

    local ox_accel = -Effects.board_stiffness * Effects.board_offset_x - Effects.board_damping * Effects.board_offset_x_vel
    Effects.board_offset_x_vel = Effects.board_offset_x_vel + ox_accel * dt
    Effects.board_offset_x = Effects.board_offset_x + Effects.board_offset_x_vel * dt

    local oy_accel = -Effects.board_stiffness * Effects.board_offset_y - Effects.board_damping * Effects.board_offset_y_vel
    Effects.board_offset_y_vel = Effects.board_offset_y_vel + oy_accel * dt
    Effects.board_offset_y = Effects.board_offset_y + Effects.board_offset_y_vel * dt

    Effects.flash_update(dt)
    Effects.particles_update(dt)
end

function Effects.clear()
    Effects.flash.active = false
    Effects.flash.rows = {}
    Effects.particles = {}
    Effects.upward_particles = {}
    Effects.popups = {}
    Effects.bg_particles = {}
    Effects.board_tilt = 0
    Effects.board_tilt_vel = 0
    Effects.board_offset_x = 0
    Effects.board_offset_x_vel = 0
    Effects.board_offset_y = 0
    Effects.board_offset_y_vel = 0
end

return Effects
