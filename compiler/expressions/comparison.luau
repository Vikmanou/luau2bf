--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local Primitives = require('../bf-emitter')

local function emitEqual(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	local result = Primitives.allocTemp(state)
	Primitives.emitMoveSub(state, rightCell, leftCell)
	Primitives.emitSetCell(state, result, 1)
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, result)
	Primitives.emit(state, '[-]')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[-]]')
	Primitives.emitMoveAdd(state, result, leftCell)
	state.nextTemp = leftCell + 1
	return leftCell
end

local function emitNotEqual(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	local result = Primitives.allocTemp(state)
	Primitives.emitMoveSub(state, rightCell, leftCell)
	Primitives.emitSetCell(state, result, 0)
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, result)
	Primitives.emit(state, '+')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[-]]')
	Primitives.emitMoveAdd(state, result, leftCell)
	state.nextTemp = leftCell + 1
	return leftCell
end

local function emitLessThan(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	return Primitives.emitLessThanCells(state, leftCell, rightCell)
end

-- A > B  ≡  B < A
local function emitGreaterThan(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	return Primitives.emitLessThanCells(state, rightCell, leftCell)
end

-- A <= B  ≡  NOT (B < A)
local function emitLessOrEqual(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	return Primitives.emitLessOrEqualCells(state, leftCell, rightCell)
end

-- A >= B  ≡  NOT (A < B)
local function emitGreaterOrEqual(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	return Primitives.emitGreaterOrEqualCells(state, leftCell, rightCell)
end

return {
	['=='] = emitEqual,
	['~='] = emitNotEqual,
	['<'] = emitLessThan,
	['>'] = emitGreaterThan,
	['<='] = emitLessOrEqual,
	['>='] = emitGreaterOrEqual,
}
