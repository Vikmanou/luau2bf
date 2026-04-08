--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('10_multiply', function(asserts)
	local source = [[
local a = 6
local b = 7
local c = a * b
print(c)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('42\n', output)
end)
