--!strict
-- Test runner for the Luau-to-Brainfuck compiler.
-- Usage: lute test.luau
-- Discovers all *.luau files in tests/, compiles each one, runs the output
-- through the BF interpreter, and compares against the expected output declared
-- in the first line of each file as: -- expected: <output>
-- Use \n and \t as escape sequences in that comment.

local fs = require('@lute/fs')
local Compiler = require('./pipeline')
local BFInterp = require('./bf-interpreter')

local TESTS_PATH = './tests'

local function readExpected(source: string): string?
	local raw = source:match('^%-%- expected: ([^\r\n]+)')
	if not raw then return nil end
	return raw:gsub('\\n', '\n'):gsub('\\t', '\t')
end


local function loadTests(): { { name: string, source: string, expected: string } }
	local tests = {}
	local entries = fs.listdir(TESTS_PATH)

	table.sort(entries, function(a, b) return a.name < b.name end)

	for _, entry in entries do
		if entry.type ~= 'file' or not entry.name:find('%.luau$') then continue end
		
		local path = `{TESTS_PATH}/{entry.name}`

		local fh = fs.open(path, 'r')
		local source = fs.read(fh, '*a')
		fs.close(fh)

		local expected = readExpected(source)
		if not expected then
			print(`[WARN] {entry.name}: missing -- expected: comment, skipping`)
			continue
		end

		table.insert(tests, {
			name = entry.name:gsub('%.luau$', ''),
			source = source,
			expected = expected,
		})
	end
	return tests
end


local passed, failed = 0, 0

for _, test in loadTests() do
	local ok, result = pcall(function()
		local bf = Compiler.compile(test.source)
		local output = BFInterp.run(bf)
		return output
	end)

	if not ok then
		print(`[FAIL] {test.name}: error during compilation or execution`)
		print(`[FAIL] {test.name}: Error: {tostring(result)}`)
		failed += 1
	elseif result ~= test.expected then
		print(`[FAIL] {test.name}: Expected: {test.expected:gsub('\n', '\\n')}`)
		print(`[FAIL] {test.name}: Got:      {result:gsub('\n', '\\n')}`)
		failed += 1
	else
		print(`[PASS] {test.name}`)
		passed += 1
	end
end

print('')
print(`Results: {passed} passed, {failed} failed out of {passed + failed} tests`)

