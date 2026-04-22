--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('43_length: string literal', function(asserts)
	local source = [[
print(#"hello")
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: empty string', function(asserts)
	local source = [[
print(#"")
]]
	asserts.eq('0\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: string concat', function(asserts)
	local source = [[
print(#("ab" .. "cde"))
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: array table', function(asserts)
	local source = [[
local tbl = {10, 20, 30}
print(#tbl)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: mixed table counts array portion', function(asserts)
	local source = [[
local tbl = {5, 6, foo = 7, [10] = 8}
print(#tbl)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: record-only table', function(asserts)
	local source = [[
local tbl = {foo = 1, bar = 2}
print(#tbl)
]]
	asserts.eq('0\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: use in arithmetic', function(asserts)
	local source = [[
local tbl = {10, 20, 30, 40}
local n = #tbl + 1
print(n)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('43_length: use in for loop', function(asserts)
	local source = [[
local tbl = {10, 20, 30}
local sum = 0
for i = 1, #tbl do
	sum = sum + tbl[i]
end
print(sum)
]]
	asserts.eq('60\n', BFInterp.run(Compiler.compile(source)))
end)
