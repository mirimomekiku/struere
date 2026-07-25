-- lib/countdown.lua
-- Retro Arcade Game Start Countdown (3, 2, 1, GO!)

local Audio = require("lib.audio")
local Fonts = require("lib.fonts")

local Countdown = {}

function Countdown.new(duration)
    local self = {
        timer = duration or 3.2,
        active = true,
        last_sec = -1,
        scale = 1.0,
    }
    return setmetatable(self, { __index = Countdown })
end

function Countdown:reset(duration)
    self.timer = duration or 3.2
    self.active = true
    self.last_sec = -1
    self.scale = 1.6
end

function Countdown:update(dt)
    if not self.active then return end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.active = false
        return
    end

    local sec = math.ceil(self.timer - 0.2)
    if sec ~= self.last_sec then
        self.last_sec = sec
        self.scale = 1.75 -- pulse scale on integer change
        if sec > 0 then
            Audio.play("move")
        else
            Audio.play("clear_single")
        end
    end

    -- Decay scale back to 1.0 smoothly
    self.scale = self.scale + (1.0 - self.scale) * math.min(1, dt * 12)
end

function Countdown:draw(center_x, center_y)
    if not self.active then return end

    local sec = math.ceil(self.timer - 0.2)
    local text = ""
    local color = {1, 1, 1}

    if sec >= 3 then
        text = "3"
        color = {0.20, 0.85, 1.00}
    elseif sec == 2 then
        text = "2"
        color = {1.00, 0.85, 0.20}
    elseif sec == 1 then
        text = "1"
        color = {1.00, 0.45, 0.20}
    else
        text = "GO!"
        color = {0.20, 1.00, 0.40}
    end

    love.graphics.push()
    love.graphics.translate(center_x, center_y)
    love.graphics.scale(self.scale, self.scale)

    -- Soft backdrop shadow
    love.graphics.setFont(Fonts.get(48))
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf(text, -100 + 4, -30 + 4, 200, "center")

    -- Main colored text
    love.graphics.setColor(color[1], color[2], color[3], 0.98)
    love.graphics.printf(text, -100, -30, 200, "center")

    love.graphics.pop()
end

return Countdown
