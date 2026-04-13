--!strict

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode
type FoldFn = (node: ASTNode) -> ASTNode


local function foldNumeric(op: string, l: number, r: number): ASTNode?
	if op == '+' then return { type = 'NumberLit', value = l + r } end
	if op == '-' then return { type = 'NumberLit', value = l - r } end
	if op == '*' then return { type = 'NumberLit', value = l * r } end
	if op == '/' and r ~= 0 then return { type = 'NumberLit', value = l / r } end
	if op == '//' and r ~= 0 then return { type = 'NumberLit', value = math.floor(l / r) } end
	if op == '%' and r ~= 0 then return { type = 'NumberLit', value = l % r } end
	return nil
end


local function foldRelational(op: string, l: number, r: number): ASTNode?
	if op == '<'  then return { type = 'BoolLit', value = l <  r } end
	if op == '<=' then return { type = 'BoolLit', value = l <= r } end
	if op == '>'  then return { type = 'BoolLit', value = l >  r } end
	if op == '>=' then return { type = 'BoolLit', value = l >= r } end
	return nil
end

-- Algebraic identity reductions (one side is a known literal).
local function foldIdentity(op: string, left: ASTNode, right: ASTNode): ASTNode?
	if op == '*' then
		if right.type == 'NumberLit' and right.value == 1 then return left end
		if left.type == 'NumberLit' and left.value == 1 then return right end
		if right.type == 'NumberLit' and right.value == 0 then return { type = 'NumberLit', value = 0 } end
		if left.type == 'NumberLit' and left.value == 0 then return { type = 'NumberLit', value = 0 } end
	elseif op == '+' then
		if right.type == 'NumberLit' and right.value == 0 then return left end
		if left.type == 'NumberLit' and left.value == 0 then return right end
	elseif op == '-' then
		if right.type == 'NumberLit' and right.value == 0 then return left end
	elseif op == '/' or op == '//' then
		if right.type == 'NumberLit' and right.value == 1 then return left end
	end
	return nil
end

local function foldBinOp(node: ASTNode, fold: FoldFn): ASTNode
	local left = fold(node.left)
	local right = fold(node.right)
	local op = node.op

	-- Boolean short-circuit folding
	do
		if op == 'and' and left.type == 'BoolLit' then
			return if (left.value :: boolean) then right else left
		end
		
		if op == 'or' and left.type == 'BoolLit' then
			return if (left.value :: boolean) then left else right
		end
	end

	-- Any matching literal types
	if left.type == right.type and (left.type == 'NumberLit' or left.type == 'BoolLit') then
		if op == '==' then return { type = 'BoolLit', value = left.value == right.value } end
		if op == '~=' then return { type = 'BoolLit', value = left.value ~= right.value } end
	end

	-- Numeric literal folding
	if left.type == 'NumberLit' and right.type == 'NumberLit' then
		local l = left.value
		local r = right.value
		local folded = foldNumeric(op, l, r) or foldRelational(op, l, r)
		if folded then return folded end
	end

	-- Algebraic
	local reduced = foldIdentity(op, left, right)
	if reduced then return reduced end

	return { type = 'BinOp', op = op, left = left, right = right }
end

return foldBinOp
