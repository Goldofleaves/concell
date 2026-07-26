---@class Game: Object
Game = Object:extend()

function Game:new()
	self.timer = 0
	self.glyphs = {}
	self.drawinfo = {
		gridUnit = 40,
		origin = {x = 0, y = 0},
		gridSize = {x=800,y=600},
		supergridSize = {x = 1200, y = 800}
	}
	self.dispOffset = {
		x = {},
		y = {},
	}
	self.events = {}
	self.currentID = 0
	self.flags = {
		saveData = {
			timer = 0,
			hp = 60,
			gridsPerMove = 3,
			items = {},
			playerPos = {
				x = 0,
				y = 0
			},
			timemod = 0,
			igt = 0,
			enemiesSlain = 0,
			nextItemDropAt = love.math.random(4, 6),
			nextPickupId = 1,
			totalDamage = 0
		}
	}
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
		drawIsoGrid = false,
		console = false,
		constext = ""
	}
	self.worldOffsetVector = Vector(0,0)
	self.mouseController = {
		{ pressed = false, held = false, released = false },
		{ pressed = false, held = false, released = false },
		{ pressed = false, held = false, released = false },
	}
	self.mousepos = {
		oldx = 0, oldy = 0,
		x = 0, y = 0
	}
	G = self
	return self
end
function Game:update(dt)
	self.mousepos.x, self.mousepos.y = Util.UI.convertUIPosToPos(love.mouse.getX(), love.mouse.getY())
	love.graphics.setLineWidth(1.5 * Util.UI.getScalingFactor())
	self.timer = self.timer + dt
	self.flags.saveData.igt = self.flags.saveData.igt + dt

	-- Misc
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
			source:play()
		end
		source:setVolume(targetBgm.volume)
	end
	if self.audio.musicHandler.previousBgm and self.audio.musicHandler.previousBgm.delete then
		self.audio.musicHandler.previousBgm.source:stop()
		self.audio.musicHandler.previousBgm.source:release()
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
	self.drawinfo.gridSize = { x = idealWidth, y = idealHeight }
	self.drawinfo.supergridSize = { x = 30 * self.drawinfo.gridUnit, y = 20 * self.drawinfo.gridUnit }
	self.drawinfo.superorigin = { x = self.drawinfo.origin.x - self.drawinfo.gridUnit * 5, y = self.drawinfo.origin.y -
	self.drawinfo.gridUnit * 2.5 }
	local union = {}
	for k, v in pairs(self.I.MOVEABLES) do
		table.insert(union,v)
	end
	for k, v in pairs(self.I.SPRITES) do
		table.insert(union, v)
	end
	local filter = {}
	::start::
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
		goto start
	end
	for k, v in ipairs(G.flags.saveData.items) do
		Centers[v.key].update(v)
		if v.isBeingUsed then
			Centers[v.key].IBUupdate(v)
		end
	end
	self.mousepos.oldx, self.mousepos.oldy = Util.UI.convertUIPosToPos(love.mouse.getX(), love.mouse.getY())
end
love.keyboard.setTextInput(true)
function love.textinput(t)
	if G.debug.console then
		G.debug.constext = G.debug.constext .. t
	end
end

local function getDirectionalItemTarget(direction)
	local bestTarget
	local bestAlignment = -math.huge
	local bestDistance = math.huge
	for _, target in ipairs(TARGETED_ENEMIES or {}) do
		local dx = target.TMod.x.base - PLAYER.TMod.x.base
		local dy = target.TMod.y.base - PLAYER.TMod.y.base
		local distance = math.sqrt(dx * dx + dy * dy)
		if distance > 0 then
			local alignment = (dx * direction[1] + dy * direction[2]) / distance
			if alignment >= 0.5
				and (alignment > bestAlignment + 0.0001
					or math.abs(alignment - bestAlignment) <= 0.0001
					and distance < bestDistance)
			then
				bestTarget = target
				bestAlignment = alignment
				bestDistance = distance
			end
		end
	end
	return bestTarget
end

function love.keypressed(key)
	if key == "backspace" and G.debug.console then
		G.debug.constext = string.sub(G.debug.constext, 1, -2)
	end
	if key == "k" then
		G.debug.console = not G.debug.console
	end
	if key == "l" then
		for i = 1, 7 do
			local char = string.char(string.byte("a")+i)
			if not G.flags.saveData.rooms[char] then
				print(i)
				local index = string.char(string.byte("a") + i - 1)
				G.flags.saveData.curRoomIndex = index
				G.flags.saveData.curRoom = G.flags.saveData.rooms[index]

				getObjectByNid("isoGrid"):remove()
				getObjectByNid("isoGridWeb"):remove()
				Macros.MDef.isometricGrid(G.flags.saveData.curRoom.size.w, G.flags.saveData.curRoom.size.h,
					Util.World.getArea(index))
				local list = {}
				for k, v in ipairs(G.I.MOVEABLES) do
					if v.objectType == "WORLDMOVEABLE" then
						table.insert(list, v)
					end
				end
				for k, v in ipairs(list) do
					v:remove()
				end
				PLAYER = WorldMoveable({
					x = 0,
					y = 1,
					type = "player",
					drawOrder = 31,
					updateOrder = 1,
					extra = { facing = "1" }
				})
				WorldMoveable:initRoomStuff()
				WorldMoveable:checkEaseMusic()
				break
			end
		end
	end
	if key == "g" then
		Util.World.gameWin()
	end
	if key == "u" then
		Util.World.gameOver()
	end
	if key == "r"
		and not G.debug.console
		and love.keyboard.isDown("lctrl", "rctrl")
	then
		if not Util.World.debugRegenerateCurrentRoom() then
			print("[DEBUG] Current room cannot be regenerated right now")
		end
	end
	if key == "t"
		and not G.debug.console
		and love.keyboard.isDown("lctrl", "rctrl")
	then
		if not Util.World.debugJumpToAreaTransition() then
			print("[DEBUG] Cannot jump to this area's transition room right now")
		end
	end
	if key == "return" and G.debug.console then
		if string.sub(G.debug.constext,1,1) == "=" then
			G.debug.constext = "return ".. string.sub(G.debug.constext, 2, #G.debug.constext)
		end
		local func, err = load(G.debug.constext)
		G.debug.constext = ""
		if func then
			local suc, res = pcall(func)
			print(res)
		else
			print(err)
		end
	end

	if G.debug.console or G.flags.isMoving or getEventByNid("transition") then
		return
	end

	local grid = getObjectByNid("isoGridWeb")
	local moveButton = getObjectByNid("MoveButton")
	local cancelButton = getObjectByNid("CancelButton")
	if not grid or not PLAYER or not moveButton then
		return
	end

	local directions = {
		up = { -1, 0 },
		right = { 0, -1 },
		down = { 1, 0 },
		left = { 0, 1 },
	}
	local itemSlots = {
		["1"] = 1,
		["2"] = 2,
		["3"] = 3,
		["4"] = 4,
		kp1 = 1,
		kp2 = 2,
		kp3 = 3,
		kp4 = 4,
	}
	local unLoadItemSlots = {
		["f1"] = 1,
		["f2"] = 2,
		["f3"] = 3,
		["f4"] = 4,
	}
	local itemSlot = itemSlots[key]
	local unLoadItemSlot = unLoadItemSlots[key]
	local direction = directions[key]
	if itemSlot then
		local itemButton = getObjectByNid("itemButton"..itemSlot)
		if itemButton then
			itemButton:onClick()
		end
	elseif unLoadItemSlot then
		local itemButton = getObjectByNid("itemButton" .. itemSlot)
		if itemButton then
			itemButton:onRightClick()
		end
	elseif direction and TARGETED_ENEMIES then
		local target = getDirectionalItemTarget(direction)
		if target then
			useActiveItemOnTarget(target)
		end
	elseif direction and grid.extra.tryPlanMove then
		grid.extra.tryPlanMove(grid, direction[1], direction[2])
	elseif (key == "return" or key == "kpenter" or key == "space") --[[and #grid.extra.path > 1]] then
		moveButton:onClick()
	-- elseif key == "space" and #grid.extra.path == 1 then
	-- 	moveButton:onClick()
	elseif (key == "c" and #grid.extra.path > 0) then
		cancelButton:onClick()
	elseif key == "f5" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function Game:draw()
	local shiftx, shifty = 0, 0
	for k, v in pairs(self.dispOffset.x) do
		shiftx = shiftx + v
	end
	for k, v in pairs(self.dispOffset.y) do
		shifty = shifty + v
	end
	love.graphics.translate(shiftx, shifty)
	-- preportions
	local actualHeight, actualWidth = love.graphics.getHeight(), love.graphics.getWidth()
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(Macros.colors.lightBlack)
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
	love.graphics.origin()
	if self.debug.drawWorldGrid then
		love.graphics.setColor(Util.Color.SetOpacity(Macros.colors.red, 0.15))
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
	if G.debug.console then
		local t = AdvancedText("|s:3,3||c:red|"..G.debug.constext)
		t:draw(1,1, true)
	end
end

Game()
