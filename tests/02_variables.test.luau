--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('02_variables', function(asserts)
	local source = [[
local x = 7
local y = 3
print(x)
print(y)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('7\n3\n', output)
end)
