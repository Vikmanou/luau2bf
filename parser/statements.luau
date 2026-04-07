--!strict
-- Statement parsing functions.

local Types = require('../shared/types')
local Constants = require('../shared/constants')
type ASTNode = Types.ASTNode

local TT = Constants.TokenType
local NT = Constants.NodeType

local PState = require('./parser-state')
type ParserState = PState.ParserState

local Expr = require('./expressions')

local Statements = {}

local parseStatement: (parserState: ParserState) -> ASTNode?
local parseBlock: (parserState: ParserState, terminators: { string }) -> { ASTNode }

local function parseVarDecl(parserState: ParserState): ASTNode
	local localTok = PState.advance(parserState)
	local nameTok = PState.expect(parserState, TT.IDENT)
	PState.expect(parserState, TT.ASSIGN)
	return { type = NT.VarDecl, name = nameTok.value, expr = Expr.parseExpression(parserState), line = localTok.line }
end

local function parsePrint(parserState: ParserState): ASTNode
	local printTok = PState.advance(parserState)
	PState.expect(parserState, TT.LPAREN)
	local expr = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.RPAREN)
	return { type = NT.Print, expr = expr, line = printTok.line }
end

local function parseIf(parserState: ParserState): ASTNode
	local ifTok = PState.advance(parserState)
	local condition = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.KEYWORD, 'then')
	local body = parseBlock(parserState, { 'elseif', 'else', 'end' })

	local elseifClauses: { { condition: ASTNode, body: { ASTNode } } } = {}
	while PState.match(parserState, TT.KEYWORD, 'elseif') do
		PState.advance(parserState)
		local eifCond = Expr.parseExpression(parserState)
		PState.expect(parserState, TT.KEYWORD, 'then')
		table.insert(elseifClauses, { condition = eifCond, body = parseBlock(parserState, { 'elseif', 'else', 'end' }) })
	end

	local elseBody: { ASTNode }?
	if PState.match(parserState, TT.KEYWORD, 'else') then
		PState.advance(parserState)
		elseBody = parseBlock(parserState, { 'end' })
	end
	PState.expect(parserState, TT.KEYWORD, 'end')

	return {
		type = NT.If,
		condition = condition,
		body = body,
		elseifClauses = elseifClauses,
		elseBody = elseBody,
		line = ifTok.line,
	}
end

local function parseWhile(parserState: ParserState): ASTNode
	local whileTok = PState.advance(parserState)
	local condition = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.KEYWORD, 'do')
	local body = parseBlock(parserState, { 'end' })
	PState.expect(parserState, TT.KEYWORD, 'end')
	return { type = NT.While, condition = condition, body = body, line = whileTok.line }
end

local function parseFor(parserState: ParserState): ASTNode
	local forTok = PState.advance(parserState)
	local nameTok = PState.expect(parserState, TT.IDENT)
	PState.expect(parserState, TT.ASSIGN)
	local startExpr = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.COMMA)
	local stopExpr = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.KEYWORD, 'do')
	local body = parseBlock(parserState, { 'end' })
	PState.expect(parserState, TT.KEYWORD, 'end')
	return {
		type = NT.NumericFor,
		name = nameTok.value,
		start = startExpr,
		stop = stopExpr,
		body = body,
		line = forTok.line,
	}
end

local function parseAssignment(parserState: ParserState): ASTNode
	local tok = PState.current(parserState)
	if parserState.tokens[parserState.pos + 1] and parserState.tokens[parserState.pos + 1].type == TT.ASSIGN then
		local nameTok = PState.advance(parserState)
		PState.expect(parserState, TT.ASSIGN)
		return { type = NT.Assign, name = nameTok.value, expr = Expr.parseExpression(parserState), line = nameTok.line }
	end
	error(`Error [line {tok.line}]: Unexpected identifier '{tok.value}'. Did you mean to assign a variable?`)
end

function parseStatement(parserState: ParserState): ASTNode?
	if PState.match(parserState, TT.KEYWORD, 'local') then return parseVarDecl(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'print') then return parsePrint(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'if') then return parseIf(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'while') then return parseWhile(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'for') then return parseFor(parserState) end

	if PState.current(parserState).type == TT.IDENT then return parseAssignment(parserState) end

	error(`Error [line {PState.current(parserState).line}]: Unexpected token '{PState.current(parserState).value}'`)
end

function parseBlock(parserState: ParserState, terminators: { string }): { ASTNode }
	local stmts: { ASTNode } = {}
	while true do
		local tok = PState.current(parserState)
		if tok.type == TT.EOF then break end
		if tok.type == TT.KEYWORD then
			for _, t in terminators do
				if tok.value == t then return stmts end
			end
		end
		local stmt = parseStatement(parserState)
		if stmt then
			table.insert(stmts, stmt)
		end
	end
	return stmts
end

Statements.parseStatement = parseStatement
Statements.parseBlock = parseBlock

return Statements
