--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('48_exponent: basic', function(asserts)
	local source = [[
local x = 2
local y = 3
print(x ^ y)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('8\n', output)
end)

test.case('48_exponent: zero exponent', function(asserts)
	local source = [[
print(5 ^ 0)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n', output)
end)

test.case('48_exponent: zero base', function(asserts)
	local source = [[
print(0 ^ 5)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('0\n', output)
end)

test.case('48_exponent: overflow', function(asserts)
	local source = [[
-- 2^8 = 256, should wrap to 0 in 8-bit
print(2 ^ 8)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('0\n', output)
end)

test.case('48_exponent: compound', function(asserts)
	local source = [[
local a = 3
a ^= 2
print(a)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('9\n', output)
end)

test.case('48_exponent: constant folding', function(asserts)
	local sourceFolded = "print(2 ^ 4)"
	local sourceUnfolded = "local x = 2; local y = 4; print(x ^ y)"
	
	local bfFolded = Compiler.compile(sourceFolded)
	local bfUnfolded = Compiler.compile(sourceUnfolded)
	
	if #bfFolded >= #bfUnfolded then
		error(`Constant folding failed: folded size {#bfFolded} is not smaller than unfolded size {#bfUnfolded}`)
	end
	
	local output = BFInterp.run(bfFolded)
	asserts.eq('16\n', output)
end)
