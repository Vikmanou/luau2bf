--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('03_arithmetic', function(asserts)
	local source = [[
local x = 5
local y = 3
local z = x + y
print(z)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('8\n', output)
end)
