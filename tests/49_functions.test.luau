--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('49_functions: no args no return', function(asserts)
	local source = [[
local function greet()
	print(42)
end
greet()
]]
	local bf = Compiler.compile(source)
	asserts.eq('42\n', BFInterp.run(bf))
end)

test.case('49_functions: one arg', function(asserts)
	local source = [[
local function double(x)
	print(x + x)
end
double(7)
]]
	local bf = Compiler.compile(source)
	asserts.eq('14\n', BFInterp.run(bf))
end)

test.case('49_functions: two args with return', function(asserts)
	local source = [[
local function add(x, y)
	return x + y
end
local r = add(2, 3)
print(r)
]]
	local bf = Compiler.compile(source)
	asserts.eq('5\n', BFInterp.run(bf))
end)

test.case('49_functions: call in expression', function(asserts)
	local source = [[
local function inc(n)
	return n + 1
end
print(inc(4) * 2)
]]
	local bf = Compiler.compile(source)
	asserts.eq('10\n', BFInterp.run(bf))
end)

test.case('49_functions: multiple calls', function(asserts)
	local source = [[
local function sq(n)
	return n * n
end
local a = sq(3)
local b = sq(5)
print(a)
print(b)
print(a + b)
]]
	local bf = Compiler.compile(source)
	asserts.eq('9\n25\n34\n', BFInterp.run(bf))
end)

test.case('49_functions: early return', function(asserts)
	local source = [[
local function clamp(n)
	if n > 10 then
		return 10
	end
	return n
end
print(clamp(3))
print(clamp(25))
]]
	local bf = Compiler.compile(source)
	asserts.eq('3\n10\n', BFInterp.run(bf))
end)

test.case('49_functions: return inside loop', function(asserts)
	local source = [[
local function findFirst()
	local i = 0
	while i < 100 do
		i = i + 1
		if i == 7 then
			return i
		end
	end
	return 0
end
print(findFirst())
]]
	local bf = Compiler.compile(source)
	asserts.eq('7\n', BFInterp.run(bf))
end)

test.case('49_functions: local var inside body', function(asserts)
	local source = [[
local function avgIsh(a, b)
	local s = a + b
	return s / 2
end
print(avgIsh(4, 8))
]]
	local bf = Compiler.compile(source)
	asserts.eq('6\n', BFInterp.run(bf))
end)

test.case('49_functions: function calling function', function(asserts)
	local source = [[
local function inc(n)
	return n + 1
end
local function incTwice(n)
	return inc(inc(n))
end
print(incTwice(5))
]]
	local bf = Compiler.compile(source)
	asserts.eq('7\n', BFInterp.run(bf))
end)

test.case('49_functions: void call as statement', function(asserts)
	local source = [[
local x = 10
local function show(v)
	print(v)
end
show(x)
show(x + 5)
]]
	local bf = Compiler.compile(source)
	asserts.eq('10\n15\n', BFInterp.run(bf))
end)
