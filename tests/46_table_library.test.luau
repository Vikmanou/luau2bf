--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

-- table.insert (append form)

test.case('46_table_library: table.insert appends to array', function(asserts)
	local source = [[
local t = {1, 2, 3}
table.insert(t, 4)
print(t[4])
]]
	asserts.eq('4\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.insert updates length', function(asserts)
	local source = [[
local t = {10, 20}
table.insert(t, 30)
print(#t)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.insert multiple times', function(asserts)
	local source = [[
local t = {}
table.insert(t, 5)
table.insert(t, 6)
table.insert(t, 7)
print(t[1])
print(t[2])
print(t[3])
]]
	asserts.eq('5\n6\n7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.insert with expression value', function(asserts)
	local source = [[
local t = {1, 2}
local x = 99
table.insert(t, x)
print(t[3])
]]
	asserts.eq('99\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.insert at position', function(asserts)
	local source = [[
local t = {1, 2, 3}
table.insert(t, 2, 9)
print(t[1])
print(t[2])
print(t[3])
print(t[4])
]]
	asserts.eq('1\n9\n2\n3\n', BFInterp.run(Compiler.compile(source)))
end)

-- table.remove

test.case('46_table_library: table.remove pops last element', function(asserts)
	local source = [[
local t = {10, 20, 30}
local v = table.remove(t)
print(v)
print(#t)
]]
	asserts.eq('30\n2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.remove at position', function(asserts)
	local source = [[
local t = {10, 20, 30}
local v = table.remove(t, 2)
print(v)
print(t[1])
print(t[2])
]]
	asserts.eq('20\n10\n30\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.remove as statement', function(asserts)
	local source = [[
local t = {5, 6, 7}
table.remove(t)
print(#t)
print(t[1])
print(t[2])
]]
	asserts.eq('2\n5\n6\n', BFInterp.run(Compiler.compile(source)))
end)

-- table.find

test.case('46_table_library: table.find returns index when found', function(asserts)
	local source = [[
local t = {10, 20, 30}
local i = table.find(t, 20)
print(i)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.find returns 0 when not found', function(asserts)
	local source = [[
local t = {10, 20, 30}
local i = table.find(t, 99)
print(i)
]]
	asserts.eq('0\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.find returns first match', function(asserts)
	local source = [[
local t = {5, 9, 9, 3}
local i = table.find(t, 9)
print(i)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.find with runtime needle', function(asserts)
	local source = [[
local t = {3, 7, 11}
local needle = 11
local i = table.find(t, needle)
print(i)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: table.insert then table.find', function(asserts)
	local source = [[
local t = {1, 2, 3}
table.insert(t, 42)
local i = table.find(t, 42)
print(i)
]]
	asserts.eq('4\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('46_table_library: forin after table.insert', function(asserts)
	local source = [[
local t = {10, 20}
table.insert(t, 30)
local sum = 0
for _, v in ipairs(t) do
	sum = sum + v
end
print(sum)
]]
	asserts.eq('60\n', BFInterp.run(Compiler.compile(source)))
end)
