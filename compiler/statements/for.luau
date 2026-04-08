--!strict

local Types = require('../../shared/types')
local State = require('../compiler-state')
local Primitives = require('../bf-emitter')
local Expr = require('../expressions')
local Constants = require('../../shared/constants')

type ASTNode = Types.ASTNode
type CodegenState = State.CodegenState
type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local NT = Constants.NodeType

local function emitNumericFor(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local iCell = Primitives.allocVar(state, node.name)
	local stopName = `__stop__{node.name}`
	local stopCell = Primitives.allocVar(state, stopName)
	local stepName = `__step__{node.name}`
	local stepCell = Primitives.allocVar(state, stepName)

	-- Initialize i, stop, and step
	Primitives.withTempFloor(state, state.nextTemp, function()
		local startVal = Expr.emitExpr(state, node.start)
		Primitives.emitMoveAdd(state, startVal, iCell)

		local stopVal = Expr.emitExpr(state, node.stop)
		Primitives.emitMoveAdd(state, stopVal, stopCell)

		local stepExpr: ASTNode = node.step or { type = NT.NumberLit, value = 1 }
		local stepVal = Expr.emitExpr(state, stepExpr)
		Primitives.emitMoveAdd(state, stepVal, stepCell)
	end)

	-- Loop condition: i <= stop
	local function emitCondition(): number
		local condExpr: ASTNode = {
			type = 'BinOp',
			op = '<=',
			left = { type = 'VarRef', name = node.name, line = node.line },
			right = { type = 'VarRef', name = stopName, line = node.line },
		}
		return Expr.emitExpr(state, condExpr)
	end

	-- Start loop
	local condCell = emitCondition()
	Primitives.moveTo(state, condCell)
	Primitives.emit(state, '[')

	Primitives.emitZero(state, condCell)

	emitBlock(state, node.body)

	-- i += step, preserving step for the next iteration
	local tmp = Primitives.allocTemp(state)
	Primitives.emitAddVar(state, iCell, stepCell, tmp)

	-- Re-evaluate condition
	local nextCond = emitCondition()
	Primitives.emitMoveAdd(state, nextCond, condCell)

	Primitives.moveTo(state, condCell)
	Primitives.emit(state, ']')

	Primitives.resetTemps(state)
end

return {
    [NT.NumericFor] = emitNumericFor
}