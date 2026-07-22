-- shack.lua - Screen shake library for Love2D
local shack = {
    ox = 0,
    oy = 0,
    shake_amount = 0,
    shake_decay = 5,
    shaking = false
}

function shack:setDimensions(w, h)
    self.width = w
    self.height = h
end

function shack:shake(amount)
    self.shake_amount = math.max(self.shake_amount, amount or 10)
    self.shaking = true
end

function shack:update(dt)
    if self.shake_amount > 0 then
        self.ox = (math.random() * 2 - 1) * self.shake_amount
        self.oy = (math.random() * 2 - 1) * self.shake_amount
        self.shake_amount = math.max(0, self.shake_amount - self.shake_decay * dt * 10)
    else
        self.ox = 0
        self.oy = 0
        self.shaking = false
    end
end

function shack:apply()
    if self.shaking then
        love.graphics.translate(self.ox, self.oy)
    end
end

return shack
