--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')
local StaticStrings = require('../../static-strings')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function emitDigit(state: CodegenState, digitCell: number, cpTmp: number, scratch: number)
	Primitives.emitCopy(state, digitCell, scratch, cpTmp)
	Primitives.moveTo(state, scratch)
	Primitives.emit(state, string.rep('+', 48))
	Primitives.emit(state, '.')
	Primitives.emitZero(state, scratch)
end

local function emitPlaceValue(state: CodegenState, work: number, divisorVal: number, printed: number)
	Primitives.withTempFloor(state, state.nextTemp, function()
		local divisor = Primitives.allocTemp(state)
		local quot = Primitives.allocTemp(state)
		local cnt = Primitives.allocTemp(state)
		local sc1 = Primitives.allocTemp(state)
		local sc2 = Primitives.allocTemp(state)
		local sc3 = Primitives.allocTemp(state)
		local cpTmp = Primitives.allocTemp(state)
		local dig = Primitives.allocTemp(state)

		Primitives.emitSetCell(state, divisor, divisorVal)
		Primitives.emitDivModVar(state, work, divisor, quot, cnt, sc1, sc2, sc3)

		Primitives.emitCopy(state, quot, dig, cpTmp)
		Primitives.emitCopy(state, printed, sc1, cpTmp)
		Primitives.emitMoveAdd(state, sc1, dig)

		Primitives.moveTo(state, dig)
		Primitives.emit(state, '[')
		emitDigit(state, quot, cpTmp, sc1)
		Primitives.emitSetCell(state, printed, 1)
		Primitives.moveTo(state, dig)
		Primitives.emit(state, '[-]]')
	end)
end

local function emitPrintNumber(state: CodegenState, valCell: number)
	Primitives.withTempFloor(state, state.nextTemp, function()
		local work = Primitives.allocTemp(state)
		local printed = Primitives.allocTemp(state)
		local cpTmp = Primitives.allocTemp(state)
		local scratch = Primitives.allocTemp(state)

		Primitives.emitCopy(state, valCell, work, cpTmp)
		Primitives.emitSetCell(state, printed, 0)

		emitPlaceValue(state, work, 100, printed)
		emitPlaceValue(state, work, 10, printed)
		emitDigit(state, work, cpTmp, scratch)
	end)
end

local function emitPrintArg(state: CodegenState, argNode: Node)
	local resolvedStr = StaticStrings.resolve(argNode)
	if resolvedStr ~= nil then
		Primitives.withTempFloor(state, state.nextTemp, function()
			local cell = Primitives.allocTemp(state)
			for i = 1, #resolvedStr do
				Primitives.emitSetCell(state, cell, string.byte(resolvedStr, i))
				Primitives.emit(state, '.')
			end
		end)
		return
	end

	local val = Expr.emitExpr(state, argNode)
	emitPrintNumber(state, val)
end

local function emitPrintCall(state: CodegenState, node: Node)
	local args: { Node } = {}
	for _, pair in node.arguments :: { any } do
		table.insert(args, pair.node)
	end

	Primitives.withTempFloor(state, state.nextTemp, function()
		local sep = Primitives.allocTemp(state)

		for i, arg in args do
			emitPrintArg(state, arg)
			if i < #args then
				Primitives.emitSetCell(state, sep, 9)
				Primitives.moveTo(state, sep)
				Primitives.emit(state, '.')
			end
		end

		Primitives.emitSetCell(state, sep, 10)
		Primitives.moveTo(state, sep)
		Primitives.emit(state, '.')
		Primitives.emitZero(state, sep)
	end)
end


local function emitExprStat(state: CodegenState, node: Node, _emitBlock: EmitBlock)
	local expr = node.expression :: Node
	if expr.tag ~= 'call' then
		State.report(state, `Error [line {node.location.beginLine}]: Only function call statements are supported`)
		return
	end

	local func = expr.func :: Node
	if func.tag == 'global' and func.name.text == 'print' then
		emitPrintCall(state, expr)
		return
	end

	Primitives.withTempFloor(state, state.nextTemp, function()
		Expr.emitExpr(state, expr)
	end)
end

return {
	['expression'] = emitExprStat,
}