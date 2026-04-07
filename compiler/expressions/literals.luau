--!strict
-- Literal value and variable reference expression codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType


local function emitNumberLit(state: CodegenState, node: ASTNode): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, node.value % 256)
	return cell
end


local function emitBoolLit(state: CodegenState, node: ASTNode): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, if node.value then 1 else 0)
	return cell
end


local function emitVarRef(state: CodegenState, node: ASTNode): number
	local varCell = state.variables[node.name]
	if varCell == nil then
		error(`Error [line {tostring(node.line)}]: Undefined variable '{node.name}'`)
	end

	local result = Primitives.allocTemp(state)
	local tmp = Primitives.allocTemp(state)
	Primitives.emitCopy(state, varCell, result, tmp)
	state.nextTemp -= 1
	
	return result
end


return {
	[NT.NumberLit] = emitNumberLit,
	[NT.BoolLit] = emitBoolLit,
	[NT.VarRef] = emitVarRef,
}
