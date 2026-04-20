--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('01_print: numbers', function(asserts)
	local source = [[
print(0)
print(5)
print(9)
]]
	asserts.eq('0\n5\n9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('01_print: multiple number args', function(asserts)
	local source = [[
print(1, 2, 3)
]]
	asserts.eq('1\t2\t3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('01_print: mixed string and number args', function(asserts)
	local source = [[
print("x =", 42)
]]
	asserts.eq('x =\t42\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('01_print: no args', function(asserts)
	local source = [[
print()
]]
	asserts.eq('\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('01_print: two string args', function(asserts)
	local source = [[
print("hello", "world")
]]
	asserts.eq('hello\tworld\n', BFInterp.run(Compiler.compile(source)))
end)
