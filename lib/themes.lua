local Themes = {}

Themes.list = {
    retro = {
        name = "Retro Arcade",
        background = {0.05, 0.05, 0.1},
        grid_color = {0.15, 0.15, 0.2},
        grid_border = {0.3, 0.3, 0.4},
        accent = {0.2, 0.7, 1.0},
        ghost_alpha = 0.25,
        block_style = "filled",
        highlight = {1, 1, 1, 0.1},
        colors = {
            I = {0, 240, 240}, O = {240, 240, 0}, T = {160, 0, 240},
            S = {0, 240, 0}, Z = {240, 0, 0}, J = {0, 0, 240}, L = {240, 160, 0},
        },
    },
    flat = {
        name = "Minimalist Flat",
        background = {0.95, 0.95, 0.95},
        grid_color = {0.85, 0.85, 0.85},
        grid_border = {0.75, 0.75, 0.75},
        accent = {0.1, 0.5, 0.8},
        ghost_alpha = 0.2,
        block_style = "flat",
        highlight = {0, 0, 0, 0.05},
        colors = {
            I = {0, 180, 200}, O = {220, 200, 0}, T = {140, 0, 200},
            S = {0, 180, 60}, Z = {200, 40, 40}, J = {40, 40, 200}, L = {200, 120, 0},
        },
    },
    glass = {
        name = "Glass",
        background = {0.08, 0.08, 0.15},
        grid_color = {0.12, 0.12, 0.25},
        grid_border = {0.2, 0.2, 0.4},
        accent = {0.4, 0.3, 0.9},
        ghost_alpha = 0.15,
        block_style = "glass",
        highlight = {1, 1, 1, 0.2},
        colors = {
            I = {0, 200, 220}, O = {220, 200, 0}, T = {150, 0, 220},
            S = {0, 200, 60}, Z = {220, 40, 40}, J = {40, 40, 220}, L = {220, 140, 0},
        },
    },
    cyberpunk = {
        name = "Cyberpunk",
        background = {0.02, 0.01, 0.05},
        grid_color = {0.08, 0.02, 0.12},
        grid_border = {0.4, 0.0, 0.6},
        accent = {0.9, 0.0, 0.6},
        ghost_alpha = 0.3,
        block_style = "neon",
        highlight = {0.6, 0.0, 1.0, 0.15},
        colors = {
            I = {0, 255, 255}, O = {255, 255, 0}, T = {200, 0, 255},
            S = {0, 255, 100}, Z = {255, 0, 80}, J = {80, 80, 255}, L = {255, 180, 0},
        },
    },
}

Themes.current = Themes.list.retro
Themes.current_name = "retro"
Themes.order = {"retro", "flat", "glass", "cyberpunk"}

function Themes.set(name)
    if Themes.list[name] then
        Themes.current = Themes.list[name]
        Themes.current_name = name
    end
end

function Themes.get()
    return Themes.current
end

function Themes.cycle()
    local idx = 1
    for i, name in ipairs(Themes.order) do
        if name == Themes.current_name then
            idx = i
            break
        end
    end
    idx = idx % #Themes.order + 1
    Themes.set(Themes.order[idx])
    return Themes.current.name
end

return Themes
