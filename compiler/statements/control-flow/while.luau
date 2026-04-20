--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local BREAK_PREFIX = '__brk_'
local BREAK_SUFFIX = '__'

local function emitWhile(state: CodegenState, node: Node, emitBlock: EmitBlock)
	local line = (node.location :: any).beginLine
	local brkName = `{BREAK_PREFIX}{line}{BREAK_SUFFIX}`
	local brkCell = Primitives.allocVar(state, brkName)
	Primitives.emitSetCell(state, brkCell, 1)
	table.insert(state.breakStack, brkCell)

	local condCell = Expr.emitExpr(state, node.condition)
	Primitives.moveTo(state, condCell)
	Primitives.emit(state, '[')
	Primitives.resetTemps(state)

	emitBlock(state, (node.body :: Node).statements)

	Primitives.resetTemps(state)
	local condCell2 = Expr.emitExpr(state, node.condition)

	local tmp = Primitives.allocTemp(state)
	local brkCopy = Primitives.allocTemp(state)
	local brkScr = Primitives.allocTemp(state)
	Primitives.emitMoveAdd(state, condCell2, tmp)
	Primitives.emitCopy(state, brkCell, brkCopy, brkScr)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, '[-')
	Primitives.emitMoveAdd(state, tmp, condCell2)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, ']')
	Primitives.emitZero(state, tmp)

	Primitives.moveTo(state, condCell2)
	Primitives.emit(state, ']')
	Primitives.resetTemps(state)

	table.remove(state.breakStack)
end

return {
	['while'] = emitWhile,
}