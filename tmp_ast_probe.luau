--!strict
local syntax = require('@std/syntax')

local source = [[
local t = {10, 20, 30}
for k, v in t do
  print(k, v)
end
for k, v in pairs(t) do
  print(k, v)
end
]]

local result = syntax.parse(source)
local stmts = result.root.statements

local visited: { [any]: boolean } = {}

local function dump(val: any, indent: number, label: string)
	local pad = string.rep("  ", indent)
	if type(val) == "table" then
		if visited[val] then
			print(pad .. label .. " <visited>")
			return
		end
		visited[val] = true
		print(pad .. label .. " {")
		for k, v in val :: { [any]: any } do
			local vt = type(v)
			if vt == "string" or vt == "number" or vt == "boolean" then
				print(pad .. "  [" .. tostring(k) .. "] = " .. tostring(v))
			elseif vt == "table" then
				dump(v, indent + 1, "[" .. tostring(k) .. "] =")
			else
				print(pad .. "  [" .. tostring(k) .. "] = (" .. vt .. ")" .. tostring(v))
			end
		end
		print(pad .. "}")
		visited[val] = nil
	else
		print(pad .. label .. " " .. tostring(val))
	end
end

for i = 2, #stmts do
	print("=== STMT " .. i .. " ===")
	dump(stmts[i], 0, "")
	print("")
end
