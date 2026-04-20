--!strict

local State = require('../compiler-state')
local Primitives = require('../bf-emitter')
local Expr = require('../expressions')

type CodegenState = State.CodegenState
type Node = { [string]: any }
type EmitBlock = (state: CodegenState, stmts: { Node }) -> ()

local function unpack(p: { any }): { Node }
	local out = {}
	for _, pair in p do
		table.insert(out, pair.node)
	end
	return out
end

local function evaluateExprs(state: CodegenState, exprs: { Node }): { number }
	local cells = {}
	for _, expr in exprs do
		table.insert(cells, Expr.emitExpr(state, expr))
	end
	return cells
end

local function moveExprsToCells(state: CodegenState, targets: { number }, sources: { number })
	for i, cell in targets do
		Primitives.emitZero(state, cell)
		Primitives.emitMoveAdd(state, sources[i], cell)
	end
	Primitives.resetTemps(state)
end

-- local x, y = expr1, expr2
local function emitVarDecl(state: CodegenState, node: Node, _: EmitBlock)
	local vars = unpack(node.variables)
	local values = unpack(node.values)
	local targets = {}
	for _, astLocal in vars do
		table.insert(targets, Primitives.allocVar(state, astLocal.name.text))
	end
	moveExprsToCells(state, targets, evaluateExprs(state, values))
end

-- x, y = expr1, expr2
local function emitAssign(state: CodegenState, node: Node, _: EmitBlock)
	local lhsExprs = unpack(node.variables)
	local values = unpack(node.values)
	local targets = {}
	for _, lhs in lhsExprs do
		local lhsNode = lhs :: Node
		if lhsNode.tag ~= 'local' then
			State.report(state, `Error [line {node.location.beginLine}]: Only local variable assignment is supported`)
			return
		end
		local varName: string = lhsNode["local"].name.text
		local cell = state.variables[varName]
		if cell == nil then
			State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
			return
		end
		table.insert(targets, cell)
	end
	moveExprsToCells(state, targets, evaluateExprs(state, values))
end

-- x += expr → x = x OP expr
local function emitCompoundAssign(state: CodegenState, node: Node, _: EmitBlock)
	local lhs = node.variable :: Node
	if lhs.tag ~= 'local' then
		State.report(state, `Error [line {node.location.beginLine}]: Only local variable compound assignment is supported`)
		return
	end

	local varName: string = lhs["local"].name.text
	local cell = state.variables[varName]
	if cell == nil then
		State.report(state, `Error [line {node.location.beginLine}]: Undefined variable '{varName}'`)
		return
	end

	local compoundOp: string = (node.operand :: any).text
	local baseOp = compoundOp:sub(1, -2)

	local synthetic: Node = {
		tag = 'binary',
		operator = { text = baseOp },
		lhsOperand = node.variable,
		rhsOperand = node.value :: Node,
	}
	local resultCell = Expr.emitExpr(state, synthetic)
	Primitives.emitZero(state, cell)
	Primitives.emitMoveAdd(state, resultCell, cell)
	Primitives.resetTemps(state)
end

return {
	['local'] = emitVarDecl,
	['assign'] = emitAssign,
	['compoundassign'] = emitCompoundAssign,
}
