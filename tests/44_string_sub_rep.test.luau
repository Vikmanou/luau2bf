--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('44_string_sub_rep: string.sub in print', function(asserts)
	local source = [[
print(string.sub("brainfuck", 2, 5))
]]
	asserts.eq('rain\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: string.sub negative index', function(asserts)
	local source = [[
print(string.sub("hello", -3))
]]
	asserts.eq('llo\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: string.rep in print', function(asserts)
	local source = [[
print(string.rep("ab", 3))
]]
	asserts.eq('ababab\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: string.len of string.sub', function(asserts)
	local source = [[
print(string.len(string.sub("hello world", 1, 5)))
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: string.byte of string.sub', function(asserts)
	local source = [[
print(string.byte(string.sub("ABC", 2)))
]]
	asserts.eq('66\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: string.len of string.rep', function(asserts)
	local source = [[
print(string.len(string.rep("ha", 4)))
]]
	asserts.eq('8\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: # with string.rep', function(asserts)
	local source = [[
print(#string.rep("abc", 2))
]]
	asserts.eq('6\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('44_string_sub_rep: # with string.sub', function(asserts)
	local source = [[
print(#string.sub("hello", 2, 4))
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)
