--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('32_compare_gt: true branch', function(asserts)
	local source = [[
local x = 7
if x > 5 then
	print(1)
else
	print(0)
end
]]
	local bf = Compiler.compile(source)
	asserts.eq('1\n', BFInterp.run(bf))
end)

test.case('32_compare_gt: false branch', function(asserts)
	local source = [[
local x = 3
if x > 5 then
	print(1)
else
	print(0)
end
]]
	local bf = Compiler.compile(source)
	asserts.eq('0\n', BFInterp.run(bf))
end)
