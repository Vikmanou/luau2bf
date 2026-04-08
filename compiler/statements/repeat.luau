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
	local flag = Primitives.allocVar(state, '__repeat_flag__')
	Primitives.emitSetCell(state, flag, 1)

	Primitives.moveTo(state, flag)
	Primitives.emit(state, '[')

	emitBlock(state, node.body)

	-- Evaluate condition; if true, zero the flag to exit; otherwise keep it nonzero.
	Primitives.resetTemps(state)
	local condCell = Expr.emitExpr(state, node.condition)

	-- flag = not condition
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, condCell, tmp)
	Primitives.emitZero(state, flag)
	Primitives.emitMoveAdd(state, condCell, flag)

	Primitives.moveTo(state, flag)
	Primitives.emit(state, ']')

	Primitives.resetTemps(state)
end

return {
	[NT.RepeatUntil] = emitRepeatUntil,
}
