--!strict

local process = require('@lute/process')
local json = require('@std/json')

local Linter = {}

function Linter.validate(source: string): ()
	local result = process.run({ 'lute', 'lint', '-j', '-c', './linter/.config.luau', '-s', source })

	local res = json.deserialize(result.stdout)
	
	for _, v in res do
		if v.severity == 1 then
			error(`Lint Error: {v.message} at line {v.range.start.line}`)
			return
		end
	end

	if result.ok == false then
		error(`Lint Error: {result.stderr}`)
		return
	end
end

return Linter
