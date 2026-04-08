--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('18_logical_or', function(asserts)
	local source = [[
local x = 0
local y = 1
if x or y then
	print(1)
else
	print(0)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n', output)
end)
