--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('40_string_library: string.len literal', function(asserts)
	local source = [[
print(string.len("hello"))
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.len concat literal', function(asserts)
	local source = [[
print(string.len("he" .. "llo"))
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.byte default index', function(asserts)
	local source = [[
print(string.byte("ABC"))
]]
	asserts.eq('65\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.byte explicit index', function(asserts)
	local source = [[
print(string.byte("ABC", 2))
]]
	asserts.eq('66\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.upper in print', function(asserts)
	local source = [[
print(string.upper("hello"))
]]
	asserts.eq('HELLO\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.lower in print', function(asserts)
	local source = [[
print(string.lower("HeLLo"))
]]
	asserts.eq('hello\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.reverse in print', function(asserts)
	local source = [[
print(string.reverse("stressed"))
]]
	asserts.eq('desserts\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.rep in print', function(asserts)
	local source = [[
print(string.rep("ha", 3))
]]
	asserts.eq('hahaha\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.sub in print', function(asserts)
	local source = [[
print(string.sub("brainfuck", 2, 6))
]]
	asserts.eq('rainf\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('40_string_library: string.char in print', function(asserts)
	local source = [[
print(string.char(72, 105, 33))
]]
	asserts.eq('Hi!\n', BFInterp.run(Compiler.compile(source)))
end)