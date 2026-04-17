--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitExpr = (state: CodegenState, node: Node) -> number

local Primitives = require('../bf-emitter')

local function emitNumber(state: CodegenState, node: Node, _: EmitExpr): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, node.value % 256)
	return cell
end

local function emitBool(state: CodegenState, node: Node, _: EmitExpr): number
	local cell = Primitives.allocTemp(state)
	Primitives.emitSetCell(state, cell, if node.value then 1 else 0)
	return cell
end

local function emitLocalRef(state: CodegenState, node: Node, _: EmitExpr): number
	local varName = node["local"].name.text
	local varCell = state.variables[varName]
	if varCell == nil then
		State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
		return Primitives.allocTemp(state)
	end
	
	local result = Primitives.allocTemp(state)
	local tmp = Primitives.allocTemp(state)
	Primitives.emitCopy(state, varCell, result, tmp)
	state.nextTemp -= 1
	return result
end

return {
	['number'] = emitNumber,
	['boolean'] = emitBool,
	['local'] = emitLocalRef,
}
