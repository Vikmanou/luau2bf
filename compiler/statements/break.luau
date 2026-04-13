--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local Primitives = require('../bf-emitter')

local function emitBreak(state: CodegenState, node: Node, _: EmitBlock)
	local brkCell = state.breakStack[#state.breakStack]
	if brkCell == nil then
		error(`[Line {(node.location :: any).beginLine}] 'break' used outside of a loop`)
	end
	Primitives.emitZero(state, brkCell)
end

return {
	['break'] = emitBreak,
}