--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('37_math_min: smaller value returned', function(asserts)
	local source = [[
local x = math.min(3, 7)
print(x)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('37_math_min: first arg smaller', function(asserts)
	local source = [[
local x = math.min(9, 2)
print(x)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('37_math_min: equal args', function(asserts)
	local source = [[
local x = math.min(5, 5)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)
