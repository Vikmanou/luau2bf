--!strict
-- Expression code generation - main dispatch.
-- Each submodule in expr/ returns { [key] = handler }.
-- BinOp nodes dispatch by node.op; all others dispatch by node.type.
-- To add a new expression type: create the file - no other wiring needed.

local fs = require('@lute/fs')

local Types = require('../shared/types')
type ASTNode = Types.ASTNode

local State = require('./compiler-state')
type CodegenState = State.CodegenState

local emitExpr: (state: CodegenState, node: ASTNode) -> number

local handlers: { [string]: (state: CodegenState, node: ASTNode, emitExpr: typeof(emitExpr)) -> number } = {}
local handlersReady = false

local function loadHandlers()
	if handlersReady then return end
	handlersReady = true

	local entries = fs.listdir('./compiler/expressions')

	for _, entry in entries do
		if entry.type ~= 'file' or not entry.name:find('%.luau$') or entry.name == 'init.luau' then continue end

		local name = entry.name:gsub('%.luau$', '')
		local module = (require)(`./expressions/{name}`)
		for key, handler in module do
			handlers[key] = handler
		end
	end
end

local function getKey(node: ASTNode): string
	if node.type == 'BinOp' then return node.op end
	return node.type
end

function emitExpr(state: CodegenState, node: ASTNode): number
	loadHandlers()

	local key = getKey(node)
	local handler = handlers[key]
	if not handler then
		error(`Error [line {tostring(node.line)}]: Unknown expression '{key}'`)
	end

	return handler(state, node, emitExpr)
end

return { emitExpr = emitExpr }
