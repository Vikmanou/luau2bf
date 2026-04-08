--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('16_logical_not', function(asserts)
	local source = [[
local x = 0
if not x then
	print(1)
else
	print(0)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n', output)
end)
