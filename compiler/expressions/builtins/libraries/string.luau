--!strict

local State = require('../../../compiler-state')
local Primitives = require('../../../bf-emitter')
local StaticStrings = require('../../../static-strings')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local function emitConstantNumber(state: CodegenState, value: number): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, value % 256)
	return cell
end

local function emitStringLen(state: CodegenState, args: { Node }, _emitExpr: EmitExpr): number
	if #args ~= 1 then
		State.report(state, `Error: string.len expects 1 argument, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local value = StaticStrings.resolve(args[1])
	if value == nil then
		State.report(state, 'Error: string.len requires a compile-time string argument')
		return Primitives.allocTemp(state)
	end

	return emitConstantNumber(state, #value)
end

local function emitStringByte(state: CodegenState, args: { Node }, _emitExpr: EmitExpr): number
	if #args < 1 or #args > 2 then
		State.report(state, `Error: string.byte expects 1 or 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local value = StaticStrings.resolve(args[1])
	if value == nil then
		State.report(state, 'Error: string.byte requires a compile-time string argument')
		return Primitives.allocTemp(state)
	end

	local index = 1
	if args[2] ~= nil then
		local resolvedIndex = StaticStrings.resolveNumber(args[2])
		if resolvedIndex == nil or resolvedIndex % 1 ~= 0 then
			State.report(state, 'Error: string.byte index must be an integer literal')
			return Primitives.allocTemp(state)
		end
		index = resolvedIndex
	end

	local byteValue = string.byte(value, index)
	if byteValue == nil then
		State.report(state, 'Error: string.byte index is out of range')
		return Primitives.allocTemp(state)
	end

	return emitConstantNumber(state, byteValue)
end

local function emitStringSub(state: CodegenState, args: { Node }, _emitExpr: EmitExpr): number
	if #args < 2 or #args > 3 then
		State.report(state, `Error: string.sub expects 2 or 3 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local value = StaticStrings.resolve(args[1])
	if value == nil then
		State.report(state, 'Error: string.sub requires a compile-time string argument')
		return Primitives.allocTemp(state)
	end

	local startIndex = StaticStrings.resolveNumber(args[2])
	if startIndex == nil or startIndex % 1 ~= 0 then
		State.report(state, 'Error: string.sub start index must be an integer literal')
		return Primitives.allocTemp(state)
	end

	local endIndex
	if args[3] ~= nil then
		endIndex = StaticStrings.resolveNumber(args[3])
		if endIndex == nil or endIndex % 1 ~= 0 then
			State.report(state, 'Error: string.sub end index must be an integer literal')
			return Primitives.allocTemp(state)
		end
	end

	State.report(state, `Error: string.sub returns a string which cannot be stored as a scalar value.`)
	return Primitives.allocTemp(state)
end

local function emitStringRep(state: CodegenState, args: { Node }, _emitExpr: EmitExpr): number
	if #args ~= 2 then
		State.report(state, `Error: string.rep expects 2 arguments, got {#args}`)
		return Primitives.allocTemp(state)
	end

	local value = StaticStrings.resolve(args[1])
	if value == nil then
		State.report(state, 'Error: string.rep requires a compile-time string argument')
		return Primitives.allocTemp(state)
	end

	local count = StaticStrings.resolveNumber(args[2])
	if count == nil or count < 0 or count % 1 ~= 0 then
		State.report(state, 'Error: string.rep count must be a non-negative integer literal')
		return Primitives.allocTemp(state)
	end

	State.report(state, 'Error: string.rep returns a string which cannot be stored as a scalar value.')
	return Primitives.allocTemp(state)
end

return {
	['string.len'] = emitStringLen,
	['string.byte'] = emitStringByte,
	['string.sub'] = emitStringSub,
	['string.rep'] = emitStringRep,
}