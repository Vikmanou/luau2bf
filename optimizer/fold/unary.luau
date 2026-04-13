--!strict

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode
type FoldFn = (node: ASTNode) -> ASTNode

local function foldUnary(node: ASTNode, fold: FoldFn): ASTNode
	local inner = fold(node.expr)

	if node.op == '-' and inner.type == 'NumberLit' then
		return { type = 'NumberLit', value = -inner.value }
	end

	if node.op == 'not' and inner.type == 'BoolLit' then
		return { type = 'BoolLit', value = not inner.value }
	end

	return { type = 'UnaryOp', op = node.op, expr = inner }
end

return foldUnary
