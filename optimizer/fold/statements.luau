--!strict

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode
type FoldFn  = (node: ASTNode) -> ASTNode
type FoldBlockFn = (stmts: { ASTNode }) -> { ASTNode }

local function foldStatement(node: ASTNode, fold: FoldFn, foldBlock: FoldBlockFn): ASTNode
	if node.type == 'Program' then
		return { type = 'Program', body = foldBlock(node.body) }
	elseif node.type == 'Print' then
		return { type = 'Print', expr = fold(node.expr), line = node.line }
	elseif node.type == 'VarDecl' or node.type == 'Assign' then
		local foldedExprs = {}
		for _, e in node.exprs do
			table.insert(foldedExprs, fold(e))
		end

		return {
			type = node.type,
			name = node.name,
			names = node.names,
			expr = foldedExprs[1],
			exprs = foldedExprs,
			line = node.line,
		}
	elseif node.type == 'If' then
		local foldedElseIfs = {}
		for _, ei in node.elseifClauses do
			table.insert(foldedElseIfs, {
				condition = fold(ei.condition),
				body = foldBlock(ei.body),
			})
		end

		return {
			type = 'If',
			condition = fold(node.condition),
			body = foldBlock(node.body),
			elseifClauses = foldedElseIfs,
			elseBody = node.elseBody and foldBlock(node.elseBody) or nil,
			line = node.line,
		}

	elseif node.type == 'While' then
		return {
			type = 'While',
			condition = fold(node.condition),
			body = foldBlock(node.body),
			line = node.line,
		}

	elseif node.type == 'RepeatUntil' then
		return {
			type = 'RepeatUntil',
			body = foldBlock(node.body),
			condition = fold(node.condition),
			line = node.line,
		}

	elseif node.type == 'NumericFor' then
		return {
			type = 'NumericFor',
			name = node.name,
			start = fold(node.start),
			stop = fold(node.stop),
			step = node.step and fold(node.step) or nil,
			body = foldBlock(node.body),
			line = node.line,
		}
	end

	-- NumberLit, BoolLit, VarRef, Break pass through unchanged
	return node
end

return foldStatement
