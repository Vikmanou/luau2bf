--!strict
-- Statement and block code generation - main dispatch.
-- Each submodule in the stmts/ folder returns { [NodeType] = handler }.
-- To add a new statement: create the file - no other wiring needed.

local fs = require('@lute/fs')

local Types = require('../shared/types')
type ASTNode = Types.ASTNode

local State = require('./compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('./bf-emitter')

local emitStmt: (state: CodegenState, node: ASTNode) -> ()
local emitBlock: (state: CodegenState, stmts: { ASTNode }) -> ()

local handlers: { [string]: (state: CodegenState, node: ASTNode, emitBlock: typeof(emitBlock)) -> () } = {}
local handlersReady = false

local function loadHandlers()
	if handlersReady then return end
	handlersReady = true

	local entries = fs.listdir('./compiler/statements')

	for _, entry in entries do
		if entry.type ~= 'file' or not entry.name:find('%.luau$') or entry.name == 'init.luau' then continue end

		local name = entry.name:gsub('%.luau$', '')
		local module = require(`./statements/{name}`)
		for nodeType, handler in module do
			handlers[nodeType] = handler
		end
	end
end

function emitStmt(state: CodegenState, node: ASTNode)
	loadHandlers()

	local handler = handlers[node.type]
	if not handler then
		error(`Error: Unknown statement type '{tostring(node.type)}'`)
	end
	
	handler(state, node, emitBlock)
end

function emitBlock(state: CodegenState, stmts: { ASTNode })
	for _, stmt in stmts do
		local brkCell = state.breakStack[#state.breakStack]
		if brkCell ~= nil then
			local savedTemp = state.nextTemp
			local tmpDst = Primitives.allocTemp(state)
			local tmpSrc = Primitives.allocTemp(state)
			local floor = state.nextTemp
			Primitives.emitCopy(state, brkCell, tmpDst, tmpSrc)
			Primitives.moveTo(state, tmpDst)
			Primitives.emit(state, '[-')
			Primitives.withTempFloor(state, floor, function()
				emitStmt(state, stmt)
			end)
			Primitives.moveTo(state, tmpDst)
			Primitives.emit(state, ']')
			
			state.nextTemp = savedTemp
		else
			emitStmt(state, stmt)
		end
	end
end

return { emitStmt = emitStmt, emitBlock = emitBlock }
