-- baton.lua - Input manager for Love2D
local baton = {}

local Player = {}
Player.__index = Player

function Player.new(config)
    local self = setmetatable({}, Player)
    self.controls = config.controls or {}
    self.joystick = config.joystick or (love.joystick and love.joystick.getJoysticks()[1])
    self.state = {}
    self.prev_state = {}
    self:reset()
    return self
end

function Player:reset()
    for action in pairs(self.controls) do
        self.state[action] = false
        self.prev_state[action] = false
    end
end

function Player:is_source_down(src)
    if type(src) ~= "string" then return false end
    local src_type, name = src:match("^(%a+):(.+)$")
    if not src_type then
        src_type = "key"
        name = src
    end

    if src_type == "key" or src_type == "sc" then
        return love.keyboard.isDown(name)
    elseif src_type == "button" and self.joystick then
        return self.joystick:isGamepadButton(name)
    elseif src_type == "axis" and self.joystick then
        local axis, dir = name:match("^(%a+)([+-])$")
        if axis and dir then
            local val = self.joystick:getGamepadAxis(axis)
            if dir == "+" then return val > 0.5 end
            if dir == "-" then return val < -0.5 end
        end
    end
    return false
end

function Player:update()
    for action, sources in pairs(self.controls) do
        self.prev_state[action] = self.state[action]
        local active = false
        if type(sources) == "table" then
            for _, src in ipairs(sources) do
                if self:is_source_down(src) then
                    active = true
                    break
                end
            end
        elseif type(sources) == "string" then
            active = self:is_source_down(sources)
        end
        self.state[action] = active
    end
end

function Player:down(action)
    return self.state[action] == true
end

function Player:pressed(action)
    return self.state[action] == true and not self.prev_state[action]
end

function Player:released(action)
    return not self.state[action] and self.prev_state[action] == true
end

function Player:get(action)
    return self:down(action) and 1 or 0
end

function Player:rebind(action, new_sources)
    self.controls[action] = new_sources
end

function baton.new(config)
    return Player.new(config)
end

return baton
