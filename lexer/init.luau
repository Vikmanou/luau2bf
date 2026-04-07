--!strict
local Types = require('./shared/types')
local Constants = require('./shared/constants')
local LexState = require('./lexer/lexer-state')
local Scanners = require('./lexer/scanners')

type Token = Types.Token
type LexerState = LexState.LexerState

local TT = Constants.TokenType

local Lexer = {}

function Lexer.tokenize(source: string): { Token }
	local lexerState = LexState.create(source)

	while lexerState.pos <= lexerState.len do
		local c = LexState.peek(lexerState)

		-- 1. Ignored content
		if c:find('%s') then
			Scanners.skipWhitespace(lexerState)
			continue
		end

		-- Comments
		if c == '-' and lexerState.source:sub(lexerState.pos + 1, lexerState.pos + 1) == '-' then
			Scanners.skipComment(lexerState)
			continue
		end

		-- 2. Type System specific (Luau)
		if c == ':' and lexerState.inLocalDecl then
			Scanners.skipTypeAnnotation(lexerState)
			continue
		end

		-- 3. Complex Scanners (Patterns)
		if c:find('%d') then
			Scanners.scanNumber(lexerState)
			continue
		end

		if c:find('[%a_]') then -- %a covers [a-zA-Z]
			Scanners.scanIdentOrKeyword(lexerState)
			continue
		end

		-- 4. Operators and Symbols
		-- We try Two-Char first so '>=' doesn't get picked up as '>'
		if Scanners.scanTwoCharOp(lexerState) then
			continue
		end

		if Scanners.scanSingleChar(lexerState, c) then
			continue
		end

		-- 5. Fallback
		Scanners.checkUnsupported(lexerState, c)
	end

	LexState.addToken(lexerState, TT.EOF, '')
	return lexerState.tokens
end

return Lexer