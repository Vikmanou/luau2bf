--!strict

local BinaryFold = require('./optimization/passes/binary-fold')
local Identity = require('./optimization/passes/identity')

type Node = { [string]: any }

export type FoldedResult =
	{ kind: 'number', value: number }
	| { kind: 'boolean', value: boolean }
	| { kind: 'node', value: Node }

local Optimization = {}

function Optimization.optimize(node: Node): FoldedResult?
	if node.tag == 'binary' then
		local numberResult = BinaryFold.tryNumber(node)
		if numberResult ~= nil then
			return { kind = 'number', value = numberResult }
		end

		local booleanResult = BinaryFold.tryBoolean(node)
		if booleanResult ~= nil then
			return { kind = 'boolean', value = booleanResult }
		end

		local simplified = Identity.trySimplify(node)
		if simplified ~= nil then
			return { kind = 'node', value = simplified }
		end
	elseif node.tag == 'unary' then
		local op = node.operator.text
		local inner = node.operand
		if op == '-' and inner.tag == 'number' then
			return { kind = 'number', value = -inner.value }
		end

		if op == 'not' and inner.tag == 'boolean' then
			return { kind = 'boolean', value = not inner.value }
		end

		if op == '#' and inner.tag == 'string' then
			return { kind = 'number', value = #inner.token.text }
		end
	end

	return nil
end

return Optimization