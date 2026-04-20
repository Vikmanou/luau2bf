--!strict

type Node = { [string]: any }

local Identity = {}

function Identity.trySimplify(node: Node): Node?
	local lhs = node.lhsOperand
	local rhs = node.rhsOperand
	local op = node.operator.text

	if op == '*' then
		if rhs.tag == 'number' and rhs.value == 1 then return lhs end
		if lhs.tag == 'number' and lhs.value == 1 then return rhs end
		if rhs.tag == 'number' and rhs.value == 0 then return { tag = 'number', value = 0 } end
		if lhs.tag == 'number' and lhs.value == 0 then return { tag = 'number', value = 0 } end
	elseif op == '+' then
		if rhs.tag == 'number' and rhs.value == 0 then return lhs end
		if lhs.tag == 'number' and lhs.value == 0 then return rhs end
	elseif op == '-' then
		if rhs.tag == 'number' and rhs.value == 0 then return lhs end
	elseif op == '/' or op == '//' then
		if rhs.tag == 'number' and rhs.value == 1 then return lhs end
	end

	return nil
end

return Identity