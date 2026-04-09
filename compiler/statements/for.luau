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

local function isNegativeStep(stepExpr: ASTNode): boolean
	if stepExpr.type == NT.NumberLit and (stepExpr.value :: number) < 0 then
		return true
	end
    
	if stepExpr.type == NT.UnaryOp and stepExpr.op == '-' then
		local inner = stepExpr.expr :: ASTNode
		if inner and inner.type == NT.NumberLit then
			return true
		end
	end
    
	return false
end

local function emitNumericFor(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
	local brkName = `{Constants.Flags.BREAK_PREFIX}{node.line}{Constants.Flags.BREAK_SUFFIX}`
	local brkCell = Primitives.allocVar(state, brkName)
	Primitives.emitSetCell(state, brkCell, 1)
	table.insert(state.breakStack, brkCell)

	local iCell = Primitives.allocVar(state, node.name)
	local stopName = `{Constants.Flags.FOR_STOP_PREFIX}{node.name}`
	local stopCell = Primitives.allocVar(state, stopName)
	local stepName = `{Constants.Flags.FOR_STEP_PREFIX}{node.name}`
	local stepCell = Primitives.allocVar(state, stepName)

	local stepExpr: ASTNode = node.step or { type = NT.NumberLit, value = 1 }
	local negativeStep = isNegativeStep(stepExpr)

	-- Initialize i, stop, and step
	Primitives.withTempFloor(state, state.nextTemp, function()
		local startVal = Expr.emitExpr(state, node.start)
		Primitives.emitMoveAdd(state, startVal, iCell)

		local stopVal = Expr.emitExpr(state, node.stop)
		Primitives.emitMoveAdd(state, stopVal, stopCell)

		local stepVal = Expr.emitExpr(state, stepExpr)
		Primitives.emitMoveAdd(state, stepVal, stepCell)
	end)

	-- Loop condition: i <= stop (positive step) or i >= stop (negative step)
	local condOp = if negativeStep then '>=' else '<='
	local function emitCondition(): number
		local condExpr: ASTNode = {
			type = 'BinOp',
			op = condOp,
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

	Primitives.resetTemps(state)

	local stepTmp = Primitives.allocTemp(state)
	Primitives.emitAddVar(state, iCell, stepCell, stepTmp) -- i += step; stepTmp zeroed after

	local nextCond = emitCondition()

	local tmp = Primitives.allocTemp(state)
	local brkCopy = Primitives.allocTemp(state)
	local brkScr = Primitives.allocTemp(state)
	Primitives.emitMoveAdd(state, nextCond, tmp)
	Primitives.emitCopy(state, brkCell, brkCopy, brkScr)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, '[-')
	Primitives.emitMoveAdd(state, tmp, condCell)
	Primitives.moveTo(state, brkCopy)
	Primitives.emit(state, ']')
	Primitives.emitZero(state, tmp)

	Primitives.moveTo(state, condCell)
	Primitives.emit(state, ']')

	Primitives.resetTemps(state)
	table.remove(state.breakStack)
end

return {
    [NT.NumericFor] = emitNumericFor
}