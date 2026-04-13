--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local Primitives = require('../bf-emitter')
local Expr = require('../expressions')

local REPEAT_FLAG = '__repeat_flag__'

local function emitRepeatUntil(state: CodegenState, node: Node, emitBlock: EmitBlock)
	local flag = Primitives.allocVar(state, REPEAT_FLAG)
	Primitives.emitSetCell(state, flag, 1)
	table.insert(state.breakStack, flag)

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')

	emitBlock(state, (node.body :: Node).statements)

	Primitives.resetTemps(state)
	local brkCopy = Primitives.allocTemp(state)
	local brkScr = Primitives.allocTemp(state)
	local floor = state.nextTemp
	Primitives.emitCopy(state, flag, brkCopy, brkScr)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, '[-')
	Primitives.withTempFloor(state, floor, function()
		local condCell = Expr.emitExpr(state, node.condition)
		local tmp = Primitives.allocTemp(state)
		Primitives.emitBoolNot(state, condCell, tmp)
		Primitives.emitZero(state, flag)
		Primitives.emitMoveAdd(state, condCell, flag)
	end)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, ']')

	Primitives.moveTo(state, flag)
	Primitives.emit(state, ']')

	Primitives.resetTemps(state)
	table.remove(state.breakStack)
end

return {
	['repeat'] = emitRepeatUntil,
}
