love.graphics.setDefaultFilter("nearest", "nearest", 1)

Util = {}
require "Engine.Util.Other"
require "Engine.Util.Audio"
require "Engine.Util.Splines and Easing"
require "Engine.Util.UI"
require "Engine.Util.Math"
require "Engine.Util.Drawing"
require "Engine.Util.File"
require "Engine.Function Overrides and Misc"
require "Engine.Object"
require "Engine.Text"
require "Engine.UI Definitions"
require "Engine.Vector"
require "Engine.Macros"
require "Engine.Game"
require "Engine.Event"
require "Engine.Cutscenes"
require "Engine.Sprites"
require "Engine.Moveable"
function love.load()
    Macros.CDefs.Opening()
end
function love.update(dt)
    DELTATIME = dt
    G:update(dt)
    PREVIOUS_DELTATIME = dt
end

function love.draw()
    G:draw()
end
