--!strict
-- Variable declaration and assignment codegen.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

local function getNames(node: ASTNode): { string }
	return node.names or { node.name }
end

local function getExprs(node: ASTNode): { ASTNode }
	return node.exprs or { node.expr }
end

local function evaluateExprs(state: CodegenState, exprs: { ASTNode }): { number }
	local exprCells = {}

	for _, expr in exprs do
		table.insert(exprCells, Expr.emitExpr(state, expr))
	end

	return exprCells
end

local function moveExprsToCells(state: CodegenState, targetCells: { number }, exprCells: { number })
	for index, cell in targetCells do
		Primitives.emitZero(state, cell)
		Primitives.emitMoveAdd(state, exprCells[index], cell)
	end

	Primitives.resetTemps(state)
end

local function emitVarDecl(state: CodegenState, node: ASTNode)
	local targetCells = {}

	for _, name in getNames(node) do
		table.insert(targetCells, Primitives.allocVar(state, name))
	end

	moveExprsToCells(state, targetCells, evaluateExprs(state, getExprs(node)))
end

local function emitAssign(state: CodegenState, node: ASTNode)
	local targetCells = {}

	for _, name in getNames(node) do
		local cell = state.variables[name]
		if cell == nil then
			error(`Error [line {node.line or 0}]: Undefined variable '{name}'`)
		end

		table.insert(targetCells, cell)
	end

	moveExprsToCells(state, targetCells, evaluateExprs(state, getExprs(node)))
end

return {
	[NT.VarDecl] = emitVarDecl,
	[NT.Assign] = emitAssign
}
