--!strict

local Types = require('../shared/types')
type Token = Types.Token
type TokenType = Types.TokenType

export type ParserState = {
	tokens: { Token },
	pos: number,
}

local State = {}

function State.create(tokens: { Token }): ParserState
	return {
		tokens = tokens,
		pos = 1,
	}
end

function State.current(s: ParserState): Token
	return s.tokens[s.pos]
end

function State.advance(s: ParserState): Token
	local tok = s.tokens[s.pos]
	s.pos += 1
	return tok
end

function State.expect(s: ParserState, type: TokenType, value: string?): Token
	local tok = State.current(s)
	if tok.type ~= type or (value and tok.value ~= value) then
		local expected = value or type
		error(`Error [line {tok.line}]: Expected '{expected}', got '{tok.value}'`)
	end
	return State.advance(s)
end

function State.match(s: ParserState, type: TokenType, value: string?): boolean
	local tok = State.current(s)
	return tok.type == type and (not value or tok.value == value)
end

return State
