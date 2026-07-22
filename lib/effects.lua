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

function Effects.init()
    shack:setDimensions(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)

    -- Register hermes events for game polish
    hermes:on("hard_drop", function()
        shack:shake(8)
        Audio.play("hard_drop")
    end)

    hermes:on("line_clear", function(count, rows)
        if count == 4 then
            shack:shake(18)
        else
            shack:shake(6 * count)
        end
        if rows then
            Effects.flash_start(rows)
        end
    end)
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
end

function Effects.particles_draw()
    for _, p in ipairs(Effects.particles) do
        local alpha = p.life / p.max_life
        love.graphics.setColor(p.color[1] / 255, p.color[2] / 255, p.color[3] / 255, alpha)
        love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

function Effects.update(dt)
    shack:update(dt)
    Effects.flash_update(dt)
    Effects.particles_update(dt)
end

function Effects.clear()
    Effects.flash.active = false
    Effects.flash.rows = {}
    Effects.particles = {}
end

return Effects
