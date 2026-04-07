--!strict
-- If / elseif / else statement codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local function emitCondBranch(
	state: CodegenState,
	condition: ASTNode,
	body: { ASTNode },
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

	local bodyFloor = state.nextTemp
	Primitives.withTempFloor(state, bodyFloor, function()
		emitBlock(state, body)
	end)
	state.nextTemp = bodyFloor

	Primitives.emitSetCell(state, takenFlag, 1)

	Primitives.moveTo(state, combined)
	Primitives.emit(state, '[-]]')

	state.nextTemp = savedTemp
end

local function emitElseBranch(
	state: CodegenState,
	body: { ASTNode },
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

	local bodyFloor = state.nextTemp
	Primitives.withTempFloor(state, bodyFloor, function()
		emitBlock(state, body)
	end)
	state.nextTemp = bodyFloor

	Primitives.moveTo(state, notTaken)
	Primitives.emit(state, '-]')
	state.nextTemp = savedTemp
end

local function emitIf(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local takenFlag = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, takenFlag, 0)

	emitCondBranch(state, node.condition, node.body, takenFlag, emitBlock)

	if node.elseifClauses then
		for _, clause in node.elseifClauses do
			emitCondBranch(state, clause.condition, clause.body, takenFlag, emitBlock)
		end
	end

	if node.elseBody then
		emitElseBranch(state, node.elseBody, takenFlag, emitBlock)
	end

	Primitives.resetTemps(state)
end

return {
	[NT.If] = emitIf
}
