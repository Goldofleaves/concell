io.stdout:setvbuf("no")

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
require "Engine.Items"
require "Engine.Util.InfoQueue"
local function wrapper(key, px, py, folders)
    folders = folders or ""
    registerAtlasSimple(key, "Assets/Sprites/"..folders..key..".png", px, py)
end
wrapper("grassBase",  40, 21, "Tiles/Grass/")
wrapper("grassFoley", 40, 21, "Tiles/Grass/")
wrapper("grassEdge1", 40, 21, "Tiles/Grass/")
wrapper("grassEdge2", 40, 21, "Tiles/Grass/")
wrapper("grassEdge3", 40, 21, "Tiles/Grass/")
wrapper("grassEdge4", 40, 21, "Tiles/Grass/")
wrapper("ruinsBase",  40, 21, "Tiles/Ruins/")
wrapper("ruinsFoley", 40, 21, "Tiles/Ruins/")
wrapper("ruinsEdge1", 40, 21, "Tiles/Ruins/")
wrapper("ruinsEdge2", 40, 21, "Tiles/Ruins/")
wrapper("ruinsEdge3", 40, 21, "Tiles/Ruins/")
wrapper("ruinsEdge4", 40, 21, "Tiles/Ruins/")
wrapper("prisonBase",  40, 21, "Tiles/Prison/")
wrapper("prisonFoley", 40, 21, "Tiles/Prison/")
wrapper("prisonEdge1", 40, 21, "Tiles/Prison/")
wrapper("prisonEdge2", 40, 21, "Tiles/Prison/")
wrapper("prisonEdge3", 40, 21, "Tiles/Prison/")
wrapper("prisonEdge4", 40, 21, "Tiles/Prison/")
wrapper("titlescreenBg", 600, 400, "Title/")
wrapper("titlescreenFg", 600, 400, "Title/")
wrapper("titlescreenDawn", 600, 400, "Title/")
wrapper("UICancel", 600, 400, "UI/")
wrapper("UIHP", 600, 400, "UI/")
wrapper("UIItemRibbon", 600, 400, "UI/")
wrapper("UIMove", 600, 400, "UI/")
wrapper("UIMoveInactive", 600, 400, "UI/")
wrapper("UITimer", 600, 400, "UI/")
wrapper("UITimerIcon", 25, 47, "UI/")
wrapper("ItemBlank", 50, 47, "Items/")
wrapper("ItemKnife", 50, 47, "Items/")
wrapper("ItemMusket", 50, 47, "Items/")
wrapper("ItemWhip", 50, 47, "Items/")
wrapper("ItemSunscreen", 50, 47, "Items/")
wrapper("ItemGreatsword", 50, 47, "Items/")
wrapper("ItemEminence", 50, 47, "Items/")
wrapper("ItemRapier", 50, 47, "Items/")
wrapper("ItemPrisonKey", 50, 47, "Items/")
wrapper("ItemDagger", 50, 47, "Items/")
wrapper("Door", 40, 60, "Tiles/")
wrapper("Target", 40, 60, "Tiles/")
wrapper("prisonBar", 40, 60, "Tiles/")
wrapper("prisonGate", 40, 60, "Tiles/")
wrapper("prisonGateOpen", 40, 60, "Tiles/")
wrapper("prisonKey", 40, 60, "Tiles/")
wrapper("cover1", 40, 60, "Tiles/")
wrapper("cover2", 40, 60, "Tiles/")
wrapper("cover3", 40, 60, "Tiles/")
wrapper("cover4", 40, 60, "Tiles/")
wrapper("turret1", 40, 60, "Tiles/")
wrapper("turret2", 40, 60, "Tiles/")
wrapper("turret3", 40, 60, "Tiles/")
wrapper("turret4", 40, 60, "Tiles/")
wrapper("hunter1", 40, 60, "Tiles/")
wrapper("hunter2", 40, 60, "Tiles/")
wrapper("hunter3", 40, 60, "Tiles/")
wrapper("hunter4", 40, 60, "Tiles/")
wrapper("officer1", 40, 60, "Tiles/")
wrapper("officer2", 40, 60, "Tiles/")
wrapper("officer3", 40, 60, "Tiles/")
wrapper("officer4", 40, 60, "Tiles/")
wrapper("skeleton1", 40, 60, "Tiles/")
wrapper("skeleton2", 40, 60, "Tiles/")
wrapper("skeleton3", 40, 60, "Tiles/")
wrapper("skeleton4", 40, 60, "Tiles/")
wrapper("skeletonDowned", 40, 60, "Tiles/")
wrapper("elite1", 40, 60, "Tiles/")
wrapper("elite2", 40, 60, "Tiles/")
wrapper("elite3", 40, 60, "Tiles/")
wrapper("elite4", 40, 60, "Tiles/")
registerAtlasSimple("guard3", "Assets/Sprites/Tiles/guard.png", 40, 60)
wrapper("dawn1", 40, 60, "Tiles/")
wrapper("dawn2", 40, 60, "Tiles/")
wrapper("dawn3", 40, 60, "Tiles/")
wrapper("dawn4", 40, 60, "Tiles/")
wrapper("cellmate1", 40, 60, "Tiles/")
wrapper("cellmate2", 40, 60, "Tiles/")
wrapper("cellmate3", 40, 60, "Tiles/")
wrapper("cellmate4", 40, 60, "Tiles/")
wrapper("cellboss1", 40, 60, "Tiles/")
wrapper("cellboss2", 40, 60, "Tiles/")
wrapper("cellboss3", 40, 60, "Tiles/")
wrapper("cellboss4", 40, 60, "Tiles/")
wrapper("danger_1", 40, 60, "Tiles/")
wrapper("danger_2", 40, 60, "Tiles/")
wrapper("tileAttack_1", 40, 60, "Tiles/")
wrapper("tileAttack_2", 40, 60, "Tiles/")
wrapper("tileAttack_3", 40, 60, "Tiles/")
wrapper("tileAttack_4", 40, 60, "Tiles/")
wrapper("cutscene", 600, 500)
wrapper("gameOver", 600, 400)
wrapper("gameWin", 600, 400)
wrapper("hpSymbol", 7, 9)
Util.Audio.registerMusic("title", { "Assets", "Audio", "Music", "title" }, { volume = 0.8 })
Util.Audio.registerMusic("overworld", { "Assets", "Audio", "Music", "overworld" })
Util.Audio.registerMusic("battle", { "Assets", "Audio", "Music", "battle" })
Util.Audio.registerMusic("interrogation", { "Assets", "Audio", "Music", "interrogation" })
Util.Audio.registerMusic("ambience", { "Assets", "Audio", "Music", "ambience" })
Util.Audio.registerSfx("blip_hover", { "Assets", "Audio", "SFX", "blip_hover" }, {volume = 5}, ".wav")
Util.Audio.registerSfx("blip_unhover", { "Assets", "Audio", "SFX", "blip_unhover" }, { volume = 5 }, ".wav")
Util.Audio.registerSfx("blip_stopped", { "Assets", "Audio", "SFX", "blip_stopped" }, { volume = 5 }, ".wav")
Util.Audio.registerSfx("start_jingle", { "Assets", "Audio", "SFX", "start_jingle" }, { volume = 5 }, ".wav")
Util.Audio.registerSfx("fatalhit", { "Assets", "Audio", "SFX", "fatalhit" })
Util.Audio.registerSfx("hit", { "Assets", "Audio", "SFX", "hit" })
Util.Audio.registerSfx("key_pick", { "Assets", "Audio", "SFX", "key_pick" }, nil, ".wav")
Util.Audio.registerSfx("gate_unlock", { "Assets", "Audio", "SFX", "gate_unlock" }, nil, ".wav")
Util.Audio.registerSfx("slam", { "Assets", "Audio", "SFX", "slam" }, nil, ".wav")

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
