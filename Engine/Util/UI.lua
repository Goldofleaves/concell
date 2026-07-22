Util.UI = {}
function Util.UI.convertPosToUIPos(x, y)
	return x * G.drawinfo.gridUnit + G.drawinfo.origin.x, y * G.drawinfo.gridUnit + G.drawinfo.origin.y
end
function Util.UI.convertUIPosToPos(x, y)
	return (x - G.drawinfo.origin.x) / G.drawinfo.gridUnit, (y - G.drawinfo.origin.y) / G.drawinfo.gridUnit
end
---comment
---@param entries table
---@param info table?
---@param extra {orientation:"horizontal"|"vertical", interactable:boolean|nil}?
---@return Moveable
Util.UI.CreatePagedList = function(entries, info, extra)
	info = info or {}
	extra = extra or {}
	local entryMoveables = {}
	for i, v in ipairs(entries) do
		local m = v.init()
		if m then
			table.insert(entryMoveables, m)
		end
	end
	local m = info
	m.extra = m.extra or {}
	m.extra.curPage = 1
	m.extra.max = #entries
	m.extra.entries = entries
	m.extra.entryMoveables = entryMoveables
	m.properties = m.extra.properties or {}
	m.properties.isPagedList = true
	m.properties.interactable = extra.interactable or true
	m.extra.inMenu = false
	local old = m.updateFunc
	m.updateFunc = function(self, dt)
		if type(old) == "function" then
			old(self, dt)
		end
		if self.properties.interactable then
			for i = 1, m.extra.max do
				self.extra.entryMoveables[i].properties.interactable = i == self.extra.curPage
			end
			if not self.extra.inMenu then
				if G.controller[extra.orientation == "horizontal" and "left" or "up"].pressed then
					self.extra.curPage = Util.Math.clamp(1, self.extra.max, self.extra.curPage - 1)
					Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
				end
				if G.controller[extra.orientation == "horizontal" and "right" or "down"].pressed then
					self.extra.curPage = Util.Math.clamp(1, self.extra.max, self.extra.curPage + 1)
					Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
				end
			end
		end
	end
	local moveable = Moveable(m)
	for k, v in pairs(moveable.extra.entryMoveables) do
		v.master = moveable
	end
	return moveable
end
Util.UI.CreateList = function(entries, info, extra)
	info = info or {}
	extra = extra or {}
	local entryMoveables = {}
	for i, v in ipairs(entries) do
		table.insert(entryMoveables, v.init())
	end
	local m = info
	m.extra = m.extra or {}
	m.extra.curOption = 1
	m.extra.max = #entries
	m.extra.entries = entries
	m.extra.entryMoveables = entryMoveables
	m.extra.inMenu = false
	m.properties = m.extra.properties or {}
	m.properties.isList = true
	m.properties.interactable = extra.interactable or true
	local old = m.updateFunc
	m.updateFunc = function(self, dt)
		if type(old) == "function" then
			old(self, dt)
		end
		if self.properties.interactable then
			for i = 1, m.extra.max do
				self.extra.entryMoveables[i].properties.state = (i == self.extra.curOption and (self.extra.entryMoveables[i].properties.state == "targeted" and "targeted" or "selected") or "idle")
			end
			if not self.extra.inMenu then
				if G.controller[extra.orientation == "horizontal" and "left" or "up"].pressed then
					self.extra.curOption = Util.Math.clamp(1, self.extra.max, self.extra.curOption - 1)
					Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
				end
				if G.controller[extra.orientation == "horizontal" and "right" or "down"].pressed then
					self.extra.curOption = Util.Math.clamp(1, self.extra.max, self.extra.curOption + 1)
					Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
				end
				if G.controller.select.pressed then
					if not G.flags.listInitiation then
						Util.Audio.playSfx("Select", 0.3, math.random() * 0.5 + 0.75)
						self.extra.entryMoveables[self.extra.curOption].properties.state = "targeted"
						self.extra.inMenu = true
						if self.master then
							self.master.extra.inMenu = true
						end
					else
						G.flags.listInitiation = nil
					end
				end
			end
		end
	end
	local moveable = Moveable(m)
	for k, v in pairs(moveable.extra.entryMoveables) do
		v.master = moveable
	end
	return moveable
end

function Util.UI.CreateSlider(info, text, rTab, rVal, min, max, extra)
	extra = extra or {}
	extra.dispFunc = type(extra.dispFunc) ~= "function" and function(a)
		return a
	end or extra.dispFunc
	local m = info
	m.extra = m.extra or {}
	m.extra.text = AdvancedText(text.text, { extra.dispFunc(rTab[rVal]) })
	m.extra.textSelected = AdvancedText(text.textSelected, { extra.dispFunc(rTab[rVal]) })
	m.extra.textTargeted = AdvancedText(text.textTargeted, { extra.dispFunc(rTab[rVal]) })
	m.extra.t = 0
	m.extra.tick = extra.tick or (1 / 25)
	m.extra.transparency = 1
	local old = m.updateFunc
	m.drawFunc = function(s)
		local pageObj = s.master
		if pageObj.properties.interactable then
			if s.properties.state == "targeted" then
				s.extra.textTargeted:draw(s.T.x, s.T.y)
			elseif s.properties.state == "selected" then
				s.extra.textSelected:draw(s.T.x, s.T.y)
			else
				s.extra.text:draw(s.T.x, s.T.y)
			end
		end
		s.extra.text:setTransparency(s.extra.transparency)
		s.extra.textSelected:setTransparency(s.extra.transparency)
		s.extra.textTargeted:setTransparency(s.extra.transparency)
	end
	m.updateFunc = function(s, dt)
		if type(old) == "function" then
			old(s, dt)
		end
		local function recalcText()
			s.extra.text:recalculate({ extra.dispFunc(rTab[rVal]) })
			s.extra.textSelected:recalculate({ extra.dispFunc(rTab[rVal]) })
			s.extra.textTargeted:recalculate({ extra.dispFunc(rTab[rVal]) })
		end
		if s.properties.state == "targeted" then
			if G.controller.left.held and not G.controller.right.held then
				if s.extra.t <= 0 then
					s.extra.t = s.extra.tick
					rTab[rVal] = Util.Math.clamp(min, max, rTab[rVal] - 1)
					recalcText()
					if rTab[rVal] ~= min then
						Util.Audio.playSfx("SliderSound1", 0.3, math.random() * 0.5 + 0.75)
					end
				end
			end
			if G.controller.right.held and not G.controller.left.held then
				if s.extra.t <= 0 then
					s.extra.t = s.extra.tick
					rTab[rVal] = Util.Math.clamp(min, max, rTab[rVal] + 1)
					recalcText()
					if rTab[rVal] ~= max then
						Util.Audio.playSfx("SliderSound1", 0.3, math.random() * 0.5 + 0.75)
					end
				end
			end
			s.extra.t = math.max(s.extra.t - dt, -0.02)
			if G.controller.cancel.pressed then
				Util.Audio.playSfx("Deselect", 0.3, math.random() * 0.5 + 0.75)
				s.master.extra.inMenu = false
				local v = s.master
				while v.master do
					v = v.master
					v.extra.inMenu = false
				end
				s.properties.state = "selected"
			end
		end
	end
	return Moveable(m)
end

function Util.UI.CreateOption(info, text, rTab, rVal, values, extra)
	extra = extra or {}
	extra.dispFunc = type(extra.dispFunc) ~= "function" and function(a)
		return a
	end or extra.dispFunc
	local m = info
	m.extra = m.extra or {}
	m.extra.text = AdvancedText(text.text, { extra.dispFunc(rTab[rVal]) })
	m.extra.textSelected = AdvancedText(text.textSelected, { extra.dispFunc(rTab[rVal]) })
	m.extra.textTargeted = AdvancedText(text.textTargeted, { extra.dispFunc(rTab[rVal]) })
	m.extra.curOption = 1
	m.extra.transparency = 1
	for k, v in pairs(values) do
		if rTab[rVal] == v then
			m.extra.curOption = k
		end
	end
	local max = #values
	local old = m.updateFunc
	m.drawFunc = function(s)
		local pageObj = s.master
		if pageObj.properties.interactable then
			if s.properties.state == "targeted" then
				s.extra.textTargeted:draw(s.T.x, s.T.y)
			elseif s.properties.state == "selected" then
				s.extra.textSelected:draw(s.T.x, s.T.y)
			else
				s.extra.text:draw(s.T.x, s.T.y)
			end
		end
		s.extra.text:setTransparency(s.extra.transparency)
		s.extra.textSelected:setTransparency(s.extra.transparency)
		s.extra.textTargeted:setTransparency(s.extra.transparency)
	end
	m.updateFunc = function(s, dt)
		if type(old) == "function" then
			old(s)
		end
		local function recalcText()
			s.extra.text:recalculate({ extra.dispFunc(rTab[rVal]) })
			s.extra.textSelected:recalculate({ extra.dispFunc(rTab[rVal]) })
			s.extra.textTargeted:recalculate({ extra.dispFunc(rTab[rVal]) })
		end
		if s.properties.state == "targeted" then
			if G.controller.left.pressed then
				s.extra.curOption = Util.Math.clamp(1, max, s.extra.curOption - 1)
				rTab[rVal] = values[s.extra.curOption]
				recalcText()
				Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
			end
			if G.controller.right.pressed then
				s.extra.curOption = Util.Math.clamp(1, max, s.extra.curOption + 1)
				rTab[rVal] = values[s.extra.curOption]
				recalcText()
				Util.Audio.playSfx("MenuSwitchSubjects", 0.3, math.random() * 0.5 + 0.75)
			end
			if G.controller.cancel.pressed then
				Util.Audio.playSfx("Deselect", 0.3, math.random() * 0.5 + 0.75)
				s.master.extra.inMenu = false
				local v = s.master
				while v.master do
					v = v.master
					v.extra.inMenu = false
				end
				s.properties.state = "selected"
			end
		end
	end
	return Moveable(m)
end

function Util.UI.CreateButton(info, text, fun, extra)
	local m = info
	m.extra = m.extra or {}
	m.extra.text = AdvancedText(text.text)
	m.extra.textSelected = AdvancedText(text.textSelected)
	m.extra.textTargeted = AdvancedText(text.textTargeted)
	m.extra.curOption = 1
	m.extra.transparency = 1
	local old = m.updateFunc
	m.drawFunc = function(s)
		local pageObj = s.master
		if pageObj.properties.interactable then
			if s.properties.state == "targeted" then
				s.extra.textTargeted:draw(s.T.x, s.T.y)
			elseif s.properties.state == "selected" then
				s.extra.textSelected:draw(s.T.x, s.T.y)
			else
				s.extra.text:draw(s.T.x, s.T.y)
			end
		end
		s.extra.text:setTransparency(s.extra.transparency)
		s.extra.textSelected:setTransparency(s.extra.transparency)
		s.extra.textTargeted:setTransparency(s.extra.transparency)
	end
	m.updateFunc = function(s, dt)
		if type(old) == "function" then
			old(s)
		end
		if s.properties.state == "targeted" then
			local a = fun(s)
			Util.Audio.playSfx("Select", 0.3, math.random() * 0.5 + 0.75)
			if type(a) ~= "table" or a.exit then
				s.master.extra.inMenu = false
				local v = s.master
				while v.master do
					v = v.master
					v.extra.inMenu = false
				end
			end
			s.properties.state = "selected"
		end
	end
	return Moveable(m)
end
