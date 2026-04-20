--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function emitCondBranch(
	state: CodegenState,
	condition: Node,
	stmts: { Node },
	takenFlag: number,
	emitBlock: EmitBlock
)
	local savedTemp = state.nextTemp
	local condCell = Expr.emitExpr(state, condition)

	local notTaken = Primitives.allocTemp(state)
	local copyT = Primitives.allocTemp(state)
	local copyS = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, notTaken, 1)
	Primitives.emitCopy(state, takenFlag, copyT, copyS)
	Primitives.moveTo(state, copyT)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '-')
	Primitives.moveTo(state, copyT)
	Primitives.emit(state, '[-]]')

	local combined = Primitives.allocTemp(state)
	Primitives.emitZero(state, combined)
	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '[')
	Primitives.emitMoveAdd(state, condCell, combined)
	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '-]')
	Primitives.emitZero(state, condCell)

	Primitives.moveTo(state, combined)
	Primitives.emit(state, '[')
	Primitives.withTempFloor(state, state.nextTemp, function()
		emitBlock(state, stmts)
	end)
	Primitives.emitSetCell(state, takenFlag, 1)
	Primitives.moveTo(state, combined)
	Primitives.emit(state, '[-]]')

	state.nextTemp = savedTemp
end

local function emitElseBranch(
	state: CodegenState,
	stmts: { Node },
	takenFlag: number,
	emitBlock: EmitBlock
)
	local savedTemp = state.nextTemp
	local notTaken = Primitives.allocTemp(state)
	local copyT = Primitives.allocTemp(state)
	local copyS = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, notTaken, 1)
	Primitives.emitCopy(state, takenFlag, copyT, copyS)
	Primitives.moveTo(state, copyT)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '-')
	Primitives.moveTo(state, copyT)
	Primitives.emit(state, '[-]]')

	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '[')
	Primitives.withTempFloor(state, state.nextTemp, function()
		emitBlock(state, stmts)
	end)
	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '-]')

	state.nextTemp = savedTemp
end

local function emitIf(state: CodegenState, node: Node, emitBlock: EmitBlock)
	local takenFlag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, takenFlag, 0)

	emitCondBranch(state, node.condition, (node.thenBlock :: Node).statements, takenFlag, emitBlock)

	for _, clause in node.elseifs :: { any } do
		emitCondBranch(state, clause.condition, (clause.thenBlock :: Node).statements, takenFlag, emitBlock)
	end

	if node.elseBlock then
		emitElseBranch(state, (node.elseBlock :: Node).statements, takenFlag, emitBlock)
	end

	Primitives.resetTemps(state)
end

return {
	['conditional'] = emitIf,
}