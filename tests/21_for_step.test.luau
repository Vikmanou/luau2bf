--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('21_for_step', function(asserts)
	local source = [[
for i = 1, 9, 2 do
	print(i)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n3\n5\n7\n9\n', output)
end)
