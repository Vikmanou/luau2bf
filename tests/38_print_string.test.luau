--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('38_print_string: single string', function(asserts)
	local source = [[
print("hello")
]]
	asserts.eq('hello\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('38_print_string: multiple strings', function(asserts)
	local source = [[
print("hello")
print("world")
]]
	asserts.eq('hello\nworld\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('38_print_string: empty string', function(asserts)
	local source = [[
print("")
]]
	asserts.eq('\n', BFInterp.run(Compiler.compile(source)))
end)
