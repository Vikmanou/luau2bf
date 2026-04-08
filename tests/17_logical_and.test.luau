--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('17_logical_and', function(asserts)
	local source = [[
local x = 1
local y = 0
if x and y then
	print(1)
else
	print(0)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('0\n', output)
end)
