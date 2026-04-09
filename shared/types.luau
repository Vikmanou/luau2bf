--!strict

export type TokenType =
	'NUMBER' | 'KEYWORD' | 'IDENT' | 'COMPARE' | 'ASSIGN' | 'COMPOUND_ASSIGN' |
	'OP' | 'LPAREN' | 'RPAREN' | 'COMMA' | 'EOF'

export type NodeType =
	'Program' | 'NumberLit' | 'BoolLit' | 'VarRef' |
	'UnaryOp' | 'BinOp' |
	'VarDecl' | 'Assign' | 'Print' |
	'If' | 'While' | 'NumericFor' | 'RepeatUntil' | 'Break'

export type Token = {
	type: TokenType,
	value: string,
	line: number,
}

export type ASTNode = {
	type: NodeType,
	[string]: any,
}

return {}
