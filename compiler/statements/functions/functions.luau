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
