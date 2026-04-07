--!strict

local Types = require('./types')

type TokenType = Types.TokenType
type NodeType = Types.NodeType

local Constants = {}

Constants.TokenType = table.freeze({
	NUMBER = 'NUMBER',
	KEYWORD = 'KEYWORD',
	IDENT = 'IDENT',
	COMPARE = 'COMPARE',
	ASSIGN = 'ASSIGN',
	OP = 'OP',
	LPAREN = 'LPAREN',
	RPAREN = 'RPAREN',
	COMMA = 'COMMA',
	EOF = 'EOF'
} :: { [string]: TokenType } )

Constants.NodeType = table.freeze({
	Program = 'Program',
	NumberLit = 'NumberLit',
	BoolLit = 'BoolLit',
	VarRef = 'VarRef',
	UnaryOp = 'UnaryOp',
	BinOp = 'BinOp',
	VarDecl = 'VarDecl',
	Assign = 'Assign',
	Print = 'Print',
	If = 'If',
	While = 'While',
	NumericFor = 'NumericFor'
} :: { [string]: NodeType } )

return Constants
