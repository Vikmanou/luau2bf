--!strict
-- Counts all variable declarations

local Types = require('../shared/types')

type ASTNode = Types.ASTNode

local countVars: (node: ASTNode) -> number

local function countBody(nodes: { ASTNode }): number
	local sum = 0
	for _, stmt in nodes do
		sum += countVars(stmt)
	end
	return sum
end

local countFuncs = {
	['Program'] = function(node: ASTNode): number
		return countBody(node.body)
	end,

	['VarDecl'] = function(node: ASTNode): number
		return if node.names then #node.names else 1
	end,

	['If'] = function(node: ASTNode): number
		local count = countBody(node.body)

		if node.elseifClauses then
			for _, clause in node.elseifClauses do
				count += countBody(clause.body)
			end
		end
		
		if node.elseBody then
			count += countBody(node.elseBody)
		end

		return count
	end,

	['While'] = function(node: ASTNode): number
		return countBody(node.body)
	end,

	['NumericFor'] = function(node: ASTNode): number
		local count = 2 -- loop variable + stop cell
		count += countBody(node.body)
		return count
	end,

	['Print'] = function(node: ASTNode): number
		return 0
	end
}


countVars = function(node: ASTNode): number
	local func = countFuncs[node.type]
	return func and func(node) or 0
end

return countVars