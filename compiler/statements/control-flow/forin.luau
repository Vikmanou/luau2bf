--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local TableAccess = require('../../table-access')
local Tables = require('../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()
type TableInfo = Tables.TableInfo
type TableEntry = Tables.TableEntry

local BREAK_PREFIX = '__brk_forin_'
local BREAK_SUFFIX = '__'

local function getVarNames(node: Node): (string, string?)
	local kName = node.variables[1].node.name.text
	local vName: string? = nil
	if node.variables[2] then
		vName = node.variables[2].node.name.text
	end

	return kName, vName
end

local function resolveIterTable(state: CodegenState, node: Node): (TableInfo?, boolean)
	local valNode = node.values[1].node

	if valNode.tag == 'call' and valNode.func.tag == 'global' then
		local funcName: string = valNode.func.name.text
		if funcName == 'pairs' or funcName == 'ipairs' then
			local argNode = valNode.arguments[1].node
			local info = TableAccess.resolveBaseTable(state, argNode)
			return info, funcName == 'ipairs'
		end
	end

	local info = TableAccess.resolveBaseTable(state, valNode)
	return info, false
end

local function getEntries(info: TableInfo, ipairsMode: boolean): { TableEntry }
	if not ipairsMode then return info.entries end

	local result: { TableEntry } = {}
	
	local i = 1
	while true do
		local found = false
		for _, entry in info.entries do
			if entry.key.kind == 'number' and entry.key.numberValue == i then
				table.insert(result, entry)
				found = true
				break
			end
		end

		if not found then break end
		
		i += 1
	end

	return result
end

-- Emit BF to set kCell to the key's value.
local function emitSetKey(state: CodegenState, kCell: number, entry: TableEntry)
	if entry.key.kind == 'number' then
		Primitives.emitSetCell(state, kCell, (entry.key.numberValue :: number) % 256)
	elseif entry.key.kind == 'boolean' then
		Primitives.emitSetCell(state, kCell, if entry.key.booleanValue then 1 else 0)
	else
		-- String keys have no numeric representation; key cell is set to 0.
		Primitives.emitSetCell(state, kCell, 0)
	end
end

local function emitForIn(state: CodegenState, node: Node, emitBlock: EmitBlock)
	local line = node.location.beginLine
	local kName, vName = getVarNames(node)
	local brkName = `{BREAK_PREFIX}{line}{BREAK_SUFFIX}`

	local info, ipairsMode = resolveIterTable(state, node)
	if info == nil then
		State.report(state, `Error [line {line}]: Cannot resolve table for 'for-in' iteration`)
		return
	end

	-- Allocate loop variables (brkCell is within the +4 buffer in init.luau).
	local brkCell = Primitives.allocVar(state, brkName)
	local kCell = Primitives.allocVar(state, kName)
	local vCell: number? = if vName ~= nil then Primitives.allocVar(state, vName) else nil

	Primitives.emitSetCell(state, brkCell, 1)
	table.insert(state.breakStack, brkCell)

	local entries = getEntries(info, ipairsMode)

	for _, entry in entries do
		-- Set k and v for this iteration.
		Primitives.withTempFloor(state, state.nextTemp, function()
			emitSetKey(state, kCell, entry)

			if vCell ~= nil then
				if entry.value.kind == 'scalar' then
					local tmp = Primitives.allocTemp(state)
					Primitives.emitCopy(state, entry.value.valueCell, vCell :: number, tmp)
				else
					State.report(state, `Error [line {line}]: Cannot iterate nested table values directly`)
				end
			end
		end)

		emitBlock(state, (node.body :: Node).statements)
		Primitives.resetTemps(state)
	end

	table.remove(state.breakStack)
end

return {
	['forin'] = emitForIn,
}
