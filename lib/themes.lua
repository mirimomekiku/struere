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
    ocean = {
        name = "Ocean Deep",
        background = {0.02, 0.06, 0.14},
        grid_color = {0.04, 0.10, 0.22},
        grid_border = {0.10, 0.35, 0.65},
        accent = {0.10, 0.60, 0.95},
        ghost_alpha = 0.2,
        block_style = "glass",
        highlight = {0.20, 0.70, 1.0, 0.15},
        colors = {
            I = {0, 210, 255}, O = {255, 220, 80}, T = {120, 80, 220},
            S = {40, 220, 140}, Z = {220, 60, 100}, J = {30, 100, 220}, L = {240, 170, 50},
        },
    },
    sunset = {
        name = "Sunset Blaze",
        background = {0.12, 0.04, 0.04},
        grid_color = {0.18, 0.06, 0.06},
        grid_border = {0.60, 0.25, 0.15},
        accent = {1.0, 0.45, 0.15},
        ghost_alpha = 0.22,
        block_style = "filled",
        highlight = {1.0, 0.6, 0.2, 0.12},
        colors = {
            I = {255, 200, 60}, O = {255, 120, 40}, T = {200, 50, 120},
            S = {255, 160, 80}, Z = {200, 40, 60}, J = {180, 60, 160}, L = {255, 220, 100},
        },
    },
    pastel = {
        name = "Soft Pastel",
        background = {0.92, 0.90, 0.95},
        grid_color = {0.82, 0.80, 0.88},
        grid_border = {0.70, 0.68, 0.78},
        accent = {0.60, 0.45, 0.80},
        ghost_alpha = 0.18,
        block_style = "flat",
        highlight = {0, 0, 0, 0.04},
        colors = {
            I = {130, 210, 240}, O = {250, 230, 130}, T = {190, 140, 220},
            S = {140, 220, 160}, Z = {240, 150, 150}, J = {140, 170, 230}, L = {240, 200, 140},
        },
    },
    monochrome = {
        name = "Monochrome",
        background = {0.08, 0.08, 0.08},
        grid_color = {0.14, 0.14, 0.14},
        grid_border = {0.35, 0.35, 0.35},
        accent = {0.85, 0.85, 0.85},
        ghost_alpha = 0.15,
        block_style = "filled",
        highlight = {1, 1, 1, 0.08},
        colors = {
            I = {200, 200, 200}, O = {220, 220, 220}, T = {170, 170, 170},
            S = {190, 190, 190}, Z = {160, 160, 160}, J = {180, 180, 180}, L = {210, 210, 210},
        },
    },
    lava = {
        name = "Lava Core",
        background = {0.06, 0.01, 0.01},
        grid_color = {0.12, 0.03, 0.02},
        grid_border = {0.65, 0.15, 0.0},
        accent = {1.0, 0.30, 0.0},
        ghost_alpha = 0.25,
        block_style = "neon",
        highlight = {1.0, 0.4, 0.0, 0.15},
        colors = {
            I = {255, 100, 0}, O = {255, 200, 0}, T = {255, 50, 50},
            S = {255, 150, 0}, Z = {200, 30, 0}, J = {255, 80, 30}, L = {255, 220, 50},
        },
    },
}

Themes.current = Themes.list.retro
Themes.current_name = "retro"
Themes.order = {"retro", "flat", "glass", "cyberpunk", "ocean", "sunset", "pastel", "monochrome", "lava"}

function Themes.set(name)
    if Themes.list[name] then
        Themes.current = Themes.list[name]
        Themes.current_name = name
    end
end

function Themes.get_ui_theme()
    return Themes.list.retro
end

function Themes.get_board_theme()
    return Themes.current
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
