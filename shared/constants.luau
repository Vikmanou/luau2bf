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
	COMPOUND_ASSIGN = 'COMPOUND_ASSIGN',
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
	NumericFor = 'NumericFor',
	RepeatUntil = 'RepeatUntil',
	Break = 'Break'
} :: { [string]: NodeType } )

Constants.Flags = table.freeze({
	REPEAT_FLAG = '__repeat_flag__',
	BREAK_PREFIX = '__brk_',
	BREAK_SUFFIX = '__',
	FOR_STOP_PREFIX = '__stop__',
	FOR_STEP_PREFIX = '__step__'
})

return Constants
