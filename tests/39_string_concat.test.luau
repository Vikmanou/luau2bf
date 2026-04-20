--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('39_string_concat: two literals', function(asserts)
	local source = [[
print("hello" .. " world")
]]
	asserts.eq('hello world\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('39_string_concat: three literals', function(asserts)
	local source = [[
print("a" .. "b" .. "c")
]]
	asserts.eq('abc\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('39_string_concat: concat with empty string', function(asserts)
	local source = [[
print("hello" .. "")
]]
	asserts.eq('hello\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('39_string_concat: grouped concat', function(asserts)
	local source = [[
print(("foo") .. "bar")
]]
	asserts.eq('foobar\n', BFInterp.run(Compiler.compile(source)))
end)
