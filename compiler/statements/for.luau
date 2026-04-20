--!strict

local State = require('../compiler-state')
local Primitives = require('../bf-emitter')
local Expr = require('../expressions')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local BREAK_PREFIX = '__brk_'
local BREAK_SUFFIX = '__'
local STOP_PREFIX = '__stop__'
local STEP_PREFIX = '__step__'

local function isNegativeStep(stepExpr: Node): boolean
	if stepExpr.tag == 'number' and stepExpr.value < 0 then
		return true
	end

	if stepExpr.tag == 'unary' and stepExpr.operator.text == '-' then
		local inner = stepExpr.operand
		if inner and inner.tag == 'number' then
			return true
		end
	end

	return false
end

local function copyVarToTemp(state: CodegenState, varName: string): number
	local varCell = state.variables[varName]
	local result = Primitives.allocTemp(state)
	local tmp = Primitives.allocTemp(state)
	Primitives.emitCopy(state, varCell, result, tmp)
	state.nextTemp -= 1
	return result
end

local function emitNumericFor(state: CodegenState, node: Node, emitBlock: EmitBlock)
	local iName = node.variable.name.text
	local brkName = `{BREAK_PREFIX}{node.location.beginLine}{BREAK_SUFFIX}`
	local stopName = `{STOP_PREFIX}{iName}`
	local stepName = `{STEP_PREFIX}{iName}`

	local brkCell = Primitives.allocVar(state, brkName)
	local iCell = Primitives.allocVar(state, iName)
	local stopCell = Primitives.allocVar(state, stopName)
	local stepCell = Primitives.allocVar(state, stepName)

	Primitives.emitSetCell(state, brkCell, 1)
	table.insert(state.breakStack, brkCell)

	local stepExpr = node.step or { tag = 'number', value = 1 }
	local negativeStep = isNegativeStep(stepExpr)

	Primitives.withTempFloor(state, state.nextTemp, function()
		local startVal = Expr.emitExpr(state, node.from)
		Primitives.emitMoveAdd(state, startVal, iCell)
		local stopVal = Expr.emitExpr(state, node.to)
		Primitives.emitMoveAdd(state, stopVal, stopCell)
		local stepVal = Expr.emitExpr(state, stepExpr)
		Primitives.emitMoveAdd(state, stepVal, stepCell)
	end)

	local function emitCondition(): number
		local iCopy = copyVarToTemp(state, iName)
		local stopCopy = copyVarToTemp(state, stopName)
		if negativeStep then
			return Primitives.emitGreaterOrEqualCells(state, iCopy, stopCopy)
		else
			return Primitives.emitLessOrEqualCells(state, iCopy, stopCopy)
		end
	end

	local condCell = emitCondition()
	Primitives.moveTo(state, condCell)
	Primitives.emit(state, '[')
	Primitives.emitZero(state, condCell)

	emitBlock(state, (node.body :: Node).statements)

	Primitives.resetTemps(state)

	local stepTmp = Primitives.allocTemp(state)
	Primitives.emitAddVar(state, iCell, stepCell, stepTmp)

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
	['for'] = emitNumericFor,
}
