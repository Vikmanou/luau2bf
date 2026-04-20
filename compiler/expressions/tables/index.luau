--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Tables = require('../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number
type TableKey = Tables.TableKey
type TableEntry = Tables.TableEntry
type TableInfo = Tables.TableInfo

local function copyCell(state: CodegenState, src: number): number
	local dst = Primitives.allocTemp(state)
	local tmp = Primitives.allocTemp(state)
	Primitives.emitCopy(state, src, dst, tmp)
	state.nextTemp -= 1
	return dst
end

local function emitKeyConstant(state: CodegenState, key: TableKey): number
	local cell = Primitives.allocTemp(state)
	if key.kind == 'number' then
		Primitives.emitSetCell(state, cell, (key.numberValue :: number) % 256)
	else
		Primitives.emitSetCell(state, cell, if key.booleanValue then 1 else 0)
	end
	return cell
end

local function emitEqualsKey(state: CodegenState, sourceCell: number, key: TableKey): number
	local sourceCopy = copyCell(state, sourceCell)
	local keyCell = emitKeyConstant(state, key)
	local result = Primitives.allocTemp(state)
	Primitives.emitMoveSub(state, keyCell, sourceCopy)
	Primitives.emitSetCell(state, result, 1)
	Primitives.moveTo(state, sourceCopy)
	Primitives.emit(state, '[')
	Primitives.moveTo(state, result)
	Primitives.emit(state, '[-]')
	Primitives.moveTo(state, sourceCopy)
	Primitives.emit(state, '[-]]')
	Primitives.emitMoveAdd(state, result, sourceCopy)
	state.nextTemp = sourceCopy + 1
	return sourceCopy
end

local function emitDirectLookup(state: CodegenState, entry: TableEntry): number
	return copyCell(state, entry.valueCell)
end

local function emitDynamicLookup(state: CodegenState, info: TableInfo, indexNode: Node, emitExpr: EmitExpr): number
	local indexCell = emitExpr(state, indexNode)
	local resultCell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, resultCell, 0)

	Primitives.withTempFloor(state, state.nextTemp, function()
		for _, entry in info.entries do
			if entry.key.kind ~= 'string' then
				local matchCell = emitEqualsKey(state, indexCell, entry.key)
				local currentCopy = copyCell(state, resultCell)
				local entryCopy = copyCell(state, entry.valueCell)
				Primitives.emitZero(state, resultCell)
				Primitives.emitSelect(state, matchCell, resultCell, entryCopy, currentCopy)
			end
		end
	end)

	return resultCell
end

local function emitIndex(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local tableExpr = node.expression :: Node
	if tableExpr.tag ~= 'local' then
		State.report(state, `Error [line {node.location.beginLine}]: Only local table indexing is supported`)
		return Primitives.allocTemp(state)
	end

	local tableName = tableExpr['local'].name.text
	local info = state.tables[tableName]
	if info == nil then
		State.report(state, `Error [line {node.location.beginLine}]: '{tableName}' is not a table`)
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
	['index'] = emitIndex
}