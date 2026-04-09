--!strict

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')
local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local function emitRepeatUntil(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local flag = Primitives.allocVar(state, Constants.Flags.REPEAT_FLAG)
	Primitives.emitSetCell(state, flag, 1)
	table.insert(state.breakStack, flag)

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')

	emitBlock(state, node.body)

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
	[NT.RepeatUntil] = emitRepeatUntil,
}
