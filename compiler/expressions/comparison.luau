--!strict

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

type EmitExpr = (state: CodegenState, node: ASTNode) -> number

local function emitEqual(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local rightCell = emitExpr(state, node.right)
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

local function emitNotEqual(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local rightCell = emitExpr(state, node.right)
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

local function emitLessThan(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local rightCell = emitExpr(state, node.right)
	local leftCopy = Primitives.allocTemp(state)
	local copyTmp = Primitives.allocTemp(state)
	local leftTmp = Primitives.allocTemp(state)
	local flag = Primitives.allocTemp(state)

	Primitives.emitCopy(state, leftCell, leftCopy, copyTmp)
	Primitives.emitSetCell(state, leftCell, 0)

	Primitives.moveTo(state, rightCell)
	Primitives.emit(state, '[')

	Primitives.emitCopy(state, leftCopy, leftTmp, copyTmp)
	Primitives.emitSetCell(state, flag, 1)

	Primitives.moveTo(state, leftTmp)
	Primitives.emit(state, '[')
	Primitives.emitZero(state, flag)
	Primitives.moveTo(state, leftCopy)
	Primitives.emit(state, '-')
	Primitives.emitZero(state, leftTmp)
	Primitives.emit(state, ']')

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')
	Primitives.emitSetCell(state, leftCell, 1)
	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[-]]')

	Primitives.moveTo(state, rightCell)
	Primitives.emit(state, '-]')

	Primitives.emitZero(state, leftCopy)

	state.nextTemp = leftCell + 1
	return leftCell
end

-- A > B  ≡  B < A
local function emitGreaterThan(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	return emitExpr(state, { type = 'BinOp', op = '<', left = node.right, right = node.left })
end

-- A <= B  ≡  NOT (B < A)
local function emitLessOrEqual(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local inner = emitExpr(state, { type = 'BinOp', op = '<', left = node.right, right = node.left })
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, inner, tmp)
	state.nextTemp = inner + 1
	return inner
end

-- A >= B  ≡  NOT (A < B)
local function emitGreaterOrEqual(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local inner = emitExpr(state, { type = 'BinOp', op = '<', left = node.left, right = node.right })
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, inner, tmp)
	state.nextTemp = inner + 1
	return inner
end


return {
	['=='] = emitEqual,
	['~='] = emitNotEqual,
	['<'] = emitLessThan,
	['>'] = emitGreaterThan,
	['<='] = emitLessOrEqual,
	['>='] = emitGreaterOrEqual,
}
