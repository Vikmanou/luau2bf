--!strict
-- Lexer state and low-level helpers (peek, advance, addToken).

local Types = require('../shared/types')
type Token = Types.Token
type TokenType = Types.TokenType

export type LexerState = {
	source: string,
	tokens: { Token },
	pos: number,
	line: number,
	len: number,
	inLocalDecl: boolean,
}

local State = {}

function State.create(source: string): LexerState
	return {
		source = source,
		tokens = {},
		pos = 1,
		line = 1,
		len = #source,
		inLocalDecl = false,
	}
end

function State.peek(s: LexerState): string
	if s.pos <= s.len then
		return s.source:sub(s.pos, s.pos)
	end
	return ''
end

function State.advance(s: LexerState): string
	local c = s.source:sub(s.pos, s.pos)
	s.pos += 1
	if c == '\n' then
		s.line += 1
	end
	return c
end

function State.addToken(s: LexerState, type: TokenType, value: string)
	table.insert(s.tokens, { type = type, value = value, line = s.line })
end

return State
