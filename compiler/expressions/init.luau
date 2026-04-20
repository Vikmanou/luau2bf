--!strict

local State = require('./compiler-state')
local ModuleRegistry = require('./module-registry')
local Optimization = require('./expr-optimization')
local Primitives = require('./bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }

local emitExpr: (state: CodegenState, node: Node) -> number

local handlers: { [string]: (state: CodegenState, node: Node, emitExpr: typeof(emitExpr)) -> number } = {}
local handlersReady = false

local function loadHandlers()
	if handlersReady then return end
	local loadedHandlers = ModuleRegistry.load('./compiler/expressions', './expressions')
	handlers = loadedHandlers
	handlersReady = true
end

local function emitLiteralValue(state: CodegenState, value: number): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, value % 256)
	return cell
end

local function emitBooleanValue(state: CodegenState, value: boolean): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, if value then 1 else 0)
	return cell
end

function emitExpr(state: CodegenState, node: Node): number
	loadHandlers()

	if node.tag == 'group' then
		return emitExpr(state, node.expression)
	end

	local optimized = Optimization.optimize(node)
	if optimized ~= nil then
		if optimized.kind == 'number' then
			return emitLiteralValue(state, optimized.value)
		elseif optimized.kind == 'boolean' then
			return emitBooleanValue(state, optimized.value)
		else
			return emitExpr(state, optimized.value)
		end
	end

	if node.tag == 'binary' then
		local op = node.operator.text
		local handler = handlers[op]
		if not handler then
			local loc = node.operator.location
			State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unknown binary operator '{op}'`)
			return Primitives.allocTemp(state)
		end

		return handler(state, node, emitExpr)
	end

	local key = node.tag
	local handler = handlers[key]
	if not handler then
		local loc = node.location
		State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unknown expression '{key}'`)
		return Primitives.allocTemp(state)
	end

	return handler(state, node, emitExpr)
end

return { emitExpr = emitExpr }
