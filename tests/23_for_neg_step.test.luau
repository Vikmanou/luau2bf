--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('23_for_neg_step', function(asserts)
	local source = [[
for i = 5, 1, -1 do
	print(i)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('5\n4\n3\n2\n1\n', output)
end)
