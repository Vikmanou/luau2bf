--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('50_recursion: tail countdown', function(asserts)
	local source = [[
local function countdown(n)
	if n == 0 then
		return n
	end
	return countdown(n - 1)
end
print(countdown(5))
]]
	local bf = Compiler.compile(source)
	asserts.eq('0\n', BFInterp.run(bf))
end)

test.case('50_recursion: tail factorial via accumulator', function(asserts)
	local source = [[
local function fact(n, acc)
	if n == 0 then
		return acc
	end
	return fact(n - 1, acc * n)
end
print(fact(5, 1))
]]
	local bf = Compiler.compile(source)
	asserts.eq('120\n', BFInterp.run(bf))
end)

test.case('50_recursion: tail gcd', function(asserts)
	local source = [[
local function gcd(a, b)
	if b == 0 then
		return a
	end
	return gcd(b, a % b)
end
print(gcd(48, 18))
]]
	local bf = Compiler.compile(source)
	asserts.eq('6\n', BFInterp.run(bf))
end)

test.case('50_recursion: tail sum via accumulator', function(asserts)
	local source = [[
local function sum(n, acc)
	if n == 0 then
		return acc
	end
	return sum(n - 1, acc + n)
end
print(sum(10, 0))
]]
	local bf = Compiler.compile(source)
	asserts.eq('55\n', BFInterp.run(bf))
end)

test.case('50_recursion: param swap in tail call', function(asserts)
	local source = [[
local function loop(a, b)
	if a == 0 then
		return b
	end
	return loop(a - 1, b + a)
end
print(loop(4, 10))
]]
	local bf = Compiler.compile(source)
	asserts.eq('20\n', BFInterp.run(bf))
end)

test.case('50_recursion: tail call inside while', function(asserts)
	local source = [[
local function f(n)
	while n < 100 do
		return f(n + 7)
	end
	return n
end
print(f(0))
]]
	local bf = Compiler.compile(source)
	asserts.eq('105\n', BFInterp.run(bf))
end)

test.case('50_recursion: non-tail recursion errors', function(asserts)
	local source = [[
local function f(n)
	if n == 0 then
		return 1
	end
	return f(n - 1) + 1
end
print(f(3))
]]
	local ok = pcall(function()
		Compiler.compile(source)
	end)
	asserts.eq(false, ok)
end)
