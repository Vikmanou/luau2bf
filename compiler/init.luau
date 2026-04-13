--!strict

local State = require('./compiler/compiler-state')
local Statements = require('./compiler/statements')
local CountVars = require('./compiler/count-variables')

local Codegen = {}

function Codegen.generate(root): string
	local varCount = CountVars(root)
	-- +4: for loop allocates step and break cells beyond the declared variable count
	local state = State.create(varCount + 4)

	Statements.emitBlock(state, root.statements)

	return table.concat(state.output)
end

return Codegen
