---@class Game: Object
Game = Object:extend()

function Game:new()
	self.timer = 0
	self.glyphs = {}
	self.drawinfo = {}
	self.events = {}
	self.currentID = 0
	self.flags = {}
	self.I = {
		MOVEABLES = {},
		SPRITES = {}
	}
	self.audio = {
		sfx = {},
		music = {},
		musicHandler = {}
	}
	self.debug = {
		drawWorldGrid = false,
		drawIsoGrid = true,
	}
	self.worldOffsetVector = Vector(0,0)
	self.settings = {
		fullscreen = false,
		sound = {
			master = 100,
			music = 100,
			sfx = 100
		},
		keybinds = {
			up = { "w", "up" },
			down = { "s", "down" },
			left = { "a", "left" },
			right = { "d", "right" },
			select = { "z", "return" },
			cancel = { "x", "lshift", "rshift" },
			pause = { "c", "escape" }
		}
	}
	self.controller = {
		up = { pressed = false, held = false, released = false },
		down = { pressed = false, held = false, released = false },
		left = { pressed = false, held = false, released = false },
		right = { pressed = false, held = false, released = false },
		select = { pressed = false, held = false, released = false },
		cancel = { pressed = false, held = false, released = false },
		pause = { pressed = false, held = false, released = false },
	}
	self.mouseController = {
		{ pressed = false, held = false, released = false },
		{ pressed = false, held = false, released = false },
		{ pressed = false, held = false, released = false },
	}
	G = self
	return self
end
function Game:update(dt)
	self.timer = self.timer + dt

	-- Misc
	-- Controller
	for k, v in pairs(self.controller) do
		if (function()
				for kk, vv in pairs(G.settings.keybinds[k]) do
					if type(vv) ~= "table" then
						if love.keyboard.isDown(vv) then
							return true
						end
					else
						local bool = true
						for kkk, vvv in pairs(vv) do
							if not love.keyboard.isDown(vvv) then
								bool = false
							end
						end
						return bool
					end
				end
				return false
			end)() then
			v.held = true
			if not v.pressTemp then
				v.pressed = true
				v.pressTemp = true
			else
				v.pressed = false
			end
		else
			if v.held then
				v.released = true
			else
				v.released = false
			end
			v.held = false
			v.pressed = false
			v.pressTemp = nil
		end
	end
	-- Mouse Controller
	for k, v in pairs(self.mouseController) do
		if love.mouse.isDown(k) then
			v.held = true
			if not v.pressTemp then
				v.pressed = true
				v.pressTemp = true
			else
				v.pressed = false
			end
		else
			if v.held then
				v.released = true
			else
				v.released = false
			end
			v.held = false
			v.pressed = false
			v.pressTemp = nil
		end
	end
	-- Sounds
	-- Sfx
	for i, v in ipairs(self.audio.sfx) do
		if not v.source:isPlaying() and not v.no_delete then
			v.source:release()
			self.audio.sfx[i] = nil
		end
	end
	self.audio.sfx = Util.Other.removeNils(self.audio.sfx)

	-- Music
	local targetBgm = Util.Audio.getHighestPriorityMusic() --self.audio.music[#self.audio.music]
	local previousBgm = self.audio.musicHandler.previousBgm
	for i, v in ipairs(self.audio.music) do
		if v.priority < targetBgm.priority and v.source:isPlaying() then
			v.source:pause()
		end
	end
	if targetBgm then
		if previousBgm and previousBgm ~= targetBgm and previousBgm.group == targetBgm.group then
			targetBgm.source:seek(previousBgm.source:tell('seconds'), 'seconds')
		end
		local source = targetBgm.source
		if not source:isPlaying() then
			if type(targetBgm.endFunc) == "function" then
				targetBgm.endFunc()
				Util.Audio.musicPop(targetBgm.id)
			end
		end
		source:setVolume(targetBgm.volume * G.settings.sound.music / 100 * G.settings.sound.master / 100)
	end
	self.audio.musicHandler.previousBgm = targetBgm
	-- Handling Events
	for k, queue in pairs(self.events) do
		event = queue[1]
		if not event.paused then
			event.curTime = event.curTime or 0
			if event.easeFunc then
				event.easeFunc(event.curTime / event.duration, event)
			end
			event.curTime = event.curTime + dt
			if event.curTime > event.duration then
				if event.endFunc then event.endFunc(event) end
				table.remove(queue, 1)
				if not next(queue) then
					self.events[k] = nil
				end
			end
		end
	end

	-- preportions
	local actualHeight, actualWidth = love.graphics.getHeight(), love.graphics.getWidth()
	local actualPreportion = actualHeight / actualWidth
	local idealPreportion = Macros.screenDimentions.y / Macros.screenDimentions.x
	local idealHeight, idealWidth
	if actualPreportion > idealPreportion then
		idealWidth = actualWidth
		idealHeight = idealWidth / Macros.screenDimentions.x * Macros.screenDimentions.y
	else
		idealHeight = actualHeight
		idealWidth = idealHeight / Macros.screenDimentions.y * Macros.screenDimentions.x
	end
	self.drawinfo.gridUnit = idealHeight / Macros.screenDimentions.y / Macros.gridSingleSubdivision
	self.drawinfo.origin = { x = (actualWidth - idealWidth) / 2, y = (actualHeight - idealHeight) / 2 }
	self.drawinfo.gridSize = {x = idealWidth, y = idealHeight}
	local union = {}
	for k, v in pairs(self.I.MOVEABLES) do
		table.insert(union,v)
	end
	for k, v in pairs(self.I.SPRITES) do
		table.insert(union, v)
	end
	local function updateAllObjects(filter)
		local max_update_order = -math.huge
		local updated_object
		local updated_k
		for k, v in pairs(union) do
			if v.updateOrder > max_update_order and not filter[k] then
				max_update_order = v.updateOrder
				updated_object = v
				updated_k = k
			end
		end
		if updated_k then
			filter[updated_k] = true
			updated_object:update(dt)
			updateAllObjects(filter)
		end
	end
	updateAllObjects({})
end

function Game:draw()
	-- preportions
	local actualHeight, actualWidth = love.graphics.getHeight(), love.graphics.getWidth()
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(Macros.colors.white)
	love.graphics.rectangle("fill", 0, 0, actualWidth, actualHeight)
	local Table = {}
	for _, v in pairs(self.I.MOVEABLES) do
		table.insert(Table, v)
	end
	for _, queue in pairs(self.events) do
		for _, v in pairs(queue) do
			table.insert(Table, v)
		end
	end
	for _, v in pairs(self.I.SPRITES) do
		table.insert(Table, v)
	end
	table.sort(Table, function(a, b)
		return (a.drawOrder < b.drawOrder)
	end)
	for _, v in ipairs(Table) do
		if v.type == "event" then
			v.drawFunc(v.curTime / v.duration, v)
		else
			v:draw()
		end
	end
	local actualPreportion = actualHeight / actualWidth
	local idealPreportion = Macros.screenDimentions.y / Macros.screenDimentions.x
	local idealHeight, idealWidth
	if actualPreportion > idealPreportion then
		idealWidth = actualWidth
		idealHeight = idealWidth / Macros.screenDimentions.x * Macros.screenDimentions.y
	else
		idealHeight = actualHeight
		idealWidth = idealHeight / Macros.screenDimentions.y * Macros.screenDimentions.x
	end
	if self.debug.drawWorldGrid then
		love.graphics.setColor(Macros.colors.red)
		for i = 1, Macros.screenDimentions.x * Macros.gridSingleSubdivision do
			for j = 1, Macros.screenDimentions.y * Macros.gridSingleSubdivision do
				love.graphics.rectangle("line", self.drawinfo.origin.x + (i - 1) * self.drawinfo.gridUnit,
					self.drawinfo.origin.y + (j - 1) * self.drawinfo.gridUnit, self.drawinfo.gridUnit,
					self.drawinfo.gridUnit)
			end
		end
	end
	if actualPreportion > Macros.screenStretchTolerance.max then
		love.graphics.setColor(Macros.colors.night)
		love.graphics.rectangle("fill", 0, 0, actualWidth, (actualHeight - actualWidth) / 2)
		love.graphics.rectangle("fill", 0, (actualHeight - actualWidth) / 2 + actualWidth, actualWidth, (actualHeight - actualWidth) / 2)
		love.graphics.setColor(Macros.colors.white)
		love.graphics.rectangle("fill", 0, (actualHeight - actualWidth) / 2 - 4, actualWidth, 2)
		love.graphics.rectangle("fill", 0, (actualHeight - actualWidth) / 2 + actualWidth + 2, actualWidth, 2)
	end
	if actualPreportion < Macros.screenStretchTolerance.min then
		love.graphics.setColor(Macros.colors.night)
		love.graphics.rectangle("fill", 0, 0, (actualWidth -  2 * actualHeight) / 2, actualHeight)
		love.graphics.rectangle("fill", (actualWidth - 2 * actualHeight) / 2 + 2 * actualHeight, 0, (actualWidth -  2 * actualHeight) / 2, actualHeight)
		love.graphics.setColor(Macros.colors.white)
		love.graphics.rectangle("fill", (actualWidth - 2 * actualHeight) / 2 - 4, 0, 2, actualHeight)
		love.graphics.rectangle("fill", (actualWidth - 2 * actualHeight) / 2 + 2 * actualHeight + 2, 0, 2, actualHeight)
	end
	love.graphics.setColor { r, g, b, a }
	local t = AdvancedText("|c:red|Penis")
	t:draw(2,2, true, true, Macros.colors.blue)
end

Game()