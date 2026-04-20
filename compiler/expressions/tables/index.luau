--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local TableAccess = require('../../table-access')
local Tables = require('../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number
type TableEntry = Tables.TableEntry
type TableInfo = Tables.TableInfo

local function emitDirectLookup(state: CodegenState, entry: TableEntry): number
	if entry.value.kind ~= 'scalar' then
		State.report(state, 'Error: Table values must be indexed before use')
		return Primitives.allocTemp(state)
	end
	return TableAccess.copyCell(state, entry.value.valueCell)
end

local function emitDynamicLookup(state: CodegenState, info: TableInfo, indexNode: Node, emitExpr: EmitExpr): number
	local indexCell = emitExpr(state, indexNode)
	local resultCell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, resultCell, 0)

	Primitives.withTempFloor(state, state.nextTemp, function()
		for _, entry in info.entries do
			if entry.key.kind ~= 'string' and entry.value.kind == 'scalar' then
				local matchCell = TableAccess.emitEqualsKey(state, indexCell, entry.key)
				local currentCopy = TableAccess.copyCell(state, resultCell)
				local entryCopy = TableAccess.copyCell(state, entry.value.valueCell)
				Primitives.emitZero(state, resultCell)
				Primitives.emitSelect(state, matchCell, resultCell, entryCopy, currentCopy)
			end
		end
	end)

	return resultCell
end

local function emitIndex(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local info = TableAccess.resolveBaseTable(state, node.expression)
	if info == nil then
		State.report(state, `Error [line {node.location.beginLine}]: Only local table indexing is supported`)
		return Primitives.allocTemp(state)
	end

	local constantKey = Tables.resolveKey(node.index)
	if constantKey ~= nil then
		local entry = Tables.findEntry(info, constantKey)
		if entry == nil then
			State.report(state, `Error [line {node.location.beginLine}]: Table key not found`)
			return Primitives.allocTemp(state)
		end
		return emitDirectLookup(state, entry)
	end

	return emitDynamicLookup(state, info, node.index, emitExpr)
end

return {
	['index'] = emitIndex,
	['indexname'] = function(state, node, emitExpr)
		return emitIndex(state, Tables.lowerIndexName(node), emitExpr)
	end
}