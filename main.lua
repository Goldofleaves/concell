love.graphics.setDefaultFilter("nearest", "nearest", 1)

Util = {}
require "Engine.Util.Other"
require "Engine.Util.Splines and Easing"
require "Engine.Util.UI"
require "Engine.Util.Math"
require "Engine.Util.Drawing"
require "Engine.Macros"
require "Engine.Util.File"
require "Engine.Function Overrides and Misc"
require "Engine.Object"
require "Engine.Text"
require "Engine.Vector"
require "Engine.Game"
require "Engine.Event"
require "Engine.Cutscenes"
require "Engine.Sprites"
require "Engine.Moveable"
require "Engine.UI Definitions"
require "Engine.Moveable Definitions"
require "Engine.Util.Audio"
require "Engine.Util.World"
local function wrapper(key, px, py)
    registerAtlasSimple(key, "Assets/Sprites/"..key..".png", px, py)
end
wrapper("grassBase", 40, 21)
wrapper("grassFoley", 40, 21)
wrapper("grassEdge1", 40, 21)
wrapper("grassEdge2", 40, 21)
wrapper("grassEdge3", 40, 21)
wrapper("grassEdge4", 40, 21)
function love.load()
    Macros.MDef.isometricGrid(5, 8)
end
function love.update(dt)
    DELTATIME = dt
    G:update(dt)
    PREVIOUS_DELTATIME = dt
end

function love.draw()
    G:draw()
end
