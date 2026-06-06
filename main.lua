love.graphics.setDefaultFilter("nearest", "nearest", 1)

Util = {}
require "Engine.Object"
require "Engine.Vector"
require "Engine.Util.Other"
require "Engine.Util.Splines and Easing"
require "Engine.Util.UI"
require "Engine.Util.Math"
require "Engine.Util.Drawing"
require "Engine.Function Overrides and Misc"
require "Engine.Macros"
require "Engine.Game"
require "Engine.Event"
require "Engine.Cutscenes"
require "Engine.Sprites"
require "Engine.Moveable"

Macros.CDefs.Opening()

function love.update(dt)
    DELTATIME = dt
    G:update(dt)
    PREVIOUS_DELTATIME = dt
end

function love.draw()
    G:draw()
end
