--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('34_unary_minus: negate literal wraps to 251 (byte)', function(asserts)
	-- -5 wraps to 256 - 5 = 251 in unsigned byte arithmetic
	local source = [[
local x = -5
print(x)
]]
	local bf = Compiler.compile(source)
	asserts.eq('251\n', BFInterp.run(bf))
end)

test.case('34_unary_minus: subtract negated value', function(asserts)
	local source = [[
local x = 5
local y = -x
print(y)
]]
	local bf = Compiler.compile(source)
	asserts.eq('251\n', BFInterp.run(bf))
end)
