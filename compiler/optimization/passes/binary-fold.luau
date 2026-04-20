--!strict

type Node = { [string]: any }

local BinaryFold = {}

function BinaryFold.tryNumber(node: Node): number?
	local lhs = node.lhsOperand
	local rhs = node.rhsOperand
	local op = node.operator.text

	if lhs.tag == 'number' and rhs.tag == 'number' then
		local left = lhs.value
		local right = rhs.value
		if op == '+' then return left + right
		elseif op == '-' then return left - right
		elseif op == '*' then return left * right
		elseif op == '/' and right ~= 0 then return left / right
		elseif op == '//' and right ~= 0 then return math.floor(left / right)
		elseif op == '%' and right ~= 0 then return left % right
		end
	end

	return nil
end

function BinaryFold.tryBoolean(node: Node): boolean?
	local lhs = node.lhsOperand
	local rhs = node.rhsOperand
	local op = node.operator.text

	if lhs.tag == 'number' and rhs.tag == 'number' then
		local left = lhs.value
		local right = rhs.value
		if op == '==' then return left == right
		elseif op == '~=' then return left ~= right
		elseif op == '<' then return left < right
		elseif op == '<=' then return left <= right
		elseif op == '>' then return left > right
		elseif op == '>=' then return left >= right
		end
	end

	if op == 'and' and lhs.tag == 'boolean' then
		return if lhs.value then nil else false
	end

	if op == 'or' and lhs.tag == 'boolean' then
		return if lhs.value then true else nil
	end

	return nil
end

return BinaryFold