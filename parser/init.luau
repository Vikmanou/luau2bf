--!strict

local Types = require('./shared/types')
local Constants = require('./shared/constants')
type Token = Types.Token

export type ASTNode = Types.ASTNode

local TT = Constants.TokenType
local NT = Constants.NodeType

local ParserState = require('./parser/parser-state')
local Stmts = require('./parser/statements')

local Parser = {}

function Parser.parse(tokens: { Token }): ASTNode
	local parserState = ParserState.create(tokens)

	local body = Stmts.parseBlock(parserState, {})
	ParserState.expect(parserState, TT.EOF)

	return { type = NT.Program, body = body }
end

return Parser
