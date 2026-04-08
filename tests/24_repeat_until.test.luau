--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('24_repeat_until', function(asserts)
	local source = [[
local i = 1
repeat
	print(i)
	i += 1
until i > 3
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('1\n2\n3\n', output)
end)
