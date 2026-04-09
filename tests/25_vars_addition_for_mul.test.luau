--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')


test.case('25_vars_addition_for_mul', function(asserts)
    local source = [[
local a = 5
local b = 3
local c = a + b
for i = 1, c do
    print(i * 2)
end
    ]]

	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('2\n4\n6\n8\n10\n12\n14\n16\n', output)
end)