--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('12_modulo', function(asserts)
	local source = [[
local a = 17
local b = 5
local c = a % b
print(c)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('2\n', output)
end)
