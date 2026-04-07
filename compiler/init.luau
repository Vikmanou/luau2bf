--!strict
-- Implementation is split across this directory's submodules:
--   compiler-state.luau - CodegenState type and tape-layout helpers
--   bf-emitter/  - Low-level BF emit helpers
--   expressions/ - Expression codegen
--   statements/  - Statement and block codegen

local State = require('./compiler/compiler-state')
local Stmts = require('./compiler/statements')
local CountVars = require('./compiler/count-variables')

local Types = require('./shared/types')
type ASTNode = Types.ASTNode

local Codegen = {}

function Codegen.generate(ast: ASTNode): string
	assert(ast.type == 'Program', 'Expected Program node')

	-- Reserve enough cells for all declared variables
	local varCount = CountVars(ast)
	local tempStart = varCount + 4 -- small buffer for safety
	local state = State.create(tempStart)

	Stmts.emitBlock(state, ast.body)

	return table.concat(state.output)
end

return Codegen
