love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setLineStyle("rough")
Util = {}
require "Engine.Util.Other"
require "Engine.Util.Splines and Easing"
require "Engine.Util.UI"
require "Engine.Util.Math"
require "Engine.Util.Drawing"
require "Engine.Macros"
require "Engine.Util.File"
require "Engine.Util.Color"
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
require "Engine.Moveable Subclasses.Button"
require "Engine.Moveable Subclasses.WorldMoveables"
local function wrapper(key, px, py)
    registerAtlasSimple(key, "Assets/Sprites/"..key..".png", px, py)
end
wrapper("grassBase", 40, 21)
wrapper("grassFoley", 40, 21)
wrapper("grassEdge1", 40, 21)
wrapper("grassEdge2", 40, 21)
wrapper("grassEdge3", 40, 21)
wrapper("grassEdge4", 40, 21)
wrapper("prisonBase", 40, 21)
wrapper("prisonFoley", 40, 21)
wrapper("prisonEdge1", 40, 21)
wrapper("prisonEdge2", 40, 21)
wrapper("prisonEdge3", 40, 21)
wrapper("prisonEdge4", 40, 21)
wrapper("titlescreenBg", 600, 400)
wrapper("titlescreenFg", 600, 400)
wrapper("titlescreenDawn", 600, 400)
wrapper("UICancel", 600, 400)
wrapper("UIHP", 600, 400)
wrapper("UIItemRibbon", 600, 400)
wrapper("UIMove", 600, 400)
wrapper("UIMoveInactive", 600, 400)
wrapper("UITimer", 600, 400)
wrapper("UITimerIcon", 25, 47)
Util.Audio.registerMusic("title", { "Assets", "Audio", "Music", "title" }, { volume = 0.8 })
Util.Audio.registerMusic("overworld", { "Assets", "Audio", "Music", "overworld" })
Util.Audio.registerMusic("battle", { "Assets", "Audio", "Music", "battle" })
Util.Audio.registerSfx("blip_hover", { "Assets", "Audio", "SFX", "blip_hover" }, {volume = 5}, ".wav")
Util.Audio.registerSfx("blip_unhover", { "Assets", "Audio", "SFX", "blip_unhover" }, { volume = 5 }, ".wav")
Util.Audio.registerSfx("blip_stopped", { "Assets", "Audio", "SFX", "blip_stopped" }, { volume = 5 }, ".wav")

function love.load()
    Util.Audio.musicPush("title", "titleID", "title", 1, 1, 1, { looping = true })
    Macros.UIDef.title()
end
function love.update(dt)
    DELTATIME = dt
    G:update(dt)
    PREVIOUS_DELTATIME = dt
end

function love.draw()
    G:draw()
end
