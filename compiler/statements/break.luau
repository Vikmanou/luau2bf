--!strict

local State = require('../compiler-state')
local Primitives = require('../bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function emitBreak(state: CodegenState, node: Node, _: EmitBlock)
	local brkCell = state.breakStack[#state.breakStack]
	if brkCell == nil then
		State.report(state, `Error [line {node.location.beginLine}]: 'break' used outside of a loop`)
		return
	end
	Primitives.emitZero(state, brkCell)
end

return {
	['break'] = emitBreak,
}
