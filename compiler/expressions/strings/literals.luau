--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local function emitString(state: CodegenState, node: Node, _: EmitExpr): number
	State.report(state, `Error [line {node.location.beginLine}]: String values are only supported as print() arguments`)
	return Primitives.allocTemp(state)
end

local function emitConcat(state: CodegenState, node: Node, _: EmitExpr): number
	local loc = node.operator.location
	State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: String concatenation (..) requires all operands to be string literals`)
	return Primitives.allocTemp(state)
end

return {
	['string'] = emitString,
	['..'] = emitConcat,
}