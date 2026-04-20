--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('36_math_max: larger value returned', function(asserts)
	local source = [[
local x = math.max(3, 7)
print(x)
]]
	asserts.eq('7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('36_math_max: first arg larger', function(asserts)
	local source = [[
local x = math.max(9, 2)
print(x)
]]
	asserts.eq('9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('36_math_max: equal args', function(asserts)
	local source = [[
local x = math.max(5, 5)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)
