--!strict

type Node = { [string]: any }

local StaticStrings = {}

local function unpackArgs(punctuated: { any }): { Node }
	local args = {}
	for _, pair in punctuated do
		table.insert(args, pair.node)
	end
	return args
end

function StaticStrings.resolveNumber(node: Node): number?
	if node.tag == 'number' then
		return node.value
	end

	if node.tag == 'group' then
		return StaticStrings.resolveNumber(node.expression)
	end

	if node.tag == 'unary' and node.operator.text == '-' then
		local inner = StaticStrings.resolveNumber(node.operand)
		if inner ~= nil then
			return -inner
		end
	end

	return nil
end

local function resolveStringBuiltin(node: Node): string?
	local func = node.func :: Node
	if func.tag ~= 'indexname' then
		return nil
	end

	local tableExpr = func.expression :: Node
	if tableExpr.tag ~= 'global' or tableExpr.name.text ~= 'string' then
		return nil
	end

	local method = func.index.text
	local args = unpackArgs(node.arguments)

	if method == 'upper' or method == 'lower' or method == 'reverse' then
		if #args ~= 1 then
			return nil
		end

		local value = StaticStrings.resolve(args[1])
		if value == nil then
			return nil
		end

		if method == 'upper' then return string.upper(value) end
		if method == 'lower' then return string.lower(value) end
		return string.reverse(value)
	end

	if method == 'rep' then
		if #args ~= 2 then
			return nil
		end

		local value = StaticStrings.resolve(args[1])
		local count = StaticStrings.resolveNumber(args[2])
		if value == nil or count == nil or count < 0 or count % 1 ~= 0 then
			return nil
		end

		return string.rep(value, count)
	end

	if method == 'sub' then
		if #args < 2 or #args > 3 then
			return nil
		end

		local value = StaticStrings.resolve(args[1])
		local startIndex = StaticStrings.resolveNumber(args[2])
		local endIndex = if args[3] ~= nil then StaticStrings.resolveNumber(args[3]) else nil
		if value == nil or startIndex == nil or startIndex % 1 ~= 0 then
			return nil
		end

		if endIndex ~= nil and endIndex % 1 ~= 0 then
			return nil
		end

		if endIndex ~= nil then
			return string.sub(value, startIndex, endIndex)
		end

		return string.sub(value, startIndex)
	end

	if method == 'char' then
		local chars = {}
		for _, arg in args do
			local byteValue = StaticStrings.resolveNumber(arg)
			if byteValue == nil or byteValue % 1 ~= 0 or byteValue < 0 or byteValue > 255 then
				return nil
			end
			table.insert(chars, string.char(byteValue))
		end
		return table.concat(chars)
	end

	return nil
end

function StaticStrings.resolve(node: Node): string?
	if node.tag == 'string' then
		return node.token.text
	end

	if node.tag == 'group' then
		return StaticStrings.resolve(node.expression)
	end

	if node.tag == 'binary' and node.operator.text == '..' then
		local left = StaticStrings.resolve(node.lhsOperand)
		local right = StaticStrings.resolve(node.rhsOperand)
		if left ~= nil and right ~= nil then
			return left .. right
		end
	end

	if node.tag == 'call' then
		return resolveStringBuiltin(node)
	end

	return nil
end

return StaticStrings