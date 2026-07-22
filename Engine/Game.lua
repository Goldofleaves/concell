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
	G = self
	return self
end
function Game:update(dt)
	self.timer = self.timer + dt

	-- Misc

	-- Handling Events
	for k, event in ipairs(self.events) do
		if not event.paused then
			event.curTime = event.curTime or 0
			if event.easeFunc then
				event.easeFunc(event.curTime / event.duration, event)
			end
			event.curTime = event.curTime + dt
			if event.curTime > event.duration then
				if event.endFunc then event.endFunc(event) end
				self.events[k] = nil
			end
		end
	end

	self.events = Util.Other.removeNils(self.events)

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
	for _, v in pairs(self.events) do
		table.insert(Table, v)
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
end

Game()