--!strict

local foldBinOp = require('./fold/binop')
local foldUnary = require('./fold/unary')
local foldStatement = require('./fold/statements')

local Types = require('../shared/types')
type ASTNode = Types.ASTNode

local fold: (node: ASTNode) -> ASTNode

local function foldBlock(stmts: { ASTNode }): { ASTNode }
	local out: { ASTNode } = {}
	for _, s in stmts do
		table.insert(out, fold(s))
	end
	return out
end

fold = function(node: ASTNode): ASTNode
	if node.type == 'BinOp' then
		return foldBinOp(node, fold)
	elseif node.type == 'UnaryOp' then
		return foldUnary(node, fold)
	else
		return foldStatement(node, fold, foldBlock)
	end
end

return { fold = fold }
