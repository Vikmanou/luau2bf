--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')
local Builtins = require('../builtins')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local function unpackArgs(punctuated: { any }): { Node }
	local args = {}
	for _, pair in punctuated do
		table.insert(args, pair.node)
	end
	return args
end

local function emitCall(state: CodegenState, node: Node, emitExpr: EmitExpr): number
	local func = node.func :: Node

	if func.tag == 'indexname' then
		local tableExpr = func.expression :: Node
		if tableExpr.tag == 'global' then
			local ns: string = tableExpr.name.text
			local method: string = func.index.text
			local key = `{ns}.{method}`
			local handler = Builtins[key]
			if handler then
				return handler(state, unpackArgs(node.arguments), emitExpr)
			end
			local loc = node.location
			State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unsupported built-in '{key}'`)
			return Primitives.allocTemp(state)
		end
	end

	local loc = node.location
	State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unsupported call expression`)
	return Primitives.allocTemp(state)
end

return {
	['call'] = emitCall,
}