--!strict
-- While loop codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local function emitWhile(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local brkName = `{Constants.Flags.BREAK_PREFIX}{node.line}{Constants.Flags.BREAK_SUFFIX}`
	local brkCell = Primitives.allocVar(state, brkName)
	Primitives.emitSetCell(state, brkCell, 1)
	table.insert(state.breakStack, brkCell)

	local condCell = Expr.emitExpr(state, node.condition)
	Primitives.moveTo(state, condCell)
	Primitives.emit(state, '[')
	Primitives.resetTemps(state)

	emitBlock(state, node.body)

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
	[NT.While] = emitWhile
}
