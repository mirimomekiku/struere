local Modes = {}

Modes.marathon = require("lib.modes.marathon")
Modes.sprint = require("lib.modes.sprint")
Modes.blitz = require("lib.modes.blitz")
Modes.zen = require("lib.modes.zen")
Modes.custom = require("lib.modes.custom")

Modes.order = {"marathon", "sprint", "blitz", "zen", "custom"}

Modes.labels = {
    marathon = "Marathon",
    sprint = "Sprint (40 Lines)",
    blitz = "Blitz (2 Min)",
    zen = "Zen (Infinite)",
    custom = "Custom",
}

function Modes.create(name, config)
    local mode_class = Modes[name]
    if not mode_class then return nil end
    return mode_class.new(config)
end

function Modes.getNames()
    return Modes.order
end

function Modes.getLabel(name)
    return Modes.labels[name] or name
end

return Modes
