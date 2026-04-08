--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('08_nested', function(asserts)
	local source = [[
local x = 3
local y = 0
while x > 0 do
	if x == 2 then
		y = y + 10
	else
		y = y + 1
	end
	x = x - 1
end
print(y)
]]
	local bf = Compiler.compile(source)
	local output = BFInterp.run(bf)
	asserts.eq('12\n', output)
end)
