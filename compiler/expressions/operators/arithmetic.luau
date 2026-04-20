--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local function emitAdd(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	Primitives.emitMoveAdd(state, rightCell, leftCell)
	state.nextTemp = rightCell
	return leftCell
end

local function emitSub(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.lhsOperand)
	local rightCell = emitExpr(state, node.rhsOperand)
	Primitives.emitMoveSub(state, rightCell, leftCell)
	state.nextTemp = rightCell
	return leftCell
end

local function emitMul(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local left = emitExpr(state, node.lhsOperand)
	local right = emitExpr(state, node.rhsOperand)
	Primitives.withTempFloor(state, state.nextTemp, function()
		local tmp0 = Primitives.allocTemp(state)
		local tmp1 = Primitives.allocTemp(state)
		Primitives.emitMulVar(state, left, right, tmp0, tmp1)
	end)
	state.nextTemp = right
	return left
end

local function emitDivMod(state: CodegenState, node: Node, emitExpr: EmitExpr, isDiv: boolean): number
	local left = emitExpr(state, node.lhsOperand)
	local right = emitExpr(state, node.rhsOperand)
	Primitives.withTempFloor(state, state.nextTemp, function()
		local quotient = Primitives.allocTemp(state)
		local counter = Primitives.allocTemp(state)
		local s1 = Primitives.allocTemp(state)
		local s2 = Primitives.allocTemp(state)
		local s3 = Primitives.allocTemp(state)
		Primitives.emitDivModVar(state, left, right, quotient, counter, s1, s2, s3)
		if isDiv then
			Primitives.emitZero(state, left)
			Primitives.emitMoveAdd(state, quotient, left)
		end
	end)
	state.nextTemp = right
	return left
end

return {
	['+'] = emitAdd,
	['-'] = emitSub,
	['*'] = emitMul,
	['/'] = function(state, node, emitExpr) return emitDivMod(state, node, emitExpr, true) end,
	['%'] = function(state, node, emitExpr) return emitDivMod(state, node, emitExpr, false) end,
}