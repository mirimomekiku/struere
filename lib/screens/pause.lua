-- lib/screens/pause.lua
-- Pause Modal Dialog with Quit Confirmation

local StateMgr = require("lib.state_mgr")
local Themes   = require("lib.themes")
local Audio    = require("lib.audio")
local Fonts    = require("lib.fonts")

local Pause = {}

Pause.selected = 1
Pause.options  = {"Resume", "Settings", "Main Menu"}

Pause.confirm_quit     = false
Pause.confirm_selected = 2  -- 1: Yes Quit, 2: No Stay (default for safety)

local function get_active_score()
    local Gameplay = package.loaded["lib.screens.gameplay"]
    local Battle   = package.loaded["lib.screens.battle"]

    if Gameplay then
        if (Gameplay.score and Gameplay.score >= 1) or (Gameplay.lines and Gameplay.lines >= 1) then
            return Gameplay.score or Gameplay.lines or 1
        end
    end

    if Battle then
        if (Battle.total_lines and Battle.total_lines >= 1) or (Battle.battle_level and Battle.battle_level > 1) then
            return Battle.total_lines or 1
        end
    end

    return 0
end

function Pause:enter(previous)
    Pause.selected = 1
    Pause.confirm_quit = false
    Pause.confirm_selected = 2
end

function Pause:update(dt)
end

function Pause:draw()
    local theme = Themes.get_ui_theme()
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()

    -- Dim backdrop
    love.graphics.setColor(0, 0, 0, 0.70)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local mw = 440
    local mh = 320
    local mx = math.floor((W - mw) / 2)
    local my = math.floor((H - mh) / 2)

    -- Modal Card Window
    love.graphics.setColor(0.04, 0.07, 0.16, 0.96)
    love.graphics.rectangle("fill", mx, my, mw, mh, 14, 14)
    love.graphics.setColor(0.20, 0.45, 0.90, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mx, my, mw, mh, 14, 14)
    love.graphics.setLineWidth(1)

    if not Pause.confirm_quit then
        -- ── Standard Pause Menu ──
        love.graphics.setFont(Fonts.get(22))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME PAUSED", mx, my + 24, mw, "center")

        love.graphics.setColor(0.2, 0.4, 0.8, 0.3)
        love.graphics.rectangle("fill", mx + 30, my + 60, mw - 60, 1)

        for i, opt in ipairs(Pause.options) do
            local y = my + 85 + (i - 1) * 55
            local is_sel = (i == Pause.selected)

            if is_sel then
                love.graphics.setColor(0.15, 0.45, 0.95, 0.9)
                love.graphics.rectangle("fill", mx + 50, y, mw - 100, 42, 8, 8)
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.08, 0.12, 0.24, 0.8)
                love.graphics.rectangle("fill", mx + 50, y, mw - 100, 42, 8, 8)
                love.graphics.setColor(0.7, 0.75, 0.88)
            end

            love.graphics.setFont(Fonts.get(16))
            love.graphics.printf(opt, mx + 50, y + 10, mw - 100, "center")
        end

        local InputPrompts = require("lib.input_prompts")
        local py = my + mh - 30
        local px = mx + 20
        InputPrompts.draw_action_icon("ROTATE_CW", px, py, 18)
        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(0.7, 0.8, 0.95)
        love.graphics.print("Confirm", px + 22, py + 2)

        InputPrompts.draw_action_icon("ROTATE_CCW", px + 120, py, 18)
        love.graphics.print("Resume", px + 142, py + 2)

        InputPrompts.draw_action_icon("PAUSE", px + 240, py, 18)
        love.graphics.print("Menu", px + 262, py + 2)
    else
        -- ── Confirmation Prompt Dialog (Score >= 1) ──
        love.graphics.setFont(Fonts.get(20))
        love.graphics.setColor(1, 0.35, 0.35)
        love.graphics.printf("QUIT TO MAIN MENU?", mx, my + 30, mw, "center")

        love.graphics.setFont(Fonts.get(13))
        love.graphics.setColor(0.85, 0.88, 0.95)
        love.graphics.printf("Your active game progress & score will be lost.", mx + 20, my + 75, mw - 40, "center")
        love.graphics.setColor(0.55, 0.60, 0.72)
        love.graphics.printf("Are you sure you want to exit?", mx + 20, my + 100, mw - 40, "center")

        local btn_w = 150
        local btn_h = 44
        local btn_y = my + 165
        local b1_x  = mx + 45
        local b2_x  = mx + mw - 45 - btn_w

        -- YES QUIT button
        if Pause.confirm_selected == 1 then
            love.graphics.setColor(0.85, 0.20, 0.20, 0.95)
            love.graphics.rectangle("fill", b1_x, btn_y, btn_w, btn_h, 8, 8)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.12, 0.14, 0.22, 0.8)
            love.graphics.rectangle("fill", b1_x, btn_y, btn_w, btn_h, 8, 8)
            love.graphics.setColor(0.7, 0.7, 0.8)
        end
        love.graphics.setFont(Fonts.get(14))
        love.graphics.printf("Yes, Quit", b1_x, btn_y + 12, btn_w, "center")

        -- NO STAY button
        if Pause.confirm_selected == 2 then
            love.graphics.setColor(0.15, 0.45, 0.95, 0.95)
            love.graphics.rectangle("fill", b2_x, btn_y, btn_w, btn_h, 8, 8)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.12, 0.14, 0.22, 0.8)
            love.graphics.rectangle("fill", b2_x, btn_y, btn_w, btn_h, 8, 8)
            love.graphics.setColor(0.7, 0.7, 0.8)
        end
        love.graphics.setFont(Fonts.get(14))
        love.graphics.printf("No, Stay", b2_x, btn_y + 12, btn_w, "center")

        local InputPrompts = require("lib.input_prompts")
        local py = my + mh - 30
        local px = mx + 60
        InputPrompts.draw_action_icon("ROTATE_CW", px, py, 18)
        love.graphics.setFont(Fonts.get(11))
        love.graphics.setColor(0.7, 0.8, 0.95)
        love.graphics.print("Confirm", px + 22, py + 2)

        InputPrompts.draw_action_icon("ROTATE_CCW", px + 180, py, 18)
        love.graphics.print("Cancel", px + 202, py + 2)
    end
end

function Pause:keypressed(key)
    if not Pause.confirm_quit then
        if key == "up" then
            Pause.selected = Pause.selected - 1
            if Pause.selected < 1 then Pause.selected = #Pause.options end
            Audio.play("move")
        elseif key == "down" then
            Pause.selected = Pause.selected + 1
            if Pause.selected > #Pause.options then Pause.selected = 1 end
            Audio.play("move")
        elseif key == "return" or key == "space" then
            Audio.play("rotate")
            if Pause.selected == 1 then
                StateMgr.pop()
            elseif Pause.selected == 2 then
                StateMgr.push("settings", { from_pause = true })
            elseif Pause.selected == 3 then
                local score = get_active_score()
                if score >= 1 then
                    Pause.confirm_quit = true
                    Pause.confirm_selected = 2
                else
                    StateMgr.switch("title")
                end
            end
        elseif key == "escape" then
            StateMgr.pop()
        end
    else
        -- Confirmation Prompt Navigation
        if key == "left" or key == "right" or key == "up" or key == "down" then
            Pause.confirm_selected = (Pause.confirm_selected == 1) and 2 or 1
            Audio.play("move")
        elseif key == "return" or key == "space" then
            Audio.play("rotate")
            if Pause.confirm_selected == 1 then
                Pause.confirm_quit = false
                StateMgr.switch("title")
            else
                Pause.confirm_quit = false
            end
        elseif key == "escape" then
            Pause.confirm_quit = false
        end
    end
end

return Pause
