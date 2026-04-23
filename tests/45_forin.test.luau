--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

test.case('45_forin: list table bare iteration (k, v)', function(asserts)
	local source = [[
local t = {10, 20, 30}
for k, v in t do
  print(k, v)
end
]]
	asserts.eq('1\t10\n2\t20\n3\t30\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: list table key-only iteration', function(asserts)
	local source = [[
local t = {10, 20, 30}
for k in t do
  print(k)
end
]]
	asserts.eq('1\n2\n3\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: pairs iteration', function(asserts)
	local source = [[
local t = {5, 6, 7}
for k, v in pairs(t) do
  print(k, v)
end
]]
	asserts.eq('1\t5\n2\t6\n3\t7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: ipairs iteration', function(asserts)
	local source = [[
local t = {5, 6, 7}
for k, v in ipairs(t) do
  print(k, v)
end
]]
	asserts.eq('1\t5\n2\t6\n3\t7\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: ipairs skips non-sequential keys', function(asserts)
	local source = [[
local t = {[1] = 10, [3] = 30}
for k, v in ipairs(t) do
  print(k, v)
end
]]
	-- ipairs stops at 2 since key 2 is missing
	asserts.eq('1\t10\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: pairs iterates all numeric keys', function(asserts)
	local source = [[
local t = {[1] = 10, [3] = 30}
for k, v in pairs(t) do
  print(k, v)
end
]]
	asserts.eq('1\t10\n3\t30\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: value mutation visible in loop body', function(asserts)
	local source = [[
local sum = 0
local t = {1, 2, 3, 4}
for k, v in ipairs(t) do
  sum = sum + v
end
print(sum)
]]
	asserts.eq('10\n', BFInterp.run(Compiler.compile(source)))
end)

test.case('45_forin: break exits iteration', function(asserts)
	local source = [[
local t = {10, 20, 30}
for k, v in ipairs(t) do
  if k == 2 then
    break
  end
  print(v)
end
]]
	asserts.eq('10\n', BFInterp.run(Compiler.compile(source)))
end)
