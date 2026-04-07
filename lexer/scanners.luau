--!strict
-- Individual token scanning functions.

local Constants = require('../shared/constants')
local TT = Constants.TokenType

local LexState = require('./lexer-state')
type LexerState = LexState.LexerState

local KW = require('./keywords')
local KEYWORDS = KW.KEYWORDS
local UNSUPPORTED_CHARS = KW.UNSUPPORTED_CHARS

local Scanners = {}

function Scanners.skipWhitespace(s: LexerState)
	LexState.advance(s)
end

function Scanners.skipComment(s: LexerState)
	while s.pos <= s.len and LexState.peek(s) ~= '\n' do
		LexState.advance(s)
	end
end

function Scanners.scanNumber(s: LexerState)
	local start = s.pos
	while s.pos <= s.len and LexState.peek(s):find('%d') do
		LexState.advance(s)
	end
	LexState.addToken(s, TT.NUMBER, s.source:sub(start, s.pos - 1))
end

function Scanners.scanIdentOrKeyword(s: LexerState)
	local start = s.pos
	while s.pos <= s.len and LexState.peek(s):find('[a-zA-Z0-9_]') do
		LexState.advance(s)
	end
	local word = s.source:sub(start, s.pos - 1)
	if word == 'local' then
		s.inLocalDecl = true
	end
	if KEYWORDS[word] then
		LexState.addToken(s, TT.KEYWORD, word)
	else
		LexState.addToken(s, TT.IDENT, word)
	end
end

function Scanners.skipTypeAnnotation(s: LexerState)
	LexState.advance(s) -- skip the ':'
	while s.pos <= s.len do
		local ch = LexState.peek(s)
		if ch == '=' or ch == '\n' then
			break
		end
		LexState.advance(s)
	end
end

function Scanners.scanTwoCharOp(s: LexerState): boolean
	if s.pos + 1 <= s.len then
		local two = s.source:sub(s.pos, s.pos + 1)
		if two == '==' or two == '~=' or two == '<=' or two == '>=' then
			LexState.addToken(s, TT.COMPARE, two)
			s.pos += 2
			return true
		end
	end
	return false
end

function Scanners.scanSingleChar(s: LexerState, c: string): boolean
	if c == '=' then
		LexState.addToken(s, TT.ASSIGN, c)
		LexState.advance(s)
		s.inLocalDecl = false
		return true
	end

	if c == '<' or c == '>' then
		LexState.addToken(s, TT.COMPARE, c)
		LexState.advance(s)
		return true
	end

	if c == '+' or c == '-' or c == '*' or c == '/' or c == '%' then
		LexState.addToken(s, TT.OP, c)
		LexState.advance(s)
		return true
	end

	if c == '(' then LexState.addToken(s, TT.LPAREN, c); LexState.advance(s); return true end
	if c == ')' then LexState.addToken(s, TT.RPAREN, c); LexState.advance(s); return true end
	if c == ',' then LexState.addToken(s, TT.COMMA, c); LexState.advance(s); return true end

	return false
end

function Scanners.checkUnsupported(s: LexerState, c: string)
	local msg = UNSUPPORTED_CHARS[c]
	if msg then
		error(`Error [line {s.line}]: Unsupported character '{c}': {msg}`)
	end
	error(`Error [line {s.line}]: Unexpected character '{c}'`)
end

return Scanners
