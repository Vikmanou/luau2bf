--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local StaticStrings = require('../../static-strings')
local TableAccess = require('../../table-access')
local Tables = require('../../tables')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local function emitNegate(state: CodegenState, cell: number): number
	local result = Primitives.allocTemp(state)
	Primitives.emitZero(state, result)
	Primitives.emitMoveSub(state, cell, result)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, result, cell)
	state.nextTemp -= 1
	return cell
end

local function emitNot(state: CodegenState, cell: number): number
	local tmp = Primitives.allocTemp(state)
	Primitives.emitBoolNot(state, cell, tmp)
	state.nextTemp -= 1
	return cell
end

local function countTableArrayLength(info: Tables.TableInfo): number
	local length = 0
	local index = 1

	while true do
		local key = Tables.createListKey(index)
		local entry = Tables.findEntry(info, key)
		if entry == nil then break end

		length = index
		index += 1
	end

	return length
end

local function emitLength(state: CodegenState, node: Node): number?
	local operand = node.operand

	local str = StaticStrings.resolve(operand)
	if str ~= nil then
		local cell = Primitives.allocTemp(state)
		Primitives.emitSetCell(state, cell, #str % 256)
		return cell
	end

	if operand.tag == 'local' then
		local varName = operand['local'].name.text
		local info = state.tables[varName]
		if info ~= nil then
			local length = countTableArrayLength(info)
			local cell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, cell, length % 256)

			return cell
		end
	end

	local info = TableAccess.resolveBaseTable(state, operand)
	if info ~= nil then
		local length = countTableArrayLength(info)
		local cell = Primitives.allocTemp(state)
		Primitives.emitSetCell(state, cell, length % 256)
		return cell
	end

	return nil
end

local function emitUnary(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local op = node.operator.text

	if op == '#' then
		local result = emitLength(state, node)
		if result ~= nil then return result end
		
		State.report(state, `Error [line {node.location.beginLine}]: '#' requires a compile-time string or a local table`)
		return Primitives.allocTemp(state)
	end

	local cell = emitExpr(state, node.operand)
	if op == '-' then return emitNegate(state, cell) end
	if op == 'not' then return emitNot(state, cell) end
	State.report(state, `Error [line {node.location.beginLine}]: Unknown unary operator '{op}'`)
	return Primitives.allocTemp(state)
end

return {
	['unary'] = emitUnary,
}