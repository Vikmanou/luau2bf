--!strict

local Lexer = require('./lexer')
local Parser = require('./parser')
local Codegen = require('./compiler')

local Compiler = {}

function Compiler.compile(source: string): string
	local tokens = Lexer.tokenize(source)
	local ast = Parser.parse(tokens)
	return Codegen.generate(ast)
end

return Compiler
