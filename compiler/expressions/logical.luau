--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local Primitives = require('../bf-emitter')

local function emitAnd(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local res  = Primitives.allocTemp(state)
	local flag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, res, 0)
	Primitives.emitSetCell(state, flag, 0)

	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '+')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[-]]')

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')
	local savedTemp = state.nextTemp
	local rightCell = emitExpr(state, node.rhsOperand)
	Primitives.emitMoveAdd(state, rightCell, res)
	state.nextTemp = savedTemp
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '-]')

	Primitives.emitMoveAdd(state, res, leftCell)
	state.nextTemp = leftCell + 1
	return leftCell
end

local function emitOr(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local res  = Primitives.allocTemp(state)
	local flag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, res, 0)
	Primitives.emitSetCell(state, flag, 1)

	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.emitMoveAdd(state, leftCell, res)
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[-]')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, ']')

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')
	local savedTemp = state.nextTemp
	local rightCell = emitExpr(state, node.rhsOperand)
	Primitives.emitMoveAdd(state, rightCell, res)
	state.nextTemp = savedTemp
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '-]')

	Primitives.emitMoveAdd(state, res, leftCell)
	state.nextTemp = leftCell + 1
	return leftCell
end

return {
	['and'] = emitAnd,
	['or'] = emitOr,
}
