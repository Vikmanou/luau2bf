--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Expr = require('../../expressions')
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

local function allocateTableEntryValue(state: CodegenState, tableName: string, entryIndex: number, valueNode: Node): number
	if valueNode.tag == 'table' then
		State.report(state, `Error [line {valueNode.location.beginLine}]: Nested tables are not supported`)
		return Primitives.allocVar(state, `__tbl_{tableName}_{entryIndex}_invalid`)
	end

	local valueCell = Expr.emitExpr(state, valueNode)
	local targetCell = Primitives.allocVar(state, `__tbl_{tableName}_{entryIndex}`)
	Primitives.emitZero(state, targetCell)
	Primitives.emitMoveAdd(state, valueCell, targetCell)
	Primitives.resetTemps(state)
	return targetCell
end

local function buildTable(state: CodegenState, tableName: string, tableNode: Node): TableInfo
	local info: TableInfo = { entries = {} }
	local seenKeys: { [string]: boolean } = {}
	local listIndex = 1

	for entryIndex, entry in tableNode.entries do
		local key = nil
		if entry.kind == 'list' then
			key = Tables.createListKey(listIndex)
			listIndex += 1
		elseif entry.kind == 'record' then
			key = Tables.createRecordKey(entry.key.text)
		elseif entry.kind == 'general' then
			key = Tables.resolveKey(entry.key)
			if key == nil then
				State.report(state, `Error [line {entry.location.beginLine}]: Table keys must be constant numbers, booleans, or strings`)
				continue
			end
		else
			State.report(state, `Error [line {entry.location.beginLine}]: Unsupported table entry kind '{entry.kind}'`)
			continue
		end

		if seenKeys[key.id] then
			State.report(state, `Error [line {entry.location.beginLine}]: Duplicate table key '{key.id}'`)
			continue
		end
		seenKeys[key.id] = true

		local valueCell = allocateTableEntryValue(state, tableName, entryIndex, entry.value)
		table.insert(info.entries, {
			key = key,
			valueCell = valueCell
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
	local targets = {}
	for _, lhs in lhsExprs do
		local lhsNode = lhs :: Node
		if lhsNode.tag ~= 'local' then
			State.report(state, `Error [line {node.location.beginLine}]: Only local variable assignment is supported`)
			return
		end
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
		table.insert(targets, cell)
	end
	moveExprsToCells(state, targets, evaluateExprs(state, values))
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