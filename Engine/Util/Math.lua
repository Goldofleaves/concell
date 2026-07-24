Util.Math = {}

--- The value of τ.
math.tau = math.pi * 2

--- The value of e, better known as eulers number/the expodential constant.
math.e = math.exp(1)

--- Integer division. What more do I have to say?
--- @param num number
--- @param div number
--- @return integer Result
Util.Math.div = function(num, div)
	return math.floor(num / div)
	-- // is fucking broken, thanks love2d
end

--- Returns a random element and its corresponding key from tab.
--- @param tab table
--- @return {v:any,k:string|integer} element
Util.Math.randomElement = function(tab)
	local f = {}
	for k, v in pairs(tab) do
		table.insert(f, k)
	end
	local k = f[love.math.random(1, #f)]
	return { v = tab[k], k = k }
end

--- Has a probably of the arguement to return true, else return false
--- @param chance number
--- @return boolean result
Util.Math.chance = function(chance)
	return love.math.random() <= chance
end

--- Clamps a value between 2 numbers.
--- @param min number
--- @param max number
--- @param value number
--- @return number result
Util.Math.clamp = function(min, max, value)
	if max < min then
		local a = min
		min = max
		max = a
	end
	return math.min(max, math.max(min, value))
end

--- Linearly interpolates a to b, so when v is 1 it returns b, when v is 0 it returns a, and when v is 0.5 it returns the midpoint.
--- @param a number The starting value.
--- @param b number The ending value.
--- @param v number The `"speed"`, or fraction of the distance traversed in 1 frame.
Util.Math.lerp = function(a, b, v)
	if type(a) == type(b) and type(a) == "number" then
		return a + (v * (b - a))
	end
	if type(a) == type(b) and type(a) == "table" then
		local rTab = {}
		for k, vv in pairs(a) do
			local vvv = b[k]
			if type(vv) == type(vvv) and type(vv) == "number" then
				rTab[k] = vv + (v * (vvv - vv))
			end
		end
		return rTab
	end
end

--- Same as lerp but accounting with deltatime.\
--- More info: https://www.youtube.com/watch?v=LSNQuFEDOyQ
--- @param a number The starting value.
--- @param b number The ending value.
--- @param r number The `"speed"`, or fraction of the distance left to traverse in 1 second.
Util.Math.lerpDt = function(a, b, r)
	local v = 1 - (r ^ DELTATIME)
	return Util.Math.lerp(a, b, v)
end

--- Returns the sign of a number.
--- @param n number
--- @return 1|-1|0 sign
math.sign = function (n)
	if n ~= 0 then
		return n/math.abs(n)
	end
	return 0
end

--- Check if a and b's difference are in a margin of p.
--- @param a number
--- @param b number
--- @param p number
--- @return boolean result
function Util.Math.precisionCheck(a, b, p)
	local delta = math.abs(a - b)
	return delta <= p
end

--- Returns a float from min to max.
--- @param min number|nil
--- @param max number|nil
--- @return number result
math.betterrandom = function (min, max)
	min = min or -1
	max = max or 1
	local stretch = max - min
	return love.math.random() * stretch + min
end
--- Returns the distance between a and b.
--- @param a {x:number, y:number}
--- @param b {x:number, y:number}
--- @return number
Util.Math.pythagorean = function(a, b)
	return ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) ^ (1 / 2)
end

Util.Math.round = function (a)
	return math.floor(a + 0.5)
end

Util.Math.atan2 = function (y, x)
	if x > 0 then
		return math.atan(y/x)
	elseif x < 0 then
		if y >= 0 then
			return math.atan(y / x) + math.pi
		else
			return math.atan(y / x) - math.pi
		end
	else
		if y > 0 then
			return math.pi/2
		elseif y < 0 then
			return -math.pi/2
		else
			return 0
		end
	end
end

Util.Math.moveToPoint = function(origin, target, speed)
	--[[ format origin and target as {x = num, y = num} please ]]
	local height = target.y - origin.y
	local width = target.x - origin.x
	local hyp = (width ^ 2 + height ^ 2) ^ (1 / 2)
	local returntable = {
		w = width / hyp * speed,
		h = height / hyp * speed
	}
	if math.abs(returntable.w) > math.abs(width) then
		returntable.w = width
	end
	if math.abs(returntable.h) > math.abs(height) then
		returntable.h = height
	end
	if hyp == 0 then
		return { w = 0, h = 0 }
	end
	return returntable
end


Util.Math.moveToPointDt = function(origin, target, speed)
	return Util.Math.moveToPoint(origin, target, speed * DELTATIME)
end

Util.Math.weightedChance = function(chances)
	local a = {}
	for k, v in pairs(chances) do
		for i = 1, v.weight do
			table.insert(a, v.val)
		end
	end
	return Util.Math.randomElement(a).v
end

function Util.Math.indexModulo(a, mod)
	return ((a - 1) % mod) + 1
end

function Util.Math.rotatePointAroundOrigin(x, y, theta)
	return {
		x = x * math.cos(theta) - y * math.sin(theta),
		y = x * math.sin(theta) + y * math.cos(theta),
	}
end
