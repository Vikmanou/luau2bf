--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('09_subtract', function(asserts)
	local source = [[
local a = 10
local b = 4
local c = a - b
print(c)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('6\n', output)
end)
