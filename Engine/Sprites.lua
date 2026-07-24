--- Sprite objects.

Atlases = {}
function registerAtlasSimple(key, fpos, px, py)
	if not Atlases[key] then
		Atlases[key] = {}
		local atli = Atlases[key]
		atli.imageData = love.image.newImageData(fpos)
		atli.image = love.graphics.newImage(atli.imageData)
		local spritewidth, spriteheight = atli.image:getWidth(), atli.image:getHeight()
		local Xsegments, Ysegments = spritewidth / px, spriteheight / py
		atli.key = key
		atli.filePos = fpos
		atli.splicedImages = {}
		atli.dimentions = { w = spritewidth, h = spriteheight }
		atli.singleDimention = { w = px, h = py }
		atli.size = { x = Xsegments, y = Ysegments }
		for i = 0, Xsegments - 1 do
			atli.splicedImages[i] = atli.splicedImages[i] or {}
			for j = 0, Ysegments - 1 do
				atli.splicedImages[i][j] = love.graphics.newQuad(math.floor(i * px), math.floor(j * py), math.floor(px),
					math.floor(py), math.floor(spritewidth), math.floor(spriteheight))
			end
		end
		print(
			string.format('[IMAGE INFO/REGISTER ATLAS] \'%s\' has been registered.', key)
		)
		return Atlases[key]
	else
		print(
			string.format('[IMAGE WARNING/REGISTER ATLAS] \'%s\' is already registered!', key)
		)
	end
end

---@class Sprite: Object
Sprite = Object:extend()

function Sprite:new(args)
	args = args or {}
	self.id = G.currentID
	self.nid = args.nid
	G.currentID = G.currentID + 1
	self.T = {
		x = args.x or 0,
		y = args.y or 0,
	}
	self.objectType = 'SPRITE'
	self.transparency = args.transparency or 1
	self.atlasInfo = {
		key = args.atlasKey,
		x = args.atlasX or 0,
		y = args.atlasY or 0
	}
	self.updateFunc = args.updateFunc or function(s, dt) return end
	self.updateOrder = args.updateOrder or 1
	self.drawOrder = args.drawOrder or 1
	self.drawTiled = args.drawTiled == nil and false or args.drawTiled
	self.extra = args.extra or {}
	self.drawFunc = args.drawFunc or function(s) return end
	self.mask = {
		ShouldApply = args.MaskShouldApply == nil and false or args.MaskShouldApply,
		ImageFpos = args.MaskImageFpos,
	}
	self.properties = args.properties or {}
	table.insert(G.I.SPRITES, self)
	self.offset = {
		x = args.offsetX or 0,
		y = args.offsetY or 0
	}
	self.scale = {
		x = args.scaleX or 1,
		y = args.scaleY or 1,
	}
	self.center = {
		x = args.centerX or 0,
		y = args.centerY or 0
	}
	self.rotation = args.rotation or 0
	self.worldCoords = args.worldCoords == nil and true or args.worldCoords
	return self
end

function Sprite:draw()
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor { 1, 1, 1, 1 }
	local draw_func = function(kx, ky)
		local x, y = self.T.x + kx, self.T.y + ky
		if self.worldCoords then
			x, y = Util.UI.convertPosToUIPos(self.T.x + kx, self.T.y + ky)
		end
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor { r, g, b, a * self.transparency }
		if self.mask.ShouldApply then
			self.extra = self.extra or {}
			self.extra.mask = self.extra.mask or love.graphics.newImage(self.mask.ImageFpos)
			self.extra.mask_shader = self.extra.mask_shader or love.graphics.newShader [[
				   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
					  if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
						 // a discarded pixel wont be applied as the stencil.
						 discard;
					  }
					  return vec4(1.0);
				   }
				]]
			local function myStencilFunction()
				love.graphics.setShader(self.extra.mask_shader)
				love.graphics.draw(self.extra.mask, 0, 0)
				love.graphics.setShader()
			end
			love.graphics.stencil(myStencilFunction, "replace", 1)
			love.graphics.setStencilTest("greater", 0)
		end
		if not self.drawTiled then
			local scalex = self.scale.x * Util.UI.getScalingFactor()
			local scaley = self.scale.y * Util.UI.getScalingFactor()
			local xcenter, ycenter = self.center.x * Atlases[self.atlasInfo.key].singleDimention.w * scalex,
			self.center.y * Atlases[self.atlasInfo.key].singleDimention.h * scaley
			local rot = Util.Math.rotatePointAroundOrigin(-xcenter, -ycenter, self.rotation)
			local rotationoffsetx, rotationoffsety = rot.x + xcenter, rot.y + ycenter
			local scaleoffsetx, scaleoffsety =
			(1 - scalex) * self.center.x * Atlases[self.atlasInfo.key].singleDimention.w,
			(1 - scaley) * self.center.y * Atlases[self.atlasInfo.key].singleDimention.h
			love.graphics.draw(
				Atlases[self.atlasInfo.key].image, Atlases[self.atlasInfo.key].splicedImages[self.atlasInfo.x][self.atlasInfo.y],
				x + rotationoffsetx + scaleoffsetx, y + rotationoffsety + scaleoffsety,
				self.rotation, scalex, scaley
			)
		else
			local scalex = self.scale.x * Util.UI.getScalingFactor()
			local scaley = self.scale.y * Util.UI.getScalingFactor()
			local moduloX = x % Atlases[self.atlasInfo.key].singleDimention.w * scalex
			local moduloY = y % Atlases[self.atlasInfo.key].singleDimention.h * scaley
			local xSegments = math.ceil(G.drawinfo.gridSize.x / Atlases[self.atlasInfo.key].singleDimention.w * scalex)
			local ySegments = math.ceil(G.drawinfo.gridSize.y / Atlases[self.atlasInfo.key].singleDimention.h * scaley)
			for i = -1, xSegments + 1 do
				for j = -1, ySegments + 1 do
					love.graphics.draw(
						Atlases[self.atlasInfo.key].image,
						Atlases[self.atlasInfo.key].splicedImages[self.atlasInfo.x][self.atlasInfo.y],
						moduloX + i * Atlases[self.atlasInfo.key].singleDimention.w,
						moduloY + j * Atlases[self.atlasInfo.key].singleDimention.h,
						0, scalex, scaley
					)
				end
			end
		end
		if self.mask.ShouldApply then
			love.graphics.setStencilTest()
		end
		love.graphics.setColor { r, g, b, a }
	end
	if self.atlasInfo.key then
		if self.properties.Outline then
			local r, g, b, a = love.graphics.getColor()
			local function myStencilFunction()
				draw_func(self.offset.x + 1, self.offset.y)
				draw_func(self.offset.x - 1, self.offset.y)
				draw_func(self.offset.x, self.offset.y + 1)
				draw_func(self.offset.x, self.offset.y - 1)
			end
			love.graphics.stencil(myStencilFunction, "replace", 1)
			love.graphics.setStencilTest("greater", 0)
			love.graphics.setColor(self.properties.OutlineColor)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.setColor { r, g, b, a }
			love.graphics.setStencilTest()
		end
		draw_func(self.offset.x, self.offset.y)
	end
	self.drawFunc(self)
	love.graphics.setColor { r, g, b, a }
end

function Sprite:setParent(obj)
	table.insert(obj.children, self.id)
	self.parent = obj.id
	return self.parent
end

function Sprite:getParentOffset()
	if not self.parent then return { x = 0, y = 0 } end
	local parent = getObjectById(self.parent)
	if not parent then return { x = 0, y = 0 } end
	return { x = parent.T.x, y = parent.T.y }
end

function Sprite:update(dt)
	if self.parent then
		self.T.x = self:getParentOffset().x
		self.T.y = self:getParentOffset().y
	end
	self.updateFunc(self, dt)
end

function Sprite:remove()
	for k, v in ipairs(G.I.SPRITES) do
		if v.id == self.id then
			table.remove(G.I.SPRITES, k)
		end
	end
	self = nil
end
function Sprite:getHeight()
	return Atlases[self.atlasInfo.key].singleDimention.h * self.scale.y * Util.UI.getScalingFactor()
end

function Sprite:getWidth()
	return Atlases[self.atlasInfo.key].singleDimention.w * self.scale.x * Util.UI.getScalingFactor()
end
