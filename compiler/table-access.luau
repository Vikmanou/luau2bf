--!strict

local State = require('./compiler-state')
local Primitives = require('./bf-emitter')
local Tables = require('./tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type TableKey = Tables.TableKey
type TableEntry = Tables.TableEntry
type TableInfo = Tables.TableInfo

local TableAccess = {}

function TableAccess.copyCell(state: CodegenState, src: number): number
	local dst = Primitives.allocTemp(state)
	local tmp = Primitives.allocTemp(state)
	Primitives.emitCopy(state, src, dst, tmp)
	state.nextTemp -= 1
	return dst
end

function TableAccess.emitKeyConstant(state: CodegenState, key: TableKey): number
	local cell = Primitives.allocTemp(state)
	if key.kind == 'number' then
		Primitives.emitSetCell(state, cell, (key.numberValue :: number) % 256)
	elseif key.kind == 'boolean' then
		Primitives.emitSetCell(state, cell, if key.booleanValue then 1 else 0)
	else
		Primitives.emitSetCell(state, cell, 0)
	end
	return cell
end

function TableAccess.emitEqualsKey(state: CodegenState, sourceCell: number, key: TableKey): number
	local sourceCopy = TableAccess.copyCell(state, sourceCell)
	local keyCell = TableAccess.emitKeyConstant(state, key)
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

local function resolveTableInfo(state: CodegenState, node: Node): TableInfo?
	if node.tag == 'group' then
		return resolveTableInfo(state, node.expression)
	end

	if node.tag == 'local' then
		return state.tables[node['local'].name.text]
	end

	if node.tag == 'indexname' then
		return resolveTableInfo(state, Tables.lowerIndexName(node))
	end

	if node.tag == 'index' then
		local parent = resolveTableInfo(state, node.expression)
		if parent == nil then
			return nil
		end

		local key = Tables.resolveKey(node.index)
		if key == nil then
			return nil
		end

		local entry = Tables.findEntry(parent, key)
		if entry == nil or entry.value.kind ~= 'table' then
			return nil
		end

		return entry.value.tableInfo
	end

	return nil
end

function TableAccess.resolveBaseTable(state: CodegenState, node: Node): TableInfo?
	return resolveTableInfo(state, node)
end

function TableAccess.resolveConstantEntry(state: CodegenState, node: Node): TableEntry?
	local base = resolveTableInfo(state, node.expression)
	if base == nil then
		return nil
	end

	local key = Tables.resolveKey(node.index)
	if key == nil then
		return nil
	end

	return Tables.findEntry(base, key)
end

return TableAccess