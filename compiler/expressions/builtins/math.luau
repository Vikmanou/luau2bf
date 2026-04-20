--!strict
-- Built-in macros for the `math` global.

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')

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

return {
	['math.max'] = emitMathMax,
	['math.min'] = emitMathMin,
}
