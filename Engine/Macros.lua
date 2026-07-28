local function hex(hex)
	if string.sub(hex, 1, 1) == "#" then
		hex = string.sub(hex, 2, string.len(hex))
	end
	if #hex <= 6 then hex = hex .. "FF" end
	local _, _, r, g, b, a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
	local color = { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255 or 255 }
	return color
end

local function pixelFont(font)
	font:setFilter("nearest", "nearest", 1)
	return font
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
		base = pixelFont(love.graphics.newFont("Assets/Fonts/aseprite.ttf", 7, "normal", 1)),
		times = pixelFont(love.graphics.newFont("Assets/Fonts/times.ttf", 50, "normal", 1)),
		timer = pixelFont(love.graphics.newImageFont("Assets/Sprites/TimerFont.png", " 0123456789/", 0, 1))
	},
	maxHps = {
		-- prison
		guard = 1,
		cellmate = 5,
		cellboss = 20,
		officer = 5,

		-- field
		turret = 14,
		hunter = 8,
		wizard = 14,

		-- ruins
		skeleton = 3,
		elite = 18,
		abraham = 40,
		guardian = 18,
		cain = 36,
		
	},
	bossEnemies = {
		cellboss = true,
		wizard = true,
		abraham = true,
		cain = true,
	},
	names = {
		guard = "Guard",
		cellmate = "Cellmate",
		cellboss = "Bruiser",
		turret = "Turret",
		hunter = "Vampire Hunter",
		officer = "Officer",
		skeleton = "Skeleton",
		elite = "Elite Hunter",
		abraham = "Abraham",
		guardian = "Guardian",
		wizard = "Wizard",
		cain = "Cain",
	},
	cellBoss = {
		spawnChance = 1 / 8,
		damage = 15,
		minMove = 1,
		maxMove = 4,
		rechargeTurns = 2,
	},
	hunter = {
		damage = 3,
		magazine = 2,
		range = 4,
		idealDistance = 4,
	},
	officer = {
		spawnChance = 1 / 3,
		damage = 2,
		magazine = 1,
		range = 3,
		idealDistance = 3,
	},
	skeleton = {
		damage = 2,
		moveDistance = 2,
		downedTurns = 2,
	},
	elite = {
		spawnChance = 1 / 2,
		damage = 4,
		magazine = 3,
		range = 6,
		idealDistance = 5,
		moveDistance = 2,
		attackDamage = 10,
		attackRange = 7,
		attackChance = 1 / 2,
	},
	abraham = {
		spawnChance = 1 / 8,
		damage = 7,
		magazine = 4,
		range = 8,
		idealDistance = 6,
		moveDistance = 3,
		attackDamage = 15,
		attackRange = 9,
		aoeDamage = 14,
		aoeRadius = 2,
		aoeRange = 7,
		aoeChance = 0.25,
		jumpChance = 0.35,
		lineAttackChance = 0.15,
	},
	guardian = {
		spawnChance = 1 / 3,
		damage = 12,
		chargeTurns = 2,
	},
	cain = {
		closeRange = 2,
		closeDamage = 11,
		closeAttackChance = 0.65,
		aoeDamage = 14,
		aoeCooldown = 3,
		aoeAttackChance = 0.65,
		lineWidth = 3,
		moveDistance = 3,
		idealDistance = 5,
		jumpChance = 0.2,
	},
	wizard = {
		damage = 10,
		moveDistance = 3,
		rangeFraction = 1 / 2,
		minDistance = 3,
		aoeRadius = 2,
	},
	groundHealing = {
		spawnChance = 1 / 3,
		pool = "misc",
	},
	calculates = {},
	baseTileSize = 40,
	maxtime = 480,
	maxhp = 60,
	itesmslots = 4
}
