--!strict
-- While loop codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local function emitWhile(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local condCell = Expr.emitExpr(state, node.condition)
	Primitives.moveTo(state, condCell)
	Primitives.emit(state, '[')
	Primitives.resetTemps(state)

	emitBlock(state, node.body)

	Primitives.resetTemps(state)
	local condCell2 = Expr.emitExpr(state, node.condition)
	Primitives.moveTo(state, condCell2)
	Primitives.emit(state, ']')
	Primitives.resetTemps(state)
end

return {
	[NT.While] = emitWhile
}
