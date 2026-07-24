Util.Other = {}

--- Creates a new table with the same elements to avoid jank caused by passing by reference
--- @param t table|any The original Table
--- @param filter table|nil If this is a table, then this function only copy entries inside filter as well.
--- @return table|any
Util.Other.copyTable = function(t, filter)
	if type(t) ~= "table" then
		return t
	end
	local ret = {}
	for k,v in pairs(t) do
		if type(v) ~= "table" then
			if not filter then
			ret[k] = v
			else
				for _,vv in ipairs(filter) do
					if k == vv then
						ret[k] = v
					end
				end
			end
		else
			ret[k] = Util.Other.copyTable(v, filter)
		end
	end
	return ret
end


--- Returns the color value for the passed in hex code.
--- @param hex string The hex code, `"#"` optionally included.
--- @return table Color
function Util.Other.hex(hex)
	if string.sub(hex, 1, 1) == "#" then
		hex = string.sub(hex, 2, string.len(hex))
	end
	if #hex <= 6 then hex = hex.."FF" end
	local _,_,r,g,b,a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
	local color = {tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255 or 255}
	return color
end

--- Return the stored value with the key list of hierarch in table.\
--- For example, F({a = {[4] = 7}}, {a, 4}) would return 7.
---@param tab table
---@param hierarch table
---@return any
function Util.Other.extractValueFromHierarch(tab, hierarch)
	hierarch = Util.Other.copyTable(hierarch)
	if next(hierarch) then
		local k = hierarch[#hierarch]
		table.remove(hierarch, #hierarch)
		if tab[k] then
			return Util.Other.extractValueFromHierarch(tab[k], hierarch)
		end
		return
	end
	return tab
end

--- Remove NIL values from an array and returns the result.
--- @param t table
--- @return table
function Util.Other.removeNils(t)
	local ret = {}
	for k, v in pairs(t) do
		if v ~= nil then
			table.insert(ret, v)
		end
	end
	return ret
end

--- Merges the values of multiple tables to one giant array and returns that array.\
--- Usually utilized to make hierarchies.
--- @param ... table
--- @return table
function table.merge(...)
	local _t = { ... }
	local ret = {}
	for _, v in ipairs(_t) do
		for _, vv in pairs(v) do
			ret[#ret + 1] = vv
		end
	end
	return ret
end

--- Returns the size of the table, including non integer index value.
--- @param t table
--- @return number
function table.size(t)
	local counter = 0
	for k,v in pairs(t) do
		counter = counter + 1
	end
	return counter
end

--[[

--- Removes all objects.
function Util.Other.removeAllObjects()
	local function removeEverythingRecursively(s, f)
		for k, v in pairs(G.I[s]) do
			if v.remove then
				v:remove(true)
				removeEverythingRecursively(s, f)
			end
			break
		end
	end
	for k, v in pairs(G.I) do
		removeEverythingRecursively(k)
	end
end

]]
--- Make a hook, primarily becuse i dont want to hook a l2d callback function everytime i add something/define it all in one place
--- @param path {rTab:string|table,rVal:any}
--- @param added function
function Util.Other.addFunctionality(path, added)
	local tab = path.rTab
	if type(tab) == "string" then
		tab = load("return "..tab)()
	end
	local ref = tab[path.rVal]
	tab[path.rVal] = function (...)
		local ret = ref(...)
		added(ret, ...)
		return ret
	end
end
--- Capitalizes the first letter of a string.
--- @param a string
--- @return string
function Util.Other.capitalizeFirstLetter(a)
	return string.upper(string.sub(a, 1, 1)) .. string.sub(a, 2, #a)
end
--- Remove duplicate values from an array.
---@param a table
function Util.Other.removeDupes(a)
	local function equivilence (a, b)
		if type(a) ~= type(b) then
			return false
		end
		if type(a) == "table" then
			local bool = true
			for k, v in pairs(a) do
				if not equivilence(v, b[k]) then
					bool = false
				end
			end
			for k, v in pairs(b) do
				if not equivilence(v, a[k]) then
					bool = false
				end
			end
			return bool
		end
		return a == b
	end
	local t = {}
	for k,v in pairs(a) do
		for kk, vv in ipairs(t) do
			if equivilence(v, vv) then
				a[k] = nil
			end
		end
		table.insert(t, v)
	end
	a = Util.Other.removeNils(a)
end

function Util.Other.setTableWithN(tab, n)
	for k, v in pairs(n) do
		tab[k] = v
	end
end
function getObjectById(id)
	for k, v in pairs(G.I) do
		for kk, vv in ipairs(v) do
			if vv.id == id then return vv end
		end
	end
	return false
end

---@param nid any
---@return false|Object
function getObjectByNid(nid)
	for k, v in pairs(G.I) do
		for kk, vv in ipairs(v) do
			if vv.nid == nid then return vv end
		end
	end
	return false
end
function table.exclude(a, val)
	local t = {}
	for k, v in pairs(a) do
		if v ~= val then
			t[k] = v
		end
	end
	return t
end