--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('47_table_reassign: array literal reassignment (same shape)', function(asserts)
	local source = [[
local t = {1, 2, 3}
t = {4, 5, 6}
print(t[2])
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('47_table_reassign: record literal reassignment (same keys)', function(asserts)
	local source = [[
local t = {foo = 1, bar = 2}
t = {foo = 9, bar = 8}
print(t.foo)
print(t.bar)
]]
	asserts.eq('9\n8\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('47_table_reassign: nested literal reassignment', function(asserts)
	local source = [[
local t = {inner = {10, 20}}
t = {inner = {30, 40}}
print(t.inner[1])
print(t.inner[2])
]]
	asserts.eq('30\n40\n', BFInterp.run(Compiler.compile(source)))
end)

