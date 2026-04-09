--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('26_break_while', function(asserts)
	local source = [[
local i = 1
while i <= 5 do
	print(i)
	if i == 3 then
		break
	end
	i += 1
end
]]

	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n2\n3\n', output)
end)