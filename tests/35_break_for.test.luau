--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('35_break_for: break exits loop early', function(asserts)
	local source = [[
local result = 0
for i = 1, 10 do
	if i == 4 then
		break
	end
	result = result + i
end
print(result)
]]
	-- Sums 1+2+3 = 6, breaks before adding 4
	local bf = Compiler.compile(source)
	asserts.eq('6\n', BFInterp.run(bf))
end)
