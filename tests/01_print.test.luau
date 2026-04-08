--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('01_print', function(asserts)
	local source = [[
print(0)
print(5)
print(9)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('0\n5\n9\n', output)
end)
