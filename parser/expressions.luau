--!strict
-- Expression parsing with precedence climbing.

local Types = require('../shared/types')
local Constants = require('../shared/constants')
type ASTNode = Types.ASTNode

local TT = Constants.TokenType
local NT = Constants.NodeType

local PState = require('./parser-state')
type ParserState = PState.ParserState

local Expressions = {}

local parseExpression: (parserState: ParserState) -> ASTNode

local function parseAtom(parserState: ParserState): ASTNode
	local tok = PState.current(parserState)

	if tok.type == TT.NUMBER then
		PState.advance(parserState)
		return { type = NT.NumberLit, value = tonumber(tok.value) :: number }
	end

	if tok.type == TT.KEYWORD and (tok.value == 'true' or tok.value == 'false') then
		PState.advance(parserState)
		return { type = NT.BoolLit, value = tok.value == 'true' }
	end

	if tok.type == TT.IDENT then
		PState.advance(parserState)
		return { type = NT.VarRef, name = tok.value, line = tok.line }
	end

	if tok.type == TT.LPAREN then
		PState.advance(parserState)
		local expr = parseExpression(parserState)
		PState.expect(parserState, TT.RPAREN)
		return expr
	end

	error(`Error [line {tok.line}]: Unexpected token '{tok.value}'`)
end

local function parseUnary(parserState: ParserState): ASTNode
	local tok = PState.current(parserState)
	if tok.type == TT.OP and tok.value == '-' then
		PState.advance(parserState)
		return { type = NT.UnaryOp, op = '-', expr = parseUnary(parserState) }
	end
	if tok.type == TT.KEYWORD and tok.value == 'not' then
		PState.advance(parserState)
		return { type = NT.UnaryOp, op = 'not', expr = parseUnary(parserState) }
	end
	return parseAtom(parserState)
end

local function parseMultiplication(parserState: ParserState): ASTNode
	local left = parseUnary(parserState)
	while PState.current(parserState).type == TT.OP and (PState.current(parserState).value == '*' or PState.current(parserState).value == '/' or PState.current(parserState).value == '%') do
		local op = PState.advance(parserState).value
		left = { type = NT.BinOp, op = op, left = left, right = parseUnary(parserState) }
	end
	return left
end

local function parseAddition(parserState: ParserState): ASTNode
	local left = parseMultiplication(parserState)
	while PState.current(parserState).type == TT.OP and (PState.current(parserState).value == '+' or PState.current(parserState).value == '-') do
		local op = PState.advance(parserState).value
		left = { type = NT.BinOp, op = op, left = left, right = parseMultiplication(parserState) }
	end
	return left
end

local function parseComparison(parserState: ParserState): ASTNode
	local left = parseAddition(parserState)
	while PState.current(parserState).type == TT.COMPARE do
		local op = PState.advance(parserState).value
		left = { type = NT.BinOp, op = op, left = left, right = parseAddition(parserState) }
	end
	return left
end

local function parseAnd(parserState: ParserState): ASTNode
	local left = parseComparison(parserState)
	while PState.match(parserState, TT.KEYWORD, 'and') do
		PState.advance(parserState)
		left = { type = NT.BinOp, op = 'and', left = left, right = parseComparison(parserState) }
	end
	return left
end

local function parseOr(parserState: ParserState): ASTNode
	local left = parseAnd(parserState)
	while PState.match(parserState, TT.KEYWORD, 'or') do
		PState.advance(parserState)
		left = { type = NT.BinOp, op = 'or', left = left, right = parseAnd(parserState) }
	end
	return left
end

function parseExpression(parserState: ParserState): ASTNode
	return parseOr(parserState)
end

Expressions.parseExpression = parseExpression

return Expressions
