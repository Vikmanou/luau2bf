--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('42_table_mutation: array constant assignment', function(asserts)
	local source = [[
local tbl = {1, 2, 3}
tbl[2] = 9
print(tbl[2])
]]
	asserts.eq('9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('42_table_mutation: array variable assignment', function(asserts)
	local source = [[
local tbl = {1, 2, 3}
local idx = 3
tbl[idx] = 8
print(tbl[3])
]]
	asserts.eq('8\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('42_table_mutation: dot assignment sugar', function(asserts)
	local source = [[
local tbl = {foo = 1}
tbl.foo = 7
print(tbl.foo)
]]
	asserts.eq('7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('42_table_mutation: nested array mutation', function(asserts)
	local source = [[
local tbl = {inner = {1, 2, 3}}
tbl.inner[2] = 9
print(tbl.inner[2])
]]
	asserts.eq('9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('42_table_mutation: nested dot and index access', function(asserts)
	local source = [[
local tbl = {inner = {value = 12}, arr = {4, 5, 6}}
print(tbl.inner.value)
print(tbl.arr[2])
]]
	asserts.eq('12\n5\n', BFInterp.run(Compiler.compile(source)))
end)