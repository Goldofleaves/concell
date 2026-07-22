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

function Vector:unpack()
	return unpack(self.contents)
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

local getsize = function (t)
	local counter = 0
	for k, v in pairs(t) do
		counter = counter + 1
	end
	return counter
end
local function unpackWithRespectTo0(t)
	local newT = {}
	for k, v in pairs(t) do
		table.insert(newT, v)
	end
	return unpack(newT)
end
---@class Polynomial: Object
Polynomial = Object:extend()
function Polynomial:new(...)
	local P = {}
	for k, v in ipairs({...}) do
		table.insert(P, getsize(P), v) -- inserts the first arg as the 0th index, corresponding to x^0
	end
	self.contents = P
end
function Polynomial:take_derivative()
	local newP = {}
	for k, v in ipairs(self.contents) do -- so the index starts at 1, ignoring the 0th term
		table.insert(newP, getsize(newP), v * k)
	end
	return Polynomial(unpackWithRespectTo0(newP))
end
function Polynomial:integrate(C)
	local newP = {}
	newP[0] = C
	for k, v in pairs(self.contents) do
		table.insert(newP, getsize(newP), v/(k+1))
	end
	return Polynomial(unpackWithRespectTo0(newP))
end
function Polynomial:add(other)
	local newP = {}
	if getsize(self.contents) > getsize(other.contents) then
		for k, v in pairs(self.contents) do
			newP[k] = v + (other.contents[k] or 0)
		end
	else
		for k, v in pairs(other.contents) do
			newP[k] = v + (self.contents[k] or 0)
		end
	end
	return Polynomial(unpackWithRespectTo0(newP))
end

function Polynomial:multiply(other)
	local newP = {}
	for powerA, coefficientA in pairs(self.contents) do
		for powerB, coefficientB in pairs(other.contents) do
			local newPower = powerA + powerB
			local newCoefficient = coefficientA * coefficientB
			newP[newPower] = newP[newPower] and newCoefficient or newP[newPower] + newCoefficient
		end
	end
	return Polynomial(unpackWithRespectTo0(newP))
end
function Polynomial:evaluate(x)
	local sum = 0
	for k, v in pairs(self.contents) do
		sum = sum + (x^k) * v
	end
	return sum
end
function Polynomial:__tostring()
	local str = ""
	for k, v in pairs(self.contents) do
		if v ~= 0 then
			str = str .. (k == 0 and v or (v == 1 and "" or v).."x^"..k) .. " + "
		end
	end
	str = string.sub(str, 1, #str - 3)
	return str
end

Matrix = Object:extend()
function Matrix:new(...)
	self.dimentions = { columns = #{ ... }, rows = #({ ... })[1] }
	self.contents = { ... }
end

function Matrix:scale(scalar, new)
	if new then
		local r = {}
		for i = 1, self.dimentions.columns do
			r[i] = {}
			for j = 1, self.dimentions.rows do
				r[i][j] = self.contents[i][j] * scalar
			end
		end
		return Matrix(unpack(r))
	end
	for i = 1, self.dimentions.columns do
		for j = 1, self.dimentions.rows do
			self.contents[i][j] = self.contents[i][j] * scalar
		end
	end
end

function Matrix:add(a, new)
	if self.dimentions.columns == a.dimentions.columns and self.dimentions.rows == a.dimentions.rows then
		if new then
			local tab = {}
			for i = 1, self.dimentions.columns do
				tab[i] = {}
				for j = 1, self.dimentions.rows do
					tab[i][j] = self.contents[i][j] + a.contents[i][j]
				end
			end
			return Matrix(unpack(tab))
		end
		for i = 1, self.dimentions.columns do
			for j = 1, self.dimentions.rows do
				self.contents[i][j] = self.contents[i][j] + a.contents[i][j]
			end
		end
	else
		error("Attempted to add 2 matrices with different dimentions")
	end
end

function Matrix:apply(vector, new)
	if self.dimentions.columns == vector.dimentions then
		if new then
			local r = Vector(unpack((function()
				local t = {}
				for i = 1, self.dimentions.rows do
					t[i] = 0
				end
				return t
			end)())) -- the 0 vector
			for k, v in ipairs(vector.contents) do
				if type(v) == "table" then
					local str = "v: "
					for k, v in ipairs(v) do
						str = str .. v .. ", "
					end
					error(str)
				end
				local basis_vector = Vector(unpack(self.contents[k]))
				basis_vector:scale(v)
				r:add(basis_vector)
			end
			return r
		end
		local copy = vector:scale(1, true)
		vector:scale(0)
		vector.dimentions = self.dimentions.rows
		if self.dimentions.rows > self.dimentions.columns then
			for i = 1, self.dimentions.rows do
				vector.contents[i] = vector.contents[i] or 0
			end
		elseif self.dimentions.rows < self.dimentions.columns then
			for i = 1, self.dimentions.columns do
				if i > self.dimentions.rows then
					vector.contents[i] = nil
				end
			end
		end -- setting the vector to the 0 vector in the correct dimention
		for k, v in ipairs(copy.contents) do
			local basis_vector = Vector(unpack(self.contents[k]))
			basis_vector:scale(v)
			vector:add(basis_vector)
		end
	else
		error("Attempted to apply a matrix to a vector with mismatched dimentions")
	end
end

function Util.Math.get2dRotationMatrix(theta)
	return Matrix({ math.cos(theta), math.sin(theta) }, { -math.sin(theta), math.cos(theta) })
end

function Util.Math.dotProduct(a, b)
	local sum = 0
	if b.dimentions == a.dimentions then
		for k, v in ipairs(a.contents) do
			sum = sum + v * b.contents[k]
		end
		return sum
	else
		error("Attempted to take dot product of 2 vectors with different dimentions")
	end
end
