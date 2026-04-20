--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('19_elseif', function(asserts)
	local source = [[
local x = 2
if x == 1 then
	print(1)
elseif x == 2 then
	print(2)
else
	print(3)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('2\n', output)
end)

test.case('19_elseif_multiple_clauses', function(asserts)
	local source = [[
local x = 3
if x == 1 then
	print(1)
elseif x == 2 then
	print(2)
elseif x == 3 then
	print(3)
else
	print(4)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('3\n', output)
end)

test.case('19_elseif_else_fallthrough', function(asserts)
	local source = [[
local x = 5
if x == 1 then
	print(1)
elseif x == 2 then
	print(2)
elseif x == 3 then
	print(3)
else
	print(9)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('9\n', output)
end)
