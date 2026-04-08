--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('05_while', function(asserts)
	local source = [[
local x = 5
while x > 0 do
	print(x)
	x = x - 1
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('5\n4\n3\n2\n1\n', output)
end)
