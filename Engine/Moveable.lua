---@class Moveable: {T:table,TMod:table,TLast:table,id:integer,nid:string|nil|any,parent:nil|number,children:table,extra:table,updateFunc:fun(s:Moveable, dt:number),drawFunc:fun(s:Moveable),drawOrder:number,setParent:function,properties:table}

Moveable = Object:extend()

function Moveable:new(args)
	self.id = G.currentID
	self.nid = args.nid
	G.currentID = G.currentID + 1
	args = args or {}
	self.objectType = 'MOVEABLE'
	self.T = {
		x = 0,
		y = 0,
		w = 0,
		h = 0,
	}
	self.TLast = { x = 0, y = 0 }
	self.TMod = {
		x = { base = args.x or 0 },
		y = { base = args.y or 0 },
		w = { base = args.w or 0 },
		h = { base = args.h or 0 }
	}
	self.updateFunc = args.updateFunc or function(s, dt) return end
	self.drawFunc = args.drawFunc or function(s) return end
	self.V = {
		x = { base = args.vx or 0 },
		y = { base = args.vy or 0 },
	}
	self.parent = nil
	self.children = {}
	self.properties = args.properties or {}
	self.extra = args.extra or {}
	table.insert(G.I.MOVEABLES, self)
	self.drawOrder = args.drawOrder or 0
	self.updateOrder = args.updateOrder or 0
	return self
end

-- Functions ported from Badge of Severance

---Sets the parent of this object. Its return value will be a numeracal reference ID
---@param obj Moveable
---@return integer
function Moveable:setParent(obj)
	obj.children = {}
	table.insert(obj.children, self.id)
	self.parent = obj.id
	return self.parent
end

---Add a children to this object.
---@param obj Moveable
function Moveable:addChildren(obj) obj:setParent(self) end

-- Aligns objects based on their offsets

function Moveable:getParentOffset()
	if not self.parent then return { x = 0, y = 0 } end
	local parent = getObjectById(self.parent)
	if not parent then return { x = 0, y = 0 } end
	return { x = parent.T.x, y = parent.T.y }
end

function Moveable:getTotalOffset(component)
	local ret = { x = 0, y = 0, w = 0, h = 0 }
	for k, v in pairs(self.TMod) do
		if not component then
			for kk, vv in pairs(v) do
				ret[k] = ret[k] + vv
			end
		else
			ret[k] = ret[k] + v[component]
		end
	end
	return ret
end

function Moveable:getTotalVelocity(component)
	local ret = { x = 0, y = 0 }
	for k, v in pairs(self.V) do
		if not component then
			for kk, vv in pairs(v) do
				ret[k] = ret[k] + vv
			end
		else
			if self.V[k][component] then
				ret[k] = ret[k] + v[component]
			end
		end
	end
	return ret
end

function Moveable:update(dt)
	self.TMod.x.parent = self:getParentOffset().x
	self.TMod.y.parent = self:getParentOffset().y
	self.TLast.x = self.T.x
	self.TLast.y = self.T.y
	for k, v in pairs(self.V) do
		for kk, vv in pairs(v) do
			if k == "x" or k == "y" then
				self.TMod[k][kk] = self.TMod[k][kk] and self.TMod[k][kk] + self:getTotalVelocity(kk)[k] * dt or 0
			end
		end
	end
	for k, v in pairs(self.T) do
		if type(v) == "number" then
			self.T[k] = self:getTotalOffset()[k]
		end
	end
	self.updateFunc(self, dt)
end

function Moveable:draw()
	self.drawFunc(self)
end

function Moveable:remove(killAllChildren)
	if self.extra.entryMoveables then
		for k, v in pairs(self.extra.entryMoveables) do
			v:remove(killAllChildren)
		end
	end
	for k, v in ipairs(G.I.MOVEABLES) do
		if v.id == self.id then
			local j = self.id
			table.remove(G.I.MOVEABLES, k)
			for k, v in ipairs(G.I.MOVEABLES) do
				if v.parent == j then
					if killAllChildren then
						v:remove(killAllChildren)
					else
						v.parent = nil
					end
				end
			end
		end
	end
end

function getPosById(Id)
	for k, v in ipairs(G.I.MOVEABLES) do
		if v.id == Id then
			return k
		end
	end
end
