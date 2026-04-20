--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

-- math.max
test.case('math.max: larger second arg', function(asserts)
	local source = [[
local x = math.max(3, 7)
print(x)
]]
	asserts.eq('7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.max: larger first arg', function(asserts)
	local source = [[
local x = math.max(9, 2)
print(x)
]]
	asserts.eq('9\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.max: equal args', function(asserts)
	local source = [[
local x = math.max(5, 5)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

-- math.min
test.case('math.min: smaller first arg', function(asserts)
	local source = [[
local x = math.min(3, 7)
print(x)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.min: smaller second arg', function(asserts)
	local source = [[
local x = math.min(9, 2)
print(x)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.min: equal args', function(asserts)
	local source = [[
local x = math.min(5, 5)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

-- math.clamp
test.case('math.clamp: value within range', function(asserts)
	local source = [[
local x = math.clamp(5, 0, 10)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.clamp: value above max', function(asserts)
	local source = [[
local x = math.clamp(15, 0, 10)
print(x)
]]
	asserts.eq('10\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.clamp: value below min', function(asserts)
	local source = [[
local x = math.clamp(0, 5, 10)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.clamp: value at min boundary', function(asserts)
	local source = [[
local x = math.clamp(5, 5, 10)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.clamp: value at max boundary', function(asserts)
	local source = [[
local x = math.clamp(10, 5, 10)
print(x)
]]
	asserts.eq('10\n', BFInterp.run(Compiler.compile(source)))
end)

-- math.sqrt
test.case('math.sqrt: zero', function(asserts)
	local source = [[
local x = math.sqrt(0)
print(x)
]]
	asserts.eq('0\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: perfect square 1', function(asserts)
	local source = [[
local x = math.sqrt(1)
print(x)
]]
	asserts.eq('1\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: perfect square 4', function(asserts)
	local source = [[
local x = math.sqrt(4)
print(x)
]]
	asserts.eq('2\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: perfect square 9', function(asserts)
	local source = [[
local x = math.sqrt(9)
print(x)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: floor of non-perfect square', function(asserts)
	local source = [[
local x = math.sqrt(10)
print(x)
]]
	asserts.eq('3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: perfect square 25', function(asserts)
	local source = [[
local x = math.sqrt(25)
print(x)
]]
	asserts.eq('5\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('math.sqrt: max byte value 255', function(asserts)
	local source = [[
local x = math.sqrt(255)
print(x)
]]
	asserts.eq('15\n', BFInterp.run(Compiler.compile(source)))
end)
