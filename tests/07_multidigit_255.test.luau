--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('07_multidigit_255', function(asserts)
	local source = [[
local x = 255
print(x)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('255\n', output)
end)
