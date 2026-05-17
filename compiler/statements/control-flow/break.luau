--!strict

local State = require('../../compiler-state')
local Primitives = require('../../bf-emitter')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function emitBreak(state: CodegenState, node: Node, _: EmitBlock)
	for i = #state.breakStack, 1, -1 do
		local frame = state.breakStack[i]
		if frame.kind == 'break' then
			Primitives.emitZero(state, frame.cell)
			return
		end
		if frame.kind == 'return' then break end
	end
	State.report(state, `Error [line {node.location.beginLine}]: 'break' used outside of a loop`)
end

return {
	['break'] = emitBreak,
}