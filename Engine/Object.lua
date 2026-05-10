
---@class Object
Object = {}
Object.__index = Object

--- Initiates a new object, needs to be defined seperately for each class based on Object.
function Object:new(...)
end
--- Extends an object, ususally used for creating new object sub-classes.
function Object:extend()
	local cls = {}
	for k, v in pairs(self) do
		if k:find("__") == 1 then
			cls[k] = v
		end
	end
	cls.__index = cls
	cls.super = self
	setmetatable(cls, self)
	return cls
end

--- i have no idea actually, this isnt used anywhere
function Object:implement(...)
	for _, cls in pairs({...}) do
		for k, v in pairs(cls) do
			if self[k] == nil and type(v) == "function" then
				self[k] = v
			end
		end
	end
end

--- checks if an object is another, usually an extended object
---@param T Object
function Object:is(T) 
	local mt = getmetatable(self)
	while mt do
		if mt == T then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end


function Object:__tostring()
	return "Object"
end


function Object:__call(...)
	local obj = setmetatable({}, self)
	obj:new(...)
	return obj
end