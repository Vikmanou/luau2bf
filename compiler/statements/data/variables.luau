--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')
local TableAccess = require('../../table-access')
local Tables = require('../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()
type TableInfo = Tables.TableInfo
type TableKey = Tables.TableKey

type TablePlanValue = Tables.TablePlanValue
type TablePlanEntry = Tables.TablePlanEntry

local function unpack(p: { any }): { Node }
	local out = {}
	for _, pair in p do
		table.insert(out, pair.node)
	end
	return out
end

local function evaluateExprs(state: CodegenState, exprs: { Node }): { number }
	local cells = {}
	for _, expr in exprs do
		table.insert(cells, Expr.emitExpr(state, expr))
	end
	return cells
end

local function moveExprsToCells(state: CodegenState, targets: { number }, sources: { number })
	for i, cell in targets do
		Primitives.emitZero(state, cell)
		Primitives.emitMoveAdd(state, sources[i], cell)
	end
	Primitives.resetTemps(state)
end

local function allocateScalarTableValue(state: CodegenState, tableName: string, entryIndex: number, valueNode: Node)
	local valueCell = Expr.emitExpr(state, valueNode)
	local targetCell = Primitives.allocVar(state, `__tbl_{tableName}_{entryIndex}`)
	Primitives.emitZero(state, targetCell)
	Primitives.emitMoveAdd(state, valueCell, targetCell)
	Primitives.resetTemps(state)
	return {
		kind = 'scalar',
		valueCell = targetCell
	}
end

local function resolveEntryKey(
	state: CodegenState,
	entry: Node,
	listIndex: number,
	seenKeys: { [string]: boolean }
): (Tables.TableKey?, number)
	local resolvedKey: Tables.TableKey?
	local nextListIndex = listIndex

	if entry.kind == 'list' then
		resolvedKey = Tables.createListKey(listIndex)
		nextListIndex = listIndex + 1
	elseif entry.kind == 'record' then
		resolvedKey = Tables.createRecordKey(entry.key.text)
	elseif entry.kind == 'general' then
		local key: any = Tables.resolveKey(entry.key)
		if key == nil then
			State.report(state, `Error [line {entry.location.beginLine}]: Table keys must be constant numbers, booleans, or strings`)
			return nil, listIndex
		end

		resolvedKey = key :: Tables.TableKey
	else
		State.report(state, `Error [line {entry.location.beginLine}]: Unsupported table entry kind '{entry.kind}'`)
		return nil, listIndex
	end

	local key = resolvedKey :: Tables.TableKey
	if seenKeys[key.id] then
		State.report(state, `Error [line {entry.location.beginLine}]: Duplicate table key '{key.id}'`)
		return nil, listIndex
	end
	seenKeys[key.id] = true

	return key, nextListIndex
end

local function buildTable(state: CodegenState, tableName: string, tableNode: Node): TableInfo
	local info: TableInfo = { entries = {} }
	local seenKeys: { [string]: boolean } = {}
	local listIndex = 1

	for entryIndex, entry in tableNode.entries do
		local resolvedKey, nextListIndex = resolveEntryKey(state, entry, listIndex, seenKeys)
		if resolvedKey == nil then continue end
		listIndex = nextListIndex

		local value
		if entry.value.tag == 'table' then
			value = {
				kind = 'table',
				tableInfo = buildTable(state, `{tableName}_{entryIndex}`, entry.value)
			}
		else
			value = allocateScalarTableValue(state, tableName, entryIndex, entry.value)
		end

		table.insert(info.entries, {
			key = resolvedKey,
			value = value
		})
	end

	return info
end

local function buildTableRhsPlan(state: CodegenState, tableNode: Node): { TablePlanEntry }
	local entries: { TablePlanEntry } = {}
	local seenKeys: { [string]: boolean } = {}
	local listIndex = 1

	for _, entry in tableNode.entries do
		local resolvedKey, nextListIndex = resolveEntryKey(state, entry, listIndex, seenKeys)
		if resolvedKey == nil then continue end
		listIndex = nextListIndex

		local value: TablePlanValue
		if entry.value.tag == 'table' then
			value = {
				kind = 'table',
				entries = buildTableRhsPlan(state, entry.value)
			}
		else
			value = {
				kind = 'scalar',
				tempCell = Expr.emitExpr(state, entry.value)
			}
		end

		table.insert(entries, {
			key = resolvedKey,
			value = value,
			line = entry.location.beginLine
		})
	end

	return entries
end

local function emitTableReassign(state: CodegenState, info: TableInfo, rhsEntries: { TablePlanEntry }, line: number)
	local seen: { [string]: boolean } = {}

	for _, rhs in rhsEntries do
		seen[rhs.key.id] = true

		local dstEntry = Tables.findEntry(info, rhs.key)
		if dstEntry == nil then
			State.report(state, `Error [line {rhs.line}]: Table reassignment introduces unsupported key '{rhs.key.id}'`)
			continue
		end

		if dstEntry.value.kind == 'table' then
			if rhs.value.kind ~= 'table' then
				State.report(state, `Error [line {rhs.line}]: Table reassignment shape mismatch at key '{rhs.key.id}'`)
				continue
			end
			emitTableReassign(state, dstEntry.value.tableInfo, rhs.value.entries, line)
		else
			if rhs.value.kind ~= 'scalar' then
				State.report(state, `Error [line {rhs.line}]: Table reassignment shape mismatch at key '{rhs.key.id}'`)
				continue
			end
			Primitives.emitZero(state, dstEntry.value.valueCell)
			Primitives.emitMoveAdd(state, rhs.value.tempCell, dstEntry.value.valueCell)
		end
	end

	for _, entry in info.entries do
		if not seen[entry.key.id] then
			State.report(state, `Error [line {line}]: Table reassignment is missing key '{entry.key.id}'`)
		end
	end
end

local function emitVarDecl(state: CodegenState, node: Node, _: EmitBlock)
	local vars = unpack(node.variables)
	local values = unpack(node.values)
	local targets = {}
	local scalarValues = {}

	for index, astLocal in vars do
		local name = astLocal.name.text
		local valueNode = values[index]
		if valueNode ~= nil and valueNode.tag == 'table' then
			state.tables[name] = buildTable(state, name, valueNode)
		else
			table.insert(targets, Primitives.allocVar(state, name))
			table.insert(scalarValues, valueNode)
		end
	end

	if #targets > 0 then
		moveExprsToCells(state, targets, evaluateExprs(state, scalarValues))
	end
end

local function emitAssign(state: CodegenState, node: Node, _: EmitBlock)
	local lhsExprs = unpack(node.variables)
	local values = unpack(node.values)
	local rhsPlans: { any } = {}

	for i, valueNode in values do
		if valueNode.tag == 'table' then
			rhsPlans[i] = { kind = 'table', entries = buildTableRhsPlan(state, valueNode) }
		else
			rhsPlans[i] = { kind = 'scalar', cell = Expr.emitExpr(state, valueNode) }
		end
	end

	local function assignToIndex(lhsNode: Node, sourceCell: number)
		local normalizedNode = if lhsNode.tag == 'indexname' then Tables.lowerIndexName(lhsNode) else lhsNode
		local constantEntry = TableAccess.resolveConstantEntry(state, normalizedNode)
		if constantEntry ~= nil then
			if constantEntry.value.kind ~= 'scalar' then
				State.report(state, `Error [line {lhsNode.location.beginLine}]: Cannot overwrite nested table with a scalar value`)
				return
			end
			
			Primitives.emitZero(state, constantEntry.value.valueCell)
			Primitives.emitMoveAdd(state, sourceCell, constantEntry.value.valueCell)
			return
		end

		local info = TableAccess.resolveBaseTable(state, normalizedNode.expression)
		if info == nil then
			State.report(state, `Error [line {lhsNode.location.beginLine}]: Only local table indexing is supported`)
			return
		end

		local indexCell = Expr.emitExpr(state, normalizedNode.index)
		for _, entry in info.entries do
			if entry.key.kind ~= 'string' and entry.value.kind == 'scalar' then
				local matchCell = TableAccess.emitEqualsKey(state, indexCell, entry.key)
				local currentCopy = TableAccess.copyCell(state, entry.value.valueCell)
				local sourceCopy = TableAccess.copyCell(state, sourceCell)
				Primitives.emitZero(state, entry.value.valueCell)
				Primitives.emitSelect(state, matchCell, entry.value.valueCell, sourceCopy, currentCopy)
			end
		end
	end

	for index, lhs in lhsExprs do
		local lhsNode = lhs :: Node
		local rhs = rhsPlans[index]
		if lhsNode.tag == 'local' then
			local varName: string = lhsNode['local'].name.text
			local tableInfo = state.tables[varName]
			local cell = state.variables[varName]

			if tableInfo ~= nil then
				if rhs == nil or rhs.kind ~= 'table' then
					State.report(state, `Error [line {node.location.beginLine}]: Table variables can only be reassigned from a table literal`)
					return
				end

				emitTableReassign(state, tableInfo, rhs.entries, node.location.beginLine)
			else
				if rhs ~= nil and rhs.kind == 'table' then
					State.report(state, `Error [line {node.location.beginLine}]: Cannot assign a table literal to scalar variable '{varName}'`)
					return
				end

				if cell == nil then
					State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
					return
				end
				if rhs == nil then
					State.report(state, `Error [line {node.location.beginLine}]: Missing assignment value`)
					return
				end

				Primitives.emitZero(state, cell)
				Primitives.emitMoveAdd(state, (rhs.cell :: number), cell)
			end
		elseif lhsNode.tag == 'index' or lhsNode.tag == 'indexname' then
			if rhs == nil then
				State.report(state, `Error [line {node.location.beginLine}]: Missing assignment value`)
				return
			end

			if rhs.kind ~= 'scalar' then
				State.report(state, `Error [line {node.location.beginLine}]: Cannot assign a table literal into an indexed table cell`)
				return
			end

			assignToIndex(lhsNode, rhs.cell)
		else
			State.report(state, `Error [line {node.location.beginLine}]: Unsupported assignment target`)
			return
		end
	end

	Primitives.resetTemps(state)
end

local function emitCompoundAssign(state: CodegenState, node: Node, _: EmitBlock)
	local lhs = node.variable :: Node
	if lhs.tag ~= 'local' then
		State.report(state, `Error [line {node.location.beginLine}]: Only local variable compound assignment is supported`)
		return
	end

	local varName: string = lhs['local'].name.text
	if state.tables[varName] ~= nil then
		State.report(state, `Error [line {node.location.beginLine}]: Table compound assignment is not supported`)
		return
	end
	local cell = state.variables[varName]
	if cell == nil then
		State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
		return
	end

	local compoundOp: string = (node.operand :: any).text
	local baseOp = compoundOp:sub(1, -2)

	local synthetic: Node = {
		tag = 'binary',
		operator = { text = baseOp },
		lhsOperand = node.variable,
		rhsOperand = node.value :: Node,
	}
	local resultCell = Expr.emitExpr(state, synthetic)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, resultCell, cell)
	Primitives.resetTemps(state)
end

return {
	['local'] = emitVarDecl,
	['assign'] = emitAssign,
	['compoundassign'] = emitCompoundAssign
}