Util.File = {}

--- Saves a simple table (Number/String indices, no functions) to a file named fn under the appdata
--- @param tab table
--- @param fn string
function Util.File.saveTableToFile(tab, fn)
	local returnstring = ""
	local typetab = {
		string = "str",
		number = "num",
		boolean = "bol"
	}
	local function recursion(a, spaces)
	for k, v in pairs(a) do
		if type(v) == "table" then
			if next(v) then
			returnstring = returnstring..string.rep(" ", spaces).."key:"..typetab[type(k)].."|"..k.."|value:|tab:|end"
			returnstring = returnstring.."\n"
			recursion(v, spaces + 1)
			else
			returnstring = returnstring..string.rep(" ", spaces).."key:"..typetab[type(k)].."|"..k.."|value:|emt:|end" -- accounting for an empty table
			returnstring = returnstring.."\n"
			recursion(v, spaces + 1)
			end
		else
		returnstring = returnstring..string.rep(" ", spaces).."key:"..typetab[type(k)].."|"..k.."|value:|"..typetab[type(v)].."|"..tostring(v).."|end"
		returnstring = returnstring.."\n"
		end
	end
	end
	recursion(tab, 0)
	returnstring = string.sub(returnstring, 1, -2)
	love.filesystem.write(fn..Macros.fileSuffix , returnstring)
end

--- Sets a table with the file contents in fn,  replacing its original entries with the new one, but doesnt erase any old entries.\
--- This function does not return anything and sets the table via passing by reference.
--- @param tab table
--- @param fn string
function Util.File.setTableWithFile(tab, fn)
	local c = love.filesystem.read(fn..Macros.fileSuffix)
	if c then
		local temp = Util.File.readTableFromFile(fn)
		for k,v in pairs(temp) do
			tab[k] = v == nil and tab[k] or v
		end
	end
end
--- Reads from a file named fn under the appdata and returns the contents as a table
--- @param fn string
--- @return table contents
function Util.File.readTableFromFile(fn)
	local returntable = {}
	local hierarchies = {} -- table hierarchy, for sub table value jank
	local contents = love.filesystem.read(fn..Macros.fileSuffix)
	local table_of_lines = {}
	local str = ""
	for i = 1, #contents do
		local char = string.sub(contents, i, i)
		if char ~= "\n" then
			str = str..char
		else
			table.insert(table_of_lines, str)
			str = ""
		end
		if i == #contents then
			table.insert(table_of_lines, str)
		end
	end
	local funcs = {
		str = tostring,
		num = tonumber,
		tab = function (a)
			return a
		end,
		emt = function (...)
			return {}
		end,
		bol = function (a)
			if a == "true" then
				return true
			else
				return false
			end
		end
	}
	local table_of_spaces = {[0] = -1} -- so table_of_spaces[index - 1] doesnt kill it self when comparing
	-- this is relevant for table hierarchies
	for index, line in ipairs(table_of_lines) do
		local counter = 0
		for i = 1, #line do
			local char = string.sub(line, i, i)
			if char == " " then
				counter = counter + 1
			else
				break
			end
		end
		table_of_spaces[index] = counter
	end
	for index, line in ipairs(table_of_lines) do
		local _, _end = string.find(line, "key:")
		local type = string.sub(line, _end + 1, _end + 3) -- the type of the key
		local _beginning , _en= string.find(line, "value:")
		local k = funcs[type](string.sub(line, _end + 5, _beginning - 2))
		local v_type = string.sub(line, _en + 2, _en + 4) -- the type of the value
		local ending = string.find(line, "|end")
		local v = funcs[v_type](string.sub(line, _en + 6, ending - 1))
		-- super jank... but just know that k is the key and v is the value
		if table_of_spaces[index] < table_of_spaces[index - 1] then
			local difference = table_of_spaces[index - 1] - table_of_spaces[index]
			for i = 1, difference do -- just repeat difference times
				hierarchies[#hierarchies] = nil -- removes the latest hierarchy d times, because indents and stuff
			end
		end
		if v_type == "tab" then
			table.insert(hierarchies, k) -- add the table index to the hierarchy
		end
		local function writeToTable(hierarch, degree, keyval, tab)
			if next(hierarch) then
			local hr = Util.Other.copyTable(hierarch)
				if not tab[hierarch[1]] then
					tab[hierarch[1]] = {} -- if the table doest exist create an empty table
				end
				table.remove(hr, 1)
				writeToTable(hr, degree - 1, keyval, tab[hierarch[1]]) -- -1 degree, we love recursion
			end
			if degree == 0 then -- youre at the top of the hierarchy list
				tab[keyval.key] = keyval.val -- because of how pass by reference works, this writes to the original table
			end
		end
		-- Technically this would break if the table goes deeper, but that isnt possible in normal circumstances.
		if v_type ~= "tab" then
			writeToTable(hierarchies, #hierarchies, { key = k, val = v }, returntable)
		end
	end
	return returntable
end