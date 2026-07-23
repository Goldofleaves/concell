-- Ripped straight from BoS!
-- (You wouldnt believe how much of the codebase is from there. Seriously!)
-- (It's my project though, so its okay)
local function normalize_text(text, vars)
	vars = vars or {}
	for k, v in ipairs(vars) do
		local j
		if type(v) == "table" then
			j = v.ref_table[v.ref_value]
		else
			j = v
		end
		local pos1, pos2 = string.find(text, "{" .. k .. "}")
		if pos1 then
			text = string.sub(text, 1, pos1 - 1) .. tostring(j) .. string.sub(text, pos2 + 1, #text)
		end
	end
	local effects = {}
	local tex = ""
	local txtpos = 0
	local effecttext = ""
	local pairity = false
	for i = 1, #text do
		local char = string.sub(text, i, i)
		if not pairity then
			tex = tex .. char
			txtpos = txtpos + 1
		else
			effecttext = effecttext .. char
		end
		if char == "|" then
			if not pairity then
				tex = string.sub(tex, 1, #tex - 1)
				effecttext = effecttext .. "|"
			else
				txtpos = txtpos - 1
				effecttext = effecttext .. (txtpos)
			end
			pairity = not pairity
		end
	end
	local function get_amt_recurring_chars(t, char)
		local indices_table = {}
		for i = 1, #t do
			local c = string.sub(t, i, i)
			if c == char then
				table.insert(indices_table, i)
			end
		end
		return indices_table
	end
	local amount = get_amt_recurring_chars(effecttext, "|")
	for k, v in ipairs(amount) do
		local p = k % 2
		local prev = amount[k - 1]
		local next = amount[k + 1] or #effecttext + 1
		if p == 0 then
			local str = string.sub(effecttext, prev + 1, v - 1)
			local num = tonumber(string.sub(effecttext, v + 1, next - 1))
			effects[num + 1] = effects[num + 1] or {
				str = {},
				type = {},
				miscinfo = {}
			}
			table.insert(effects[num + 1].str, str)
			table.insert(effects[num + 1].type, string.sub(str, 1, 1))
			table.insert(effects[num + 1].miscinfo, string.sub(str, 3, #str))
		end
	end
	return { string = tex, effects = effects }
end

local function split_normalized_text_into_rows_of_textchars(normalized, width)
	local text = normalized.string
	local effects = normalized.effects
	local contentwords = {}
	local contentchars = {}
	local textstr = {}
	if true then
		local j = 0
		local f = 1
		local font = Macros.fonts.base
		for i = 1, #text do
			if effects[i] and effects[i].type == "f" then
				font = Macros.fonts[effects[i].miscinfo == "reset" and "base" or effects[i].miscinfo]
			end
			local char = string.sub(text, i, i)
			if char == " " then
				table.insert(textstr,
					{ len = j, segment = { start = f, terminate = i - 1 }, type = "word", contents = string.sub(text, f,
						i - 1) })
				table.insert(textstr,
					{ len = font:getWidth(" "), segment = { start = i, terminate = i }, type = "space", contents = " " })
				j = 0
				f = i + 1
			else
				j = j + font:getWidth(char)
			end
			if i == #text then
				table.insert(textstr,
					{ len = j, segment = { start = f, terminate = i }, type = "word", contents = string.sub(text, f, i) })
				break
			end
		end
	end
	if true then
		local length = 0
		local row = 1
		for _, content in ipairs(textstr) do
			local templength = length + content.len
			if templength > width then
				row = row + 1
				length = content.len
			else
				length = templength
			end
			contentwords[row] = contentwords[row] or {}
			table.insert(contentwords[row], content)
		end
	end
	for row, segment in ipairs(contentwords) do
		for _, word in ipairs(segment) do
			contentchars[row] = contentchars[row] or {}
			for i = 1, word.segment.terminate - word.segment.start + 1 do
				local chareffects = {}
				local highestnum = 1
				for k, _ in pairs(effects) do
					if k > highestnum then
						highestnum = k
					end
				end
				for g = 1, highestnum do
					effects[g] = effects[g] or {}
				end
				for k, v in ipairs(effects) do
					if k <= i + word.segment.start - 1 then
						if next(v) then
							for kk, vv in ipairs(v.type) do
								chareffects[vv] = { type = vv, str = v.str[kk], miscinfo = v.miscinfo[kk] }
							end
						end
					end
				end
				table.insert(contentchars[row],
					TextChar(string.sub(word.contents, i, i), chareffects, i + word.segment.start - 1))
			end
		end
	end
	return contentchars
end

---@class AdvancedText: Object
AdvancedText = Object:extend()
function AdvancedText:new(text, vars)
	if type(vars) ~= "table" then
		vars = {vars}
	end
	self.ogVars = { text = text, vars = Util.Other.copyTable(vars) }
	local normalized = normalize_text(text, vars)
	local contentChars = split_normalized_text_into_rows_of_textchars(normalized, 1e10)
	local cc = {}
	for k, v in ipairs(contentChars) do
		for kk, vv in ipairs(v) do
			table.insert(cc, vv)
		end
	end
	self.contents = cc
	self.progInfo = {
		currentChar = #cc,
		allChars = #cc
	}
	return self
end

function createTableOfAdvancedText(tt, vv)
	vv = vv or {}
	local a = {}
	for k, v in ipairs(tt) do
		table.insert(a, AdvancedText(v, vv[k]))
	end
	return a
end

function AdvancedText:getWidthUpToN(n)
	local width = 0
	for k, v in ipairs(self.contents) do
		if k <= n then
			width = v:getWidth() + width
		end
	end
	return width
end

function AdvancedText:getCurrentWidth()
	return self:getWidthUpToN(self.progInfo.currentChar)
end

function AdvancedText:getTotalWidth()
	return self:getWidthUpToN(self.progInfo.allChars)
end
function AdvancedText:getHeight()
	local height = 0
	for k, v in ipairs(self.contents) do
		height = math.max(height, v:getHeight())
	end
	return height
end

function AdvancedText:setTransparency(t)
	for k, v in ipairs(self.contents) do
		v.transparency = t
	end
end
function AdvancedText:getKthChar(k)
	return self.contents[k]
end

function AdvancedText:getCurrentChar()
	return self:getKthChar(self.progInfo.currentchar) or TextChar(" ", {})
end

function AdvancedText:recalculate(vars, text)
	if type(vars) ~= "table" and type(vars) ~= "nil" then
		vars = { vars }
	end
	local txt = text or self.ogVars.text
	local vvars = Util.Other.copyTable(self.ogVars.vars)
	self.ogVars = { text = txt, vars = vars or vvars }
	local normalized = normalize_text(txt, vars or vvars)
	local contentChars = split_normalized_text_into_rows_of_textchars(normalized, 1e10)
	local cc = {}
	for k, v in ipairs(contentChars) do
		for kk, vv in ipairs(v) do
			table.insert(cc, vv)
		end
	end
	self.contents = cc
	self.progInfo = {
		currentChar = #cc,
		allChars = #cc
	}
end

function AdvancedText:advance()
	self.progInfo.currentChar = math.min(self.progInfo.currentChar + 1, self.progInfo.allChars)
end

function AdvancedText:finish()
	self.progInfo.currentChar = self.progInfo.allChars
end

function AdvancedText:update()
	for k, v in ipairs(self.contents) do
		v:update()
	end
end

function AdvancedText:draw(x, y, UI, textbox, textboxColor, f)
	if UI then
		x, y = Util.UI.convertPosToUIPos(x, y)
	end
	f = f or 0
	if textbox then
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(textboxColor)
		love.graphics.rectangle("line", x - 2, y, self:getTotalWidth() + 2, self:getHeight())
		love.graphics.setColor(r, g, b, a)
	end
	for k, v in ipairs(self.contents) do
		if k <= self.progInfo.currentChar then
			v:draw(x + math.betterrandom() * f, y + math.betterrandom() * f)
			x = v:getWidth() + x
		end
	end
end

function AdvancedText:verticalLerpDraw(x, y, width, v)
	local offset_base = width * v
	local offset_text = self:getCurrentWidth() * v
	self:draw(x + offset_base - offset_text, y)
end
function AdvancedText:horizontalLerpDraw(x, y, height, v)
	local offset_base = height * v
	local offset_text = self:getHeight() * v
	self:draw(x, y + offset_base - offset_text)
end

function AdvancedText:lerpDraw(x, y, width, height, vw, vh)
	local w_offset_base = width * vw
	local w_offset_text = self:getCurrentWidth() * vw
	local h_offset_base = height * vh
	local h_offset_text = self:getHeight() * vh
	self:draw(x + w_offset_base - w_offset_text, y + h_offset_base - h_offset_text)
end
function AdvancedText:alignDraw(x, y, width, alignmode)
	self:verticalLerpDraw(x, y, width, alignmode == "left" and 0 or (alignmode == "center" and 1 / 2 or 1))
end

---@class TextChar: Object
TextChar = Object:extend()
function TextChar:new(char, effects, pos)
	--[[
	EFFECTS DOCUMENTATION:
	f:font, corresponding to a Macros.Font index
	c:color, with a following hex code/Macros.colors value.
	e:effect, with 3 types: wavy, shake, none
	j:stillness: normal, still
	t:text effects, with 2 types: randomized, normal
	s:scale(formatted like sx,sy), the scale of the textchar
	l:wait duration, self explanitory
	o:outline color, reset for none
	]]

	local function doesapply(v)
		return (v.miscinfo == "reset") or (v.miscinfo == nil)
	end
	local alleffs = {
		color = "white",
		font = Macros.fonts.base,
		effects = "none",
		stillness = "still",
		textEffects = "normal",
		textScale = {x = 1, y = 1},
		waitDuration = 1 / 10,
		outlineColor = false,
	}
	for k, v in pairs(effects) do
		if k == "c" then
			alleffs.color = doesapply(v) and "white" or v.miscinfo
		elseif k == "f" then
			alleffs.font = Macros.fonts[doesapply(v) and "base" or v.miscinfo]
		elseif k == "e" then
			alleffs.effects = doesapply(v) and "none" or v.miscinfo
		elseif k == "t" then
			alleffs.textEffects = doesapply(v) and "normal" or v.miscinfo
		elseif k == "j" then
			alleffs.stillness = doesapply(v) and "still" or v.miscinfo
		elseif k == "s" then
			alleffs.textScale = doesapply(v) and { x = 1, y = 1 } or
				{
					x = tonumber(string.sub(v.miscinfo, 1, ({ string.find(v.miscinfo, ",") })[1] - 1)),
					y = tonumber(string.sub(v.miscinfo, ({ string.find(v.miscinfo, ",") })[1] + 1, #v.miscinfo))
				}
		elseif k == "l" then
			alleffs.waitDuration = doesapply(v) and 1 / 10 or tonumber(v.miscinfo) or 1 / 10
		elseif k == "o" then
			alleffs.outlineColor = doesapply(v) and false or v.miscinfo
		end
	end
	self.char = char
	self.effects = alleffs
	self.other = {
		position = pos,
		waveVal = 0,
		displayChar = self.char,
		displacement = {
			x = 0,
			y = 0
		},
		waveDisplacement = {
			x = 0,
			y = 0
		}
	}
	self.transparency = 1
	return self
end

function TextChar:update()
	self.other.waveVal = G.timer + self.other.position
	self.other.waveDisplacement.y = math.sin(self.other.waveVal * 5) * 2
	local chancex = Util.Math.chance(self.effects.effects == "shake" and 2 / 6 or 1 / 24)
	local chancey = Util.Math.chance(self.effects.effects == "shake" and 2 / 6 or 1 / 24)
	local offsetVal = self.effects.effects == "shake" and 2 or self.effects.stillness == "still" and 0 or 1
	if chancex then
		self.other.displacement.x = (math.random(1, 2) == 1 and 1 or -1) * offsetVal
	else
		self.other.displacement.x = 0
	end
	if chancey then
		self.other.displacement.y = (math.random(1, 2) == 1 and 1 or -1) * offsetVal
	else
		self.other.displacement.y = 0
	end
	if self.effects.textEffects == "randomized" then
		local allChars = "QWERTYUIOPASDFGHJKLZXCCVBNMqwertyuiopasdfghjklzxcvbnm1234567890`~!@#$%^&*()_=+[]\\;',./<>?:\"|"
		local charPos = math.random(#allChars)
		local char = string.sub(allChars, charPos, charPos)
		self.other.displayChar = char
	else
		self.other.displayChar = self.char
	end
end

function TextChar:draw(x, y)
	local dispx, dispy =
	self.other.displacement.x + (self.effects.effects == "wavy" and self.other.waveDisplacement.x or 0),
		self.other.displacement.y + (self.effects.effects == "wavy" and self.other.waveDisplacement.y or 0)
	dispy = dispy + (self.effects.font == Macros.fonts.small and 2 or 0)
	local r, g, b, a = love.graphics.getColor()
	local sx = self.effects.textScale.x / 40 * G.drawinfo.gridUnit
	local sy = self.effects.textScale.y / 40 * G.drawinfo.gridUnit
	local ddx, ddy = x + dispx, y + dispy
	if self.effects.outlineColor then
		local color = Macros.colors[self.effects.outlineColor] or Util.Other.hex(self.effects.outlineColor)
		love.graphics.setColor { color[1], color[2], color[3], self.transparency * color[4] }
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx + 1, ddy, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx - 1, ddy, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx, ddy + 1, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx, ddy - 1, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx + 1, ddy + 1, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx - 1, ddy - 1, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx - 1, ddy + 1, 999, 'left', 0, sx, sy)
		love.graphics.printf(self.other.displayChar, self.effects.font,ddx + 1, ddy - 1, 999, 'left', 0, sx, sy)
	end
	local color = Macros.colors[self.effects.color] or Util.Other.hex(self.effects.color)
	love.graphics.setColor{color[1], color[2], color[3], self.transparency * color[4]}
	love.graphics.printf(self.other.displayChar, self.effects.font, ddx, ddy,
	999, 'left', 0, sx, sy)
	love.graphics.setColor { r, g, b, a }
end

function TextChar:getWidth()
	return self.effects.font:getWidth(self.char) * self.effects.textScale.x / 40 * G.drawinfo.gridUnit
end
function TextChar:getHeight()
	return (self.effects.font == Macros.fonts.base and (self.effects.font:getHeight(self.char) + 2) * self.effects.textScale.y or self.effects.font:getHeight(self.char) * self.effects.textScale.y) / 40 * G.drawinfo.gridUnit
end