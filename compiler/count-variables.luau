--!strict

local visitor = require('@std/syntax/visitor')

type AstStatBlock = { statements: { any }, [string]: any }
type AstStatLocal = { variables: { any }, [string]: any }
type AstStatFor = { [string]: any }

local function countVars(root: AstStatBlock): number
	local count = 0

	local nodeVisitor = visitor.create()

	nodeVisitor.visitStatLocalDeclaration = function(node: any): boolean
		count += #node.variables
		return true
	end

	nodeVisitor.visitStatFor = function(_node: any): boolean
		count += 2  -- loop variable + stop cell (step and brk are covered by the +4 buffer)
		return true
	end

	visitor.visitBlock(root, nodeVisitor)
	return count
end

return countVars