--!strict

local test = require('@std/test')
local Compiler = require('../pipeline')
local BFInterp = require('../bf-interpreter')

local function run(source: string): string
	return BFInterp.run(Compiler.compile(source))
end

test.case('fold: 3 + 2 = 5', function(asserts)
	asserts.eq('5\n', run('print(3 + 2)'))
end)

test.case('fold: 10 - 4 = 6', function(asserts)
	asserts.eq('6\n', run('print(10 - 4)'))
end)

test.case('fold: 3 * 4 = 12', function(asserts)
	asserts.eq('12\n', run('print(3 * 4)'))
end)

test.case('fold: 20 / 4 = 5', function(asserts)
	asserts.eq('5\n', run('print(20 / 4)'))
end)

test.case('fold: 17 % 5 = 2', function(asserts)
	asserts.eq('2\n', run('print(17 % 5)'))
end)

test.case('fold identity: n * 1 = n', function(asserts)
	asserts.eq('7\n', run([[
local n = 7
print(n * 1)
]]))
end)

test.case('fold identity: 1 * n = n', function(asserts)
	asserts.eq('7\n', run([[
local n = 7
print(1 * n)
]]))
end)

test.case('fold identity: n + 0 = n', function(asserts)
	asserts.eq('9\n', run([[
local n = 9
print(n + 0)
]]))
end)

test.case('fold identity: n - 0 = n', function(asserts)
	asserts.eq('9\n', run([[
local n = 9
print(n - 0)
]]))
end)

test.case('fold identity: n / 1 = n', function(asserts)
	asserts.eq('6\n', run([[
local n = 6
print(n / 1)
]]))
end)

test.case('fold zero: 0 * n = 0', function(asserts)
	asserts.eq('0\n', run([[
local n = 42
print(0 * n)
]]))
end)

test.case('fold zero: n * 0 = 0', function(asserts)
	asserts.eq('0\n', run([[
local n = 42
print(n * 0)
]]))
end)

test.case('fold nested: (2 + 3) * 4 = 20', function(asserts)
	asserts.eq('20\n', run('print((2 + 3) * 4)'))
end)
