--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('29_multiple_assignment', function(asserts)
	local source = [[
local a, b = 1, 2
print(a)
print(b)

a, b = b, a
print(a)
print(b)

local c, d = a + b, a * b
print(c)
print(d)
]]

	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n2\n2\n1\n3\n2\n', output)
end)