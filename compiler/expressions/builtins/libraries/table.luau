--!strict

local State = require('../../../compiler-state')
local Primitives = require('../../../bf-emitter')
local StaticStrings = require('../../../static-strings')
local TableAccess = require('../../../table-access')
local Tables = require('../../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number
type TableEntry = Tables.TableEntry
type TableInfo = Tables.TableInfo


local function resolveTable(state: CodegenState, node: Node): TableInfo?
	local info = TableAccess.resolveBaseTable(state, node)
	if info == nil then
		State.report(state, 'Error: table library functions require a compile-time-known local table as the first argument')
	end
	return info
end

local function tableVarName(node: Node): string
	if node.tag == 'local' then
		return node['local'].name.text
	end
	return 'anon'
end

local function maxNumericKey(info: TableInfo): number
	local max = 0
	for _, entry in info.entries do
		if entry.key.kind == 'number' then
			max = math.max(max, entry.key.numberValue :: number)
		end
	end
	return max
end


local function emitTableInsert(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 2 and #args ~= 3 then
		State.report(state, `Error: table.insert expects 2 or 3 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local info = resolveTable(state, args[1])
	if info == nil then
		return Primitives.allocTemp(state)
	end

	local insertAt: number
	local valueNode: Node

	if #args == 2 then
		insertAt = maxNumericKey(info) + 1
		valueNode = args[2]
	else
		local constPos = StaticStrings.resolveNumber(args[2])
		if constPos == nil or constPos % 1 ~= 0 or constPos < 1 then
			State.report(state, 'Error: table.insert pos must be a positive integer literal')
			return Primitives.allocTemp(state)
		end
		insertAt = constPos
		valueNode = args[3]
	end

	local tblName = tableVarName(args[1])
	local newCellName = `__tbl_{tblName}_ins{state.nextVarCell}`

	local valueCell = emitExpr(state, valueNode)

	local targetCell = Primitives.allocVar(state, newCellName)
	Primitives.emitZero(state, targetCell)
	Primitives.emitMoveAdd(state, valueCell, targetCell)
	Primitives.resetTemps(state)

	-- Re-key existing entries at or above insertAt upward by 1.
	for _, entry in info.entries do
		if entry.key.kind == 'number' and (entry.key.numberValue :: number) >= insertAt then
			entry.key = Tables.createListKey((entry.key.numberValue :: number) + 1)
		end
	end

	table.insert(info.entries, {
		key = Tables.createListKey(insertAt),
		value = { kind = 'scalar', valueCell = targetCell }
	})

	return Primitives.allocTemp(state)
end


local function emitTableRemove(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args < 1 or #args > 2 then
		State.report(state, `Error: table.remove expects 1 or 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local info = resolveTable(state, args[1])
	if info == nil then
		return Primitives.allocTemp(state)
	end

	local removeAt: number

	if #args == 1 then
		removeAt = maxNumericKey(info)
		if removeAt == 0 then
			State.report(state, 'Error: table.remove called on an empty table')
			return Primitives.allocTemp(state)
		end
	else
		local constPos = StaticStrings.resolveNumber(args[2])
		if constPos == nil or constPos % 1 ~= 0 or constPos < 1 then
			State.report(state, 'Error: table.remove pos must be a positive integer literal')
			return Primitives.allocTemp(state)
		end
		removeAt = constPos
	end

	-- Find the entry to remove.
	local removeIdx: number?
	local removeEntry: TableEntry?
	for i, entry in info.entries do
		if entry.key.kind == 'number' and entry.key.numberValue == removeAt then
			removeIdx = i
			removeEntry = entry
			break
		end
	end

	if removeEntry == nil then
		State.report(state, `Error: table.remove: index {removeAt} not found in table`)
		return Primitives.allocTemp(state)
	end

	local entry = removeEntry :: TableEntry
	if entry.value.kind ~= 'scalar' then
		State.report(state, `Error: table.remove: cannot remove a nested-table entry`)
		return Primitives.allocTemp(state)
	end

	-- Copy removed value to result cell.
	local resultCell = TableAccess.copyCell(state, entry.value.valueCell)

	Primitives.emitZero(state, entry.value.valueCell)

	-- Remove the entry and re-key everything above removeAt downward by 1.
	table.remove(info.entries, removeIdx :: number)
	for _, e in info.entries do
		if e.key.kind == 'number' and (e.key.numberValue :: number) > removeAt then
			e.key = Tables.createListKey((e.key.numberValue :: number) - 1)
		end
	end

	return resultCell
end


local function emitTableFind(state: CodegenState, args: { Node }, emitExpr: EmitExpr): number
	if #args ~= 2 then
		State.report(state, `Error: table.find expects 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local info = resolveTable(state, args[1])
	if info == nil then
		return Primitives.allocTemp(state)
	end

	local needleCell = emitExpr(state, args[2])

	-- resultCell = 0 (not found), notFoundCell = 1 (still searching).
	local resultCell = Primitives.allocTemp(state)
	local notFoundCell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, resultCell, 0)
	Primitives.emitSetCell(state, notFoundCell, 1)

	local floor = state.nextTemp

	-- Collect numeric scalar entries sorted by ascending key.
	local numericEntries: { { index: number, valueCell: number } } = {}
	for _, entry in info.entries do
		if entry.key.kind == 'number' and entry.value.kind == 'scalar' then
			table.insert(numericEntries, {
				index = entry.key.numberValue :: number,
				valueCell = entry.value.valueCell
			})
		end
	end
	table.sort(numericEntries, function(a, b) return a.index < b.index end)

	for _, item in numericEntries do
		Primitives.withTempFloor(state, floor, function()
			local tmp = Primitives.allocTemp(state)
			local needleCopy = Primitives.allocTemp(state)
			local entryCopy = Primitives.allocTemp(state)
			Primitives.emitCopy(state, needleCell, needleCopy, tmp)
			Primitives.emitCopy(state, item.valueCell, entryCopy, tmp)

			-- equalCell = (entryCopy == needleCopy): subtract then NOT.
			Primitives.emitMoveSub(state, needleCopy, entryCopy)
			Primitives.emitBoolNot(state, entryCopy, tmp)
			local equalCell = entryCopy

			-- condCell = equalCell AND notFoundCell.
			local notFoundCopy = Primitives.allocTemp(state)
			Primitives.emitCopy(state, notFoundCell, notFoundCopy, tmp)
			local mulTmp0 = Primitives.allocTemp(state)
			local mulTmp1 = Primitives.allocTemp(state)
			Primitives.emitMulVar(state, equalCell, notFoundCopy, mulTmp0, mulTmp1)
			local condCell = equalCell

			-- Copy condCell — emitSelect consumes it so we need two copies.
			local condCopy = Primitives.allocTemp(state)
			Primitives.emitCopy(state, condCell, condCopy, tmp)

			-- if condCell: resultCell = item.index.
			local resultSave = Primitives.allocTemp(state)
			Primitives.emitCopy(state, resultCell, resultSave, tmp)
			Primitives.emitZero(state, resultCell)
			local kCell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, kCell, item.index % 256)
			Primitives.emitSelect(state, condCell, resultCell, kCell, resultSave)

			-- if condCopy: notFoundCell = 0 (stop searching).
			local notFoundSave = Primitives.allocTemp(state)
			Primitives.emitCopy(state, notFoundCell, notFoundSave, tmp)
			Primitives.emitZero(state, notFoundCell)
			local zeroCell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, zeroCell, 0)
			Primitives.emitSelect(state, condCopy, notFoundCell, zeroCell, notFoundSave)
		end)
	end

	-- Free needleCell and notFoundCell
	state.nextTemp = notFoundCell
	return resultCell
end


return {
	['table.insert'] = emitTableInsert,
	['table.remove'] = emitTableRemove,
	['table.find'] = emitTableFind,
}
