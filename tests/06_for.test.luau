--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('06_for', function(asserts)
	local source = [[
for i = 1, 9 do
	print(i)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n2\n3\n4\n5\n6\n7\n8\n9\n', output)
end)
