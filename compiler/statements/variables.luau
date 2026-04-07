--!strict
-- Variable declaration and assignment codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

local function emitVarDecl(state: CodegenState, node: ASTNode)
	local cell = Primitives.allocVar(state, node.name)
	local exprCell = Expr.emitExpr(state, node.expr)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, exprCell, cell)
	Primitives.resetTemps(state)
end

local function emitAssign(state: CodegenState, node: ASTNode)
	local cell = state.variables[node.name]
	if cell == nil then
		error(`Error [line {node.line or 0}]: Undefined variable '{node.name}'`)
	end

	local exprCell = Expr.emitExpr(state, node.expr)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, exprCell, cell)
	Primitives.resetTemps(state)
end

return {
	[NT.VarDecl] = emitVarDecl,
	[NT.Assign] = emitAssign
}
