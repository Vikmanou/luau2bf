--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function emitLocalFunction(state: CodegenState, node: Node, _: EmitBlock)
	local name: string = node.name.name.text
	local func = node.func
	if func == nil or func.body == nil then
		State.report(state, `Error [line {node.location.beginLine}]: Malformed function declaration`)
		return
	end

	local params: { string } = {}
	if func.parameters ~= nil then
		for _, pair in func.parameters do
			table.insert(params, pair.node.name.text)
		end
	end

	state.functions[name] = {
		params = params,
		body = func.body,
		line = node.location.beginLine,
	}
end

local function findTopReturn(state: CodegenState): (number?, State.FlowEntry?)
	for i = #state.breakStack, 1, -1 do
		local frame = state.breakStack[i]
		if frame.kind == 'return' then
			return i, frame
		end
	end
	return nil, nil
end

local function isTailCallToSelf(expr: Node, fname: string?): boolean
	if fname == nil then return false end
	if expr.tag ~= 'call' then return false end
	local func = expr.func
	if func == nil or func.tag ~= 'local' then return false end
	return func['local'].name.text == fname
end

local function unpackArgs(punctuated: { any }): { Node }
	local args = {}
	for _, pair in punctuated do
		table.insert(args, pair.node)
	end
	return args
end

local function emitTailCall(state: CodegenState, idx: number, frame: State.FlowEntry, callNode: Node)
	local paramCells = frame.paramCells or {}
	local argNodes = unpackArgs(callNode.arguments)

	local tempCells: { number } = {}
	local savedNextTemp = state.nextTemp
	for i = 1, #paramCells do
		local argNode = argNodes[i]
		if argNode == nil then continue end
		local srcCell = Expr.emitExpr(state, argNode)
		local tmp = Primitives.allocTemp(state)
		Primitives.emitSetCell(state, tmp, 0)
		Primitives.emitMoveAdd(state, srcCell, tmp)
		tempCells[i] = tmp
	end

	for i, paramCell in paramCells do
		Primitives.emitZero(state, paramCell)
		if tempCells[i] ~= nil then
			Primitives.emitMoveAdd(state, tempCells[i], paramCell)
		end
	end

	state.nextTemp = savedNextTemp

	if frame.continueCell ~= nil then
		Primitives.emitSetCell(state, frame.continueCell, 1)
	end

	for i = #state.breakStack, idx, -1 do
		Primitives.emitZero(state, state.breakStack[i].cell)
	end
	Primitives.resetTemps(state)
end

local function emitReturn(state: CodegenState, node: Node, _: EmitBlock)
	local idx, frame = findTopReturn(state)
	if idx == nil or frame == nil then
		State.report(state, `Error [line {node.location.beginLine}]: 'return' used outside of a function`)
		return
	end

	local exprs: { Node } = {}
	if node.expressions ~= nil then
		for _, pair in node.expressions do
			table.insert(exprs, pair.node)
		end
	end

	if #exprs > 1 then
		State.report(state, `Error [line {node.location.beginLine}]: Multiple return values are not supported`)
		return
	end

	if #exprs == 1 and isTailCallToSelf(exprs[1], frame.funcName) then
		emitTailCall(state, idx, frame, exprs[1])
		return
	end

	if #exprs == 1 then
		local resultCell = frame.resultCell
		if resultCell == nil then
			State.report(state, `Error [line {node.location.beginLine}]: Internal: return frame missing result cell`)
			return
		end
		local valCell = Expr.emitExpr(state, exprs[1])
		Primitives.emitZero(state, resultCell)
		Primitives.emitMoveAdd(state, valCell, resultCell)
		Primitives.resetTemps(state)
	end

	for i = #state.breakStack, idx, -1 do
		Primitives.emitZero(state, state.breakStack[i].cell)
	end
end

return {
	['localfunction'] = emitLocalFunction,
	['return'] = emitReturn,
}
