---@class Vector: Object

Vector = Object:extend()
function Vector:new(...)
	self.dimentions = #{...}
	self.contents = {...}
end
function Vector:scale(scalar, new)
	if new then
		local r = Vector(unpack(self.contents))
		for k, v in ipairs(r.contents) do
			r.contents[k] = v * scalar
		end
		return r
	end
	for k, v in ipairs(self.contents) do
		self.contents[k] = v * scalar
	end
end

function Vector:abs()
	local sum = 0
	for k, v in ipairs(self.contents) do
		sum = sum + v^2
	end
	return sum ^ (1/2)
end
function Vector:negate(new)
	return self:scale(-1, new)
end
function Vector:getDir(new)
	return self:scale(1/self:abs(), new)
end
function Vector:add(a, new)
	if self.dimentions == a.dimentions then
		if new then
			local tab = {}
			for k, v in ipairs(self.contents) do
				table.insert(tab, v + a.contents[k])
			end
			return Vector(unpack(tab))
		end
		for k, v in ipairs(self.contents) do
			self.contents[k] = v + a.contents[k]
		end
	else
		error("Attempted to add 2 vectors with different dimentions")
	end
end

function Vector:sub(a, new)
	local newA = a:negate(true)
	return self:add(newA, new)
end
