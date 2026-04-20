--!strict

local fs = require('@lute/fs')

local State = require('./compiler-state')
local Primitives = require('./bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }

local emitStmt: (state: CodegenState, node: Node) -> ()
local emitBlock: (state: CodegenState, stmts: { Node }) -> ()

local handlers: { [string]: (state: CodegenState, node: Node, emitBlock: typeof(emitBlock)) -> () } = {}
local handlersReady = false

local function loadHandlers()
	if handlersReady then return end
	handlersReady = true

	local entries = fs.listdir('./compiler/statements')
	for _, entry in entries do
		if entry.type ~= 'file' or not entry.name:find('%.luau$') or entry.name == 'init.luau' then continue end
		local name = entry.name:gsub('%.luau$', '')
		local module = (require)(`./statements/{name}`)
		for tag, handler in module do
			handlers[tag] = handler
		end
	end
end

function emitStmt(state: CodegenState, node: Node)
	loadHandlers()

	local handler = handlers[node.tag]
	if not handler then
		local loc = node.location
		State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unsupported statement '{node.tag}'`)
		return
	end

	handler(state, node, emitBlock)
end

function emitBlock(state: CodegenState, stmts: { Node })
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
