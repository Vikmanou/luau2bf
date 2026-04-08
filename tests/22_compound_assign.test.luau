--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('22_compound_assign', function(asserts)
	local source = [[
local x = 10
x += 5
print(x)
x -= 3
print(x)
x *= 2
print(x)
x /= 6
print(x)
x %= 3
print(x)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('15\n12\n24\n4\n1\n', output)
end)
