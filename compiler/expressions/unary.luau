--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local Primitives = require('../bf-emitter')

local function emitNegate(state: CodegenState, cell: number): number
	local result = Primitives.allocTemp(state)
	Primitives.emitZero(state, result)
	Primitives.emitMoveSub(state, cell, result)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, result, cell)
	state.nextTemp -= 1
	return cell
end

local function emitNot(state: CodegenState, cell: number): number
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, cell, tmp)
	state.nextTemp -= 1
	return cell
end

local function emitUnary(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local op = node.operator.text
	local cell = emitExpr(state, node.operand)
	if op == '-' then return emitNegate(state, cell) end
	if op == 'not' then return emitNot(state, cell) end
	State.report(state, `Error [line {node.location.beginLine}]: Unknown unary operator '{op}'`)
	return Primitives.allocTemp(state)
end

return {
	['unary'] = emitUnary,
}
