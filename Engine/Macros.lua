local function hex(hex)
	if string.sub(hex, 1, 1) == "#" then
		hex = string.sub(hex, 2, string.len(hex))
	end
	if #hex <= 6 then hex = hex .. "FF" end
	local _, _, r, g, b, a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
	local color = { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255 or 255 }
	return color
end

Macros = {
	fileSuffix = ".con",
	gridSingleSubdivision = 5,
	screenDimentions = { y = 3, x = 4}, -- 3/4
	screenStretchTolerance = { max = 1, min = 1/2 },
	colors = {
		transparent = { 0, 0, 0, 0 },
		darkRed = hex("#6d1d51"),
		yellow = hex("#ffd94d"),
		orange = hex("#f26e26"),
		green = hex("#3ea121"),
		darkGreen = hex("#1d772f"),
		blue = hex("#4deae9"),
		purple = hex("#cc28dc"),
		white = {1,1,1,1},
		black = {0,0,0,1},
		red = hex("#d31212"),
		lightRed = hex("#ff99c5"),
		night = hex("#150c41"),
		lightBlack = hex("#100f24"),
		grey = hex("#57697f"),
		dawn = hex("#38166a")
	},
	posCenter = {x = 10, y = 7.5},
	fonts = {
		base = love.graphics.newFont("Assets/Fonts/aseprite.ttf", 7),
		times = love.graphics.newFont("Assets/Fonts/times.ttf", 50),
		timer = love.graphics.newImageFont("Assets/Sprites/TimerFont.png", " 0123456789/")
	},
	maxHps = {
		guard = 1,
		cellmate = 5,
		turret = 11,
	},
	names = {
		guard = "Guard",
		cellmate = "Cellmate",
		turret = "Turret",
	},
	calculates = {
		cellmate = function(context, e)
			if context.player_move and math.random(2) == 1 then
				local dir = nil
				if (math.abs(context.pos.x - e.TMod.x.base)>1 and math.abs(context.pos.y - e.TMod.y.base)>1) then -- both
					dir = math.random(2)
				elseif math.abs(context.pos.x - e.TMod.x.base)>1 then -- both
					dir = 1
				elseif math.abs(context.pos.x - e.TMod.x.base)>1 then -- both
					dir = 2
				end

				dir = dir == 1 and "x" or "y"

				context.pos[dir] = context.pos[dir] + math.sign(context.pos[dir] - e.TMod[dir].base)
			end
		end,
		turret = function(context, e)
			if context.player_move and (Util.Math.precisionCheck(context.pos.x, e.TMod.x.base, 0.1) or Util.Math.precisionCheck(context.pos.y, e.TMod.y.base, 0.1)) then
				Util.Event.delayFunc(0.15, function()
					Util.World.modHP(-2)
				end, "moveDelay")
				Util.Event.delayFunc(0.15, function()
				end, "moveDelay")
			end
		end,
	},
	baseTileSize = 40,
	maxtime = 360,
	maxhp = 60,
	itesmslots = 4
}