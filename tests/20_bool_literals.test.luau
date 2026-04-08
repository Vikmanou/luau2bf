--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('20_bool_literals', function(asserts)
	local source = [[
if true then
	print(1)
end
if false then
	print(9)
end
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n', output)
end)
