--!strict
-- Expression code generation dispatcher.
-- Dispatches on node.tag for non-binary nodes; on node.operator.text for binary nodes.
-- Constant folding is done inline before dispatching to avoid a separate AST pass.

local fs = require('@lute/fs')

local State = require('./compiler-state')
type CodegenState = State.CodegenState
type Node = { [string]: any }

local Primitives = require('./bf-emitter')

local emitExpr: (state: CodegenState, node: Node) -> number

local handlers: { [string]: (state: CodegenState, node: Node, emitExpr: typeof(emitExpr)) -> number } = {}
local handlersReady = false

local function loadHandlers()
	if handlersReady then return end
	handlersReady = true

	local entries = fs.listdir('./compiler/expressions')
	for _, entry in entries do
		if entry.type ~= 'file' or not entry.name:find('%.luau$') or entry.name == 'init.luau' then continue end
		local name = entry.name:gsub('%.luau$', '')
		local module = (require)(`./expressions/{name}`)
		for key, handler in module do
			handlers[key] = handler
		end
	end
end

local function tryFoldBinary(node: Node): number?
	local lhs = node.lhsOperand
	local rhs = node.rhsOperand
	local op = node.operator.text

	if lhs.tag == 'number' and rhs.tag == 'number' then
		local l = lhs.value
		local r = rhs.value
		if op == '+' then return l + r
		elseif op == '-' then return l - r
		elseif op == '*' then return l * r
		elseif op == '/' and r ~= 0 then return l / r
		elseif op == '//' and r ~= 0 then return math.floor(l / r)
		elseif op == '%' and r ~= 0 then return l % r
		end
	end
	return nil
end

local function tryFoldBinaryBool(node: Node): boolean?
	local lhs = node.lhsOperand
	local rhs = node.rhsOperand
	local op = node.operator.text

	if lhs.tag == 'number' and rhs.tag == 'number' then
		local l = lhs.value
		local r = rhs.value
		if op == '==' then return l == r
		elseif op == '~=' then return l ~= r
		elseif op == '<'  then return l <  r
		elseif op == '<=' then return l <= r
		elseif op == '>'  then return l >  r
		elseif op == '>=' then return l >= r
		end
	end

	if op == 'and' and lhs.tag == 'boolean' then
		return if lhs.value then nil else false -- nil = not a constant (right side varies)
	end

	if op == 'or' and lhs.tag == 'boolean' then
		return if lhs.value then true else nil
	end

	return nil
end

-- Algebraic identity reductions.
local function tryFoldIdentity(node: Node): Node?
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

function emitExpr(state: CodegenState, node: Node): number
	loadHandlers()

	-- Unwrap parenthesised expressions
	if node.tag == 'group' then
		return emitExpr(state, node.expression)
	end

	-- Inline constant folding for binary ops
	if node.tag == 'binary' then
		local numResult = tryFoldBinary(node)
		if numResult ~= nil then
			local cell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, cell, numResult % 256)
			return cell
		end

		local boolResult = tryFoldBinaryBool(node)
		if boolResult ~= nil then
			local cell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, cell, if boolResult then 1 else 0)
			return cell
		end

		local identityNode = tryFoldIdentity(node)
		if identityNode ~= nil then
			return emitExpr(state, identityNode)
		end

		local op = node.operator.text
		local handler = handlers[op]
		if not handler then
			local loc = node.operator.location
			State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unknown binary operator '{op}'`)
			return Primitives.allocTemp(state)
		end
		
		return handler(state, node, emitExpr)
	end

	if node.tag == 'unary' then
		local op = node.operator.text
		local inner = node.operand
		if op == '-' and inner.tag == 'number' then
			local cell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, cell, (-inner.value) % 256)
			return cell
		end

		if op == 'not' and inner.tag == 'boolean' then
			local cell = Primitives.allocTemp(state)
			Primitives.emitSetCell(state, cell, if inner.value then 0 else 1)
			return cell
		end
	end

	local key = node.tag
	local handler = handlers[key]
	if not handler then
		local loc = node.location
		State.report(state, `Error [line {if loc then tostring(loc.beginLine) else '?'}]: Unknown expression '{key}'`)
		return Primitives.allocTemp(state)
	end
	
	return handler(state, node, emitExpr)
end

return { emitExpr = emitExpr }
