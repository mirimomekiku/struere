local BaseMode = require("lib.modes.base")

local Custom = {}
Custom.__index = Custom
setmetatable(Custom, { __index = BaseMode })

function Custom.new(config)
    config = config or {}
    config.name = config.name or "Custom"
    return BaseMode.new(config)
end

function Custom.newFromMenu(menu_config)
    local config = {
        name = "Custom",
        start_level = menu_config.start_level or 1,
        line_goal = menu_config.line_goal or nil,
        lock_delay = menu_config.lock_delay or 0.5,
        fixed_gravity = menu_config.fixed_gravity or false,
        time_limit = menu_config.time_limit or nil,
    }
    return Custom.new(config)
end

function Custom:drawHUD(state, x, y)
    BaseMode.drawHUD(self, state, x, y)
    local y2 = y + 260
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Mode: Custom", x, y2)
    if self.line_goal then
        love.graphics.print("Goal: " .. self.line_goal .. " lines", x, y2 + 20)
    else
        love.graphics.print("Goal: Infinite", x, y2 + 20)
    end
    if self.time_limit then
        local time_left = math.max(0, self.time_limit - self.timer)
        love.graphics.print("Time left: " .. string.format("%.1f", time_left) .. "s", x, y2 + 40)
    end
end

return Custom
