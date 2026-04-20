--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('41_tables: array constant index', function(asserts)
	local source = [[
local tbl = {10, 20, 30}
print(tbl[2])
]]
	asserts.eq('20\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('41_tables: array variable index', function(asserts)
	local source = [[
local tbl = {10, 20, 30}
local idx = 3
print(tbl[idx])
]]
	asserts.eq('30\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('41_tables: record and general string key', function(asserts)
	local source = [[
local tbl = {foo = 10, ['bar'] = 20}
print(tbl['foo'])
print(tbl['bar'])
]]
	asserts.eq('10\n20\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('41_tables: numeric dictionary variable index', function(asserts)
	local source = [[
local tbl = {[1] = 11, [3] = 33}
local idx = 3
print(tbl[idx])
]]
	asserts.eq('33\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('41_tables: boolean dictionary variable index', function(asserts)
	local source = [[
local tbl = {[true] = 7, [false] = 9}
local flag = false
print(tbl[flag])
]]
	asserts.eq('9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('41_tables: mixed array and dictionary keys', function(asserts)
	local source = [[
local tbl = {5, 6, foo = 7, [10] = 8}
print(tbl[1])
print(tbl[10])
print(tbl['foo'])
]]
	asserts.eq('5\n8\n7\n', BFInterp.run(Compiler.compile(source)))
end)