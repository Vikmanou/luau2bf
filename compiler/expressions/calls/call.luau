--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Builtins = require('../builtins')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local Statements: any
local function getStatements()
	if Statements == nil then
		Statements = require('../../statements')
	end
	return Statements
end

local function unpackArgs(punctuated: { any }): { Node }
	local args = {}
	for _, pair in punctuated do
		table.insert(args, pair.node)
	end
	return args
end

local function snapshotVars(state: CodegenState): ({ [string]: number }, { [string]: any })
	local v: { [string]: number } = {}
	for k, val in state.variables do v[k] = val end
	local t: { [string]: any } = {}
	for k, val in state.tables do t[k] = val end
	return v, t
end

local function emitUserCall(state: CodegenState, fname: string, def: any, argNodes: { Node }, emitExpr: EmitExpr, line: number): number
	for _, name in state.callStack do
		if name == fname then
			State.report(state, `Error [line {line}]: Recursive call to '{fname}' is not supported`)
			return Primitives.allocTemp(state)
		end
	end

	local params: { string } = def.params
	local argCells: { number } = {}
	for i = 1, #params do
		argCells[i] = Primitives.allocTemp(state)
		Primitives.emitSetCell(state, argCells[i], 0)
	end

	local savedNextTemp = state.nextTemp
	for i = 1, #params do
		local argNode = argNodes[i]
		if argNode == nil then continue end
		local srcCell = emitExpr(state, argNode)
		Primitives.emitZero(state, argCells[i])
		Primitives.emitMoveAdd(state, srcCell, argCells[i])
		state.nextTemp = savedNextTemp
	end

	local resultCell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, resultCell, 0)

	local savedVars, savedTables = snapshotVars(state)
	local savedNextVar = state.nextVarCell

	local continueCell = Primitives.allocVar(state, `__cont_{fname}__`)
	local gateCell = Primitives.allocVar(state, `__gate_{fname}__`)
	Primitives.emitSetCell(state, continueCell, 1)

	local paramCells: { number } = {}
	for i, paramName in params do
		local paramCell = Primitives.allocVar(state, paramName)
		Primitives.emitZero(state, paramCell)
		Primitives.emitMoveAdd(state, argCells[i], paramCell)
		paramCells[i] = paramCell
	end

	Primitives.moveTo(state, continueCell)
	Primitives.emit(state, '[')
	Primitives.emitSetCell(state, continueCell, 0)
	Primitives.emitSetCell(state, gateCell, 1)

	table.insert(state.breakStack, {
		kind = 'return',
		cell = gateCell,
		resultCell = resultCell,
		continueCell = continueCell,
		funcName = fname,
		paramCells = paramCells,
	})
	table.insert(state.callStack, fname)

	local floor = state.nextTemp
	Primitives.withTempFloor(state, floor, function()
		local stmtsMod = getStatements()
		stmtsMod.emitBlock(state, (def.body :: Node).statements)
	end)

	table.remove(state.callStack)
	table.remove(state.breakStack)

	Primitives.moveTo(state, continueCell)
	Primitives.emit(state, ']')

	state.variables = savedVars
	state.tables = savedTables
	state.nextVarCell = savedNextVar

	return resultCell
end

local function emitCall(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local func = node.func :: Node

	if func.tag == 'indexname' then
		local tableExpr = func.expression :: Node
		if tableExpr.tag == 'global' then
			local ns: string = tableExpr.name.text
			local method: string = func.index.text
			local key = `{ns}.{method}`
			local handler = Builtins[key]
			if handler then
				return handler(state, unpackArgs(node.arguments), emitExpr)
			end
			local loc = node.location
			State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unsupported built-in '{key}'`)
			return Primitives.allocTemp(state)
		end
	end

	if func.tag == 'local' then
		local fname: string = func['local'].name.text
		local def = state.functions[fname]
		if def ~= nil then
			local loc = node.location
			local line = if loc then loc.beginLine else 0
			return emitUserCall(state, fname, def, unpackArgs(node.arguments), emitExpr, line)
		end
	end

	local loc = node.location
	State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unsupported call expression`)
	return Primitives.allocTemp(state)
end

return {
	['call'] = emitCall,
}
