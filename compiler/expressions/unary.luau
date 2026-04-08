--!strict
-- Unary operator codegen: negation (-) and logical not.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

type EmitExpr = (state: CodegenState, node: ASTNode) -> number

local function emitNegate(state: CodegenState, exprCell: number): number
	local result = Primitives.allocTemp(state)
	Primitives.emitZero(state, result)
	Primitives.emitMoveSub(state, exprCell, result)
	Primitives.emitZero(state, exprCell)
	Primitives.emitMoveAdd(state, result, exprCell)
	state.nextTemp -= 1
	return exprCell
end

local function emitNot(state: CodegenState, exprCell: number): number
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, exprCell, tmp)
	state.nextTemp -= 1
	return exprCell
end

local function emitUnary(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local exprCell = emitExpr(state, node.expr)

	if node.op == '-' then return emitNegate(state, exprCell) end
	if node.op == 'not' then return emitNot(state, exprCell) end

	error(`Error [line {tostring(node.line)}]: Unknown unary operator '{tostring(node.op)}'`)
end

return {
	[NT.UnaryOp] = emitUnary,
}
