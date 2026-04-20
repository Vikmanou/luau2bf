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

local function buildTable(state: CodegenState, tableName: string, tableNode: Node): TableInfo
	local info: TableInfo = { entries = {} }
	local seenKeys: { [string]: boolean } = {}
	local listIndex = 1

	for entryIndex, entry in tableNode.entries do
		local resolvedKey: Tables.TableKey
		if entry.kind == 'list' then
			resolvedKey = Tables.createListKey(listIndex)
			listIndex += 1
		elseif entry.kind == 'record' then
			resolvedKey = Tables.createRecordKey(entry.key.text)
		elseif entry.kind == 'general' then
			local key: any = Tables.resolveKey(entry.key)
			if key == nil then
				State.report(state, `Error [line {entry.location.beginLine}]: Table keys must be constant numbers, booleans, or strings`)
				continue
			end
			resolvedKey = key
		else
			State.report(state, `Error [line {entry.location.beginLine}]: Unsupported table entry kind '{entry.kind}'`)
			continue
		end

		if seenKeys[resolvedKey.id] then
			State.report(state, `Error [line {entry.location.beginLine}]: Duplicate table key '{resolvedKey.id}'`)
			continue
		end
		seenKeys[resolvedKey.id] = true

		local value = nil
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
	local sourceCells = evaluateExprs(state, values)

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
		local sourceCell = sourceCells[index]
		if lhsNode.tag == 'local' then
			local varName: string = lhsNode['local'].name.text
			if state.tables[varName] ~= nil then
				State.report(state, `Error [line {node.location.beginLine}]: Table reassignment is not supported`)
				return
			end
			local cell = state.variables[varName]
			if cell == nil then
				State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
				return
			end
			Primitives.emitZero(state, cell)
			Primitives.emitMoveAdd(state, sourceCell, cell)
		elseif lhsNode.tag == 'index' or lhsNode.tag == 'indexname' then
			assignToIndex(lhsNode, sourceCell)
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