--!strict
-- Statement parsing functions.

local Types = require('../shared/types')
local Constants = require('../shared/constants')
local PState = require('./parser-state')
local Expr = require('./expressions')

type ASTNode = Types.ASTNode
type ParserState = PState.ParserState
local TT = Constants.TokenType
local NT = Constants.NodeType

local Statements = {}

local parseStatement: (parserState: ParserState) -> ASTNode?
local parseBlock: (parserState: ParserState, terminators: { string }) -> { ASTNode }


local function createNode(nodeType: any, line: number, data: { [string]: any }): ASTNode
    local node = { type = nodeType, line = line }
    for k, v in data do node[k] = v end
    return node
end

local function parseIdentifierList(parserState: ParserState, firstToken: Types.Token?): { string }
	local names = {}

	if firstToken then
		table.insert(names, firstToken.value)
	else
		table.insert(names, PState.expect(parserState, TT.IDENT).value)
	end

	while PState.match(parserState, TT.COMMA) do
		PState.advance(parserState)
		table.insert(names, PState.expect(parserState, TT.IDENT).value)
	end

	return names
end

local function parseExpressionList(parserState: ParserState): { ASTNode }
	local exprs = { Expr.parseExpression(parserState) }

	while PState.match(parserState, TT.COMMA) do
		PState.advance(parserState)
		table.insert(exprs, Expr.parseExpression(parserState))
	end

	return exprs
end

local function createAssignmentLikeNode(nodeType: any, line: number, names: { string }, exprs: { ASTNode }): ASTNode
	if #names ~= #exprs then
		error(`Error [line {line}]: Assignment count mismatch: got {#names} variable(s) and {#exprs} value(s)`)
	end

	return createNode(nodeType, line, {
		name = names[1],
		names = names,
		expr = exprs[1],
		exprs = exprs,
	})
end

local function parseVarDecl(parserState: ParserState): ASTNode
	local startTok = PState.advance(parserState)
	local names = parseIdentifierList(parserState)
	PState.expect(parserState, TT.ASSIGN)

	return createAssignmentLikeNode(NT.VarDecl, startTok.line, names, parseExpressionList(parserState))
end

local function parsePrint(parserState: ParserState): ASTNode
	local printTok = PState.advance(parserState)
	PState.expect(parserState, TT.LPAREN)
	local expr = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.RPAREN)
	
	return createNode(NT.Print, printTok.line, {
		expr = expr
	})
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
		table.insert(elseifClauses, {
			condition = eifCond,
			body = parseBlock(parserState, { 'elseif', 'else', 'end' })
		})
	end

	local elseBody: { ASTNode }?
	if PState.match(parserState, TT.KEYWORD, 'else') then
		PState.advance(parserState)
		elseBody = parseBlock(parserState, { 'end' })
	end
	
	PState.expect(parserState, TT.KEYWORD, 'end')

	return createNode(NT.If, ifTok.line, {
		condition = condition,
		body = body,
		elseifClauses = elseifClauses,
		elseBody = elseBody,
		line = ifTok.line,
	})
end

local function parseWhile(parserState: ParserState): ASTNode
	local whileTok = PState.advance(parserState)
	local condition = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.KEYWORD, 'do')
	local body = parseBlock(parserState, { 'end' })
	PState.expect(parserState, TT.KEYWORD, 'end')
	return createNode(NT.While, whileTok.line, {
		condition = condition,
		body = body,
		line = whileTok.line,
	})
end

local function parseFor(parserState: ParserState): ASTNode
	local forTok = PState.advance(parserState)
	local nameTok = PState.expect(parserState, TT.IDENT)
	PState.expect(parserState, TT.ASSIGN)
	local startExpr = Expr.parseExpression(parserState)
	PState.expect(parserState, TT.COMMA)
	local stopExpr = Expr.parseExpression(parserState)
	local stepExpr: ASTNode? = nil
	if PState.match(parserState, TT.COMMA) then
		PState.advance(parserState)
		stepExpr = Expr.parseExpression(parserState)
	end
	
	PState.expect(parserState, TT.KEYWORD, 'do')
	local body = parseBlock(parserState, { 'end' })
	PState.expect(parserState, TT.KEYWORD, 'end')

	return createNode(NT.NumericFor, forTok.line, {
		name = nameTok.value,
		start = startExpr,
		stop = stopExpr,
		step = stepExpr,
		body = body,
		line = forTok.line,
	})
end

local function parseRepeat(parserState: ParserState): ASTNode
	local repeatTok = PState.advance(parserState)
	local body = parseBlock(parserState, { 'until' })
	PState.expect(parserState, TT.KEYWORD, 'until')

	local condition = Expr.parseExpression(parserState)
	return createNode(NT.RepeatUntil, repeatTok.line, {
		body = body,
		condition = condition,
	})
end

local function parseAssignment(parserState: ParserState): ASTNode
	local firstNameTok = PState.expect(parserState, TT.IDENT)
	local names = parseIdentifierList(parserState, firstNameTok)
	local operationToken = PState.advance(parserState)

	if #names > 1 and operationToken.type ~= TT.ASSIGN then
		error(`Error [line {firstNameTok.line}]: Multiple assignment only supports '='`)
	end

	if operationToken.type == TT.ASSIGN then
		return createAssignmentLikeNode(NT.Assign, firstNameTok.line, names, parseExpressionList(parserState))
	elseif operationToken.type == TT.COMPOUND_ASSIGN then
		local rhs = Expr.parseExpression(parserState)
		local varRef = createNode(NT.VarRef, firstNameTok.line, { name = firstNameTok.value })
        
		return createAssignmentLikeNode(NT.Assign, firstNameTok.line, names, {
			createNode(NT.BinOp, firstNameTok.line, {
				op = operationToken.value,
				left = varRef,
				right = rhs
			})
		})
	end

	error(`[Line {firstNameTok.line}] Unexpected assignment operator.`)
end

function parseStatement(parserState: ParserState): ASTNode
	if PState.match(parserState, TT.KEYWORD, 'local') then return parseVarDecl(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'print') then return parsePrint(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'if') then return parseIf(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'while') then return parseWhile(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'for') then return parseFor(parserState) end
	if PState.match(parserState, TT.KEYWORD, 'repeat') then return parseRepeat(parserState) end
	
	if PState.match(parserState, TT.KEYWORD, 'break') then
		local token = PState.advance(parserState)
		return createNode(NT.Break, token.line, {})
	end

	if PState.current(parserState).type == TT.IDENT then return parseAssignment(parserState) end

	local currentToken = PState.current(parserState)
	error(`Error [line {currentToken.line}]: Unexpected token '{currentToken.value}'`)
end

function parseBlock(parserState: ParserState, terminators: { string }): { ASTNode }
    local stmts = {}
    
    while true do
        local currentToken = PState.current(parserState)
        if currentToken.type == TT.EOF then break end
        
        -- Check if current token is a terminator
        if currentToken.type == TT.KEYWORD and table.find(terminators, currentToken.value) then
            break
        end

        table.insert(stmts, parseStatement(parserState))
    end
    
    return stmts
end

Statements.parseStatement = parseStatement
Statements.parseBlock = parseBlock

return Statements
