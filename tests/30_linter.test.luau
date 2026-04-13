--!strict

local test = require('@std/test')
local Linter = require('../linter')

test.case('linter: clean source does not throw', function(asserts)
	local source = [[
local x = 5
local y = x + 1
print(y)
]]
	Linter.validate(source)
end)

test.case('linter: numerical table keys triggers error', function(asserts)
	local source = [[local t = {a = 1, 9 = 2}]]
	asserts.throws(Linter.validate, source)
end)

test.case('linter: error level 2 (such as duplicate keys) should not throw', function(asserts)
	local source = [[local t = {a = 1, a = 2}]]
	Linter.validate(source)
end)

test.case('linter: division by 0 is not supported for luau2bf', function(asserts)
	local source = [[local x = 1 / 0]]
	asserts.throws(Linter.validate, source)
end)
