--!strict

local Linter = require('./linter')
local Lexer = require('./lexer')
local Parser = require('./parser')
local Fold = require('./optimizer/fold')
local Codegen = require('./compiler')

local Compiler = {}

function Compiler.compile(source: string): string
	Linter.validate(source)

	local tokens = Lexer.tokenize(source)
	local ast = Parser.parse(tokens)
	ast = Fold.fold(ast)
	return Codegen.generate(ast)
end

return Compiler
