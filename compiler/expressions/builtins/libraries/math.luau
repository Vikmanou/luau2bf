--!strict
-- Built-in macros for the `math` global.

local State = require('../../../compiler-state')
local Primitives = require('../../../bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number


local function emitMathMax(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 2 then
		State.report(state, `Error: math.max expects 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local aCell = emitExpr(state, args[1])
	local bCell = emitExpr(state, args[2])

	Primitives.withTempFloor(state, state.nextTemp, function()
		local tmp = Primitives.allocTemp(state)
		local aCopy = Primitives.allocTemp(state)
		local bCopy = Primitives.allocTemp(state)
		local aForCmp = Primitives.allocTemp(state)
		local bForCmp = Primitives.allocTemp(state)

		Primitives.emitCopy(state, aCell, aCopy, tmp)
		Primitives.emitCopy(state, aCell, aForCmp, tmp)
		Primitives.emitCopy(state, bCell, bCopy, tmp)
		Primitives.emitCopy(state, bCell, bForCmp, tmp)
		Primitives.emitZero(state, aCell)

		local less = Primitives.emitLessThanCells(state, aForCmp, bForCmp)
		Primitives.emitSelect(state, less, aCell, bCopy, aCopy)
	end)

	state.nextTemp = bCell
	return aCell
end

local function emitMathMin(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 2 then
		State.report(state, `Error: math.min expects 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local aCell = emitExpr(state, args[1])
	local bCell = emitExpr(state, args[2])

	Primitives.withTempFloor(state, state.nextTemp, function()
		local tmp = Primitives.allocTemp(state)
		local aCopy = Primitives.allocTemp(state)
		local bCopy = Primitives.allocTemp(state)
		local aForCmp = Primitives.allocTemp(state)
		local bForCmp = Primitives.allocTemp(state)

		Primitives.emitCopy(state, aCell, aCopy, tmp)
		Primitives.emitCopy(state, aCell, aForCmp, tmp)
		Primitives.emitCopy(state, bCell, bCopy, tmp)
		Primitives.emitCopy(state, bCell, bForCmp, tmp)
		Primitives.emitZero(state, aCell)

		local less = Primitives.emitLessThanCells(state, bForCmp, aForCmp)
		Primitives.emitSelect(state, less, aCell, bCopy, aCopy)
	end)

	state.nextTemp = bCell
	return aCell
end

local function emitMathClamp(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 3 then
		State.report(state, `Error: math.clamp expects 3 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local xCell = emitExpr(state, args[1])
	local loCell = emitExpr(state, args[2])
	local hiCell = emitExpr(state, args[3])

	Primitives.withTempFloor(state, state.nextTemp, function()
		local tmp = Primitives.allocTemp(state)
		local xCopy = Primitives.allocTemp(state)
		local loCopy = Primitives.allocTemp(state)
		local xForCmp = Primitives.allocTemp(state)
		local loForCmp = Primitives.allocTemp(state)

		Primitives.emitCopy(state, xCell, xCopy, tmp)
		Primitives.emitCopy(state, xCell, xForCmp, tmp)
		Primitives.emitCopy(state, loCell, loCopy, tmp)
		Primitives.emitCopy(state, loCell, loForCmp, tmp)
		Primitives.emitZero(state, xCell)

		local lessLo = Primitives.emitLessThanCells(state, xForCmp, loForCmp)
		Primitives.emitSelect(state, lessLo, xCell, loCopy, xCopy)

		local resultCopy = Primitives.allocTemp(state)
		local resultForCmp = Primitives.allocTemp(state)
		local hiCopy = Primitives.allocTemp(state)
		local hiForCmp = Primitives.allocTemp(state)

		Primitives.emitCopy(state, xCell, resultCopy, tmp)
		Primitives.emitCopy(state, xCell, resultForCmp, tmp)
		Primitives.emitCopy(state, hiCell, hiCopy, tmp)
		Primitives.emitCopy(state, hiCell, hiForCmp, tmp)
		Primitives.emitZero(state, xCell)

		local lessHi = Primitives.emitLessThanCells(state, hiForCmp, resultForCmp)
		Primitives.emitSelect(state, lessHi, xCell, hiCopy, resultCopy)
	end)

	state.nextTemp = hiCell
	return xCell
end

local function emitMathSqrt(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 1 then
		State.report(state, `Error: math.sqrt expects 1 argument, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local xCell = emitExpr(state, args[1])

	Primitives.withTempFloor(state, state.nextTemp, function()
		local tmp = Primitives.allocTemp(state)
		local remaining = Primitives.allocTemp(state)
		local result = Primitives.allocTemp(state)
		local delta = Primitives.allocTemp(state)
		local loopFlag = Primitives.allocTemp(state)
		local remCmp = Primitives.allocTemp(state)
		local deltaCmp = Primitives.allocTemp(state)
		local notTaken = Primitives.allocTemp(state)
		local deltaCopy = Primitives.allocTemp(state)
		local inc2 = Primitives.allocTemp(state)
		local inc1 = Primitives.allocTemp(state)

		Primitives.emitCopy(state, xCell, remaining, tmp)
		Primitives.emitSetCell(state, result, 0)
		Primitives.emitSetCell(state, delta, 1)
		Primitives.emitSetCell(state, loopFlag, 1)

		Primitives.moveTo(state, loopFlag)
		Primitives.emit(state, '[')

		Primitives.emitCopy(state, remaining, remCmp, tmp)
		Primitives.emitCopy(state, delta, deltaCmp, tmp)
		local canContinue = Primitives.emitLessOrEqualCells(state, deltaCmp, remCmp)

		Primitives.emitCopy(state, delta, deltaCopy, tmp)
		Primitives.emitSetCell(state, notTaken, 1)

		Primitives.moveTo(state, canContinue)
		Primitives.emit(state, '[')
		Primitives.emitMoveSub(state, deltaCopy, remaining)
		Primitives.emitSetCell(state, inc2, 2)
		Primitives.emitMoveAdd(state, inc2, delta)
		Primitives.emitSetCell(state, inc1, 1)
		Primitives.emitMoveAdd(state, inc1, result)
		Primitives.moveTo(state, notTaken)
		Primitives.emit(state, '-')
		Primitives.moveTo(state, canContinue)
		Primitives.emit(state, '[-]]')

		Primitives.moveTo(state, notTaken)
		Primitives.emit(state, '[')
		Primitives.emitZero(state, loopFlag)
		Primitives.emitZero(state, deltaCopy)
		Primitives.moveTo(state, notTaken)
		Primitives.emit(state, '-]')

		Primitives.moveTo(state, loopFlag)
		Primitives.emit(state, ']')

		Primitives.emitZero(state, xCell)
		Primitives.emitMoveAdd(state, result, xCell)
	end)

	return xCell
end

return {
	['math.max'] = emitMathMax,
	['math.min'] = emitMathMin,
	['math.clamp'] = emitMathClamp,
	['math.sqrt'] = emitMathSqrt,
}