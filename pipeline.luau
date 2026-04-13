--!strict

local syntax = require('@std/syntax')
local Linter = require('./linter')
local Codegen = require('./compiler')

local Compiler = {}

function Compiler.compile(source: string): string
	Linter.validate(source)
	
	local result = syntax.parse(source)
	return Codegen.generate(result.root)
end

return Compiler
