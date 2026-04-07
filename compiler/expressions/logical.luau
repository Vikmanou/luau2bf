--!strict
-- Logical operator codegen: and, or (short-circuit)

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

type EmitExpr = (state: CodegenState, node: ASTNode) -> number

local function emitAnd(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local res = Primitives.allocTemp(state)
	local flag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, res, 0)
	Primitives.emitSetCell(state, flag, 0)

	-- If leftCell != 0: flag = 1, zero leftCell
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '+')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[-]]')

	-- If flag: evaluate right, store in res
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')
	local savedTemp = state.nextTemp
	local rightCell = emitExpr(state, node.right)
	Primitives.emitMoveAdd(state, rightCell, res)
	state.nextTemp = savedTemp
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '-]')

	Primitives.emitMoveAdd(state, res, leftCell)
	state.nextTemp = leftCell + 1
	return leftCell
end

local function emitOr(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local res = Primitives.allocTemp(state)
	local flag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, res, 0)
	Primitives.emitSetCell(state, flag, 1)

	-- If leftCell != 0: move leftCell into res and clear flag
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, '[')
	Primitives.emitMoveAdd(state, leftCell, res)
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[-]')
	Primitives.moveTo(state, leftCell)
	Primitives.emit(state, ']')

	-- If flag still 1 (left was falsy): evaluate right
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')
	local savedTemp = state.nextTemp
	local rightCell = emitExpr(state, node.right)
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
