--!strict

local query = require('@std/syntax/query')

type AstStatBlock = { statements: { any }, [string]: any }

local function countVars(root: AstStatBlock): number
	local count = 0

	query.findAllFromRoot(root, function(node: any)
		if node.tag == 'local' and node.variables ~= nil then
			count += #node.variables
		elseif node.tag == 'table' and node.entries ~= nil then
			count += #node.entries
		elseif node.tag == 'for' then
			count += 2  -- loop variable + stop cell (step and brk are covered by the +4 buffer)
		end
		return nil
	end)

	return count
end

return countVars