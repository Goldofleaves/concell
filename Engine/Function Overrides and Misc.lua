local printref = print
function print(...)
	local function log(l)
		local printtext = {}
		local function j(value, spaces, key)
			spaces = spaces or 0
			ins = ins or 0
			if type(value) == "table" then
				table.insert(printtext, string.rep(" ", spaces) .. (key and key .. ": " or "") .. "Table:")
				spaces = spaces + 1
				for k, v in pairs(value) do
					if type(v) == "table" then
						j(v, spaces + 1, k)
					else
						table.insert(printtext, string.rep(" ", spaces + 1) .. tostring(k) .. ": " .. tostring(v))
					end
				end
			else
				table.insert(printtext, string.rep(" ", spaces) .. tostring(value))
			end
		end
		j(l)
		for k, v in pairs(printtext) do
			printref(v)
		end
	end
	for k, v in pairs({ ... }) do
		log(v)
	end
end
