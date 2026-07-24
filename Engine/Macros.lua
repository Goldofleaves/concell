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
		blue = hex("#4deae9"),
		purple = hex("#cc28dc"),
		white = {1,1,1,1},
		black = {0,0,0,1},
		red = hex("#d31212"),
		lightRed = hex("#ff99c5"),
		night = hex("#150c41"),
		lightBlack = hex("#100f24"),
		grey = hex("#57697f")
	},
	posCenter = {x = 10, y = 7.5},
	fonts = {
		base = love.graphics.newFont("Assets/Fonts/aseprite.ttf", 7),
		timer = love.graphics.newImageFont("Assets/Sprites/TimerFont.png", " 0123456789/")
	},
	baseTileSize = 40,
	maxtime = 360,
	maxhp = 60
}