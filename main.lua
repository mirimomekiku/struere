local StateMgr = require("lib.state_mgr")
local Input = require("lib.input")
local Themes = require("lib.themes")
local Effects = require("lib.effects")
local Audio = require("lib.audio")
local Save = require("lib.save")
local constants = require("lib.constants")
local ShaderManager = require("lib.shaders.manager")
local BlockStyles = require("lib.block_styles")

function love.load()
    love.window.setMode(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT, {resizable = false})
    love.window.setTitle("TetriX - Refined Retro Edition")
    math.randomseed(os.time())

    Save.load()
    Input.load()
    Effects.init()
    ShaderManager.init()
    BlockStyles.load()

    Save.apply_all_settings()

    local GameplayOpts = require("lib.gameplay_opts")
    GameplayOpts.load()

    local saved_bindings = Save.get("controls")
    if saved_bindings and saved_bindings ~= "" then
        Input.load_bindings(saved_bindings)
    end

    Audio.init()

    StateMgr.register("title", require("lib.screens.title"))
    StateMgr.register("gameplay", require("lib.screens.gameplay"))
    StateMgr.register("pause", require("lib.screens.pause"))
    StateMgr.register("settings", require("lib.screens.settings"))
    StateMgr.register("gameover", require("lib.screens.gameover"))
    StateMgr.register("highscores", require("lib.screens.highscores"))
    StateMgr.register("unlockables", require("lib.screens.unlockables"))
    StateMgr.register("mode_select", require("lib.screens.mode_select"))
    StateMgr.register("battle",      require("lib.screens.battle"))

    StateMgr.switch("title")
end

function love.update(dt)
    Audio.update(dt)
    ShaderManager.update(dt)
    StateMgr.update(dt)
end

function love.draw()
    if ShaderManager.enabled then
        ShaderManager.start_capture()
        StateMgr.draw()
        ShaderManager.end_capture_and_draw()
    else
        StateMgr.draw()
    end
end

function love.keypressed(key)
    StateMgr.keypressed(key)
end

function love.keyreleased(key)
    StateMgr.keyreleased(key)
end
