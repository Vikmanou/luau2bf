--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('27_break_nested', function(asserts)
	local source = [[
local i = 1
while i <= 3 do
	local j = 1
	while j <= 4 do
		print(i * 10 + j)
		if j == 2 then
			break
		end
		j += 1
	end
	print(i)
	i += 1
end
]]

	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('11\n12\n1\n21\n22\n2\n31\n32\n3\n', output)
end)
