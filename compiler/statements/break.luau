--!strict

local Types = require('../../shared/types')
local State = require('../compiler-state')
local Primitives = require('../bf-emitter')
local Constants = require('../../shared/constants')

type ASTNode = Types.ASTNode
type CodegenState = State.CodegenState

local NT = Constants.NodeType

type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local function emitBreak(state: CodegenState, node: ASTNode, _emitBlock: EmitBlock)
	local brkCell = state.breakStack[#state.breakStack]
	if brkCell == nil then
		error(`[Line {tostring(node.line)}] 'break' used outside of a loop`)
	end
	Primitives.emitZero(state, brkCell)
end

return {
	[NT.Break] = emitBreak,
}
