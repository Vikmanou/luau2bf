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
