--!strict

local test = require('@std/test')
local Lexer = require('../lexer')
local Parser = require('../parser')
local Fold = require('../optimizer/fold')

local function foldExpr(source: string)
	local tokens = Lexer.tokenize(source)
	local ast = Parser.parse(tokens)
	local folded = Fold.fold(ast)
	return folded.body
end

test.case('fold: BinOp number literals collapse to NumberLit', function(asserts)
	local stmt = foldExpr('print(3 + 2)')[1]

	-- Should be NumberLit(5), not a BinOp
	asserts.eq('NumberLit', stmt.expr.type)
	asserts.eq(5, stmt.expr.value)
end)

test.case('fold: nested arithmetic fully collapses', function(asserts)
	local stmt = foldExpr('print(2 * 3 + 4)')[1]

	asserts.eq('NumberLit', stmt.expr.type)
	asserts.eq(10, stmt.expr.value)
end)

test.case('fold: subtraction with variable stays BinOp', function(asserts)
	local stmt = foldExpr('local x = 5\nprint(x - 1)')[2]

	asserts.eq('BinOp', stmt.expr.type)
end)

test.case('fold: n * 1 identity reduces to VarRef', function(asserts)
	local stmt = foldExpr('local x = 7\nprint(x * 1)')[2]

	-- x * 1 should fold to just x (a VarRef)
	asserts.eq('VarRef', stmt.expr.type)
end)

test.case('fold: 0 * n identity reduces to NumberLit(0)', function(asserts)
	local stmt = foldExpr('local x = 99\nprint(0 * x)')[2]

	asserts.eq('NumberLit', stmt.expr.type)
	asserts.eq(0, stmt.expr.value)
end)

test.case('fold: n + 0 identity reduces to VarRef', function(asserts)
	local stmt = foldExpr('local x = 4\nprint(x + 0)')[2]

	asserts.eq('VarRef', stmt.expr.type)
end)

test.case('fold: comparison of literals collapses to BoolLit', function(asserts)
	local stmt = foldExpr('print(3 > 2)')[1]

	asserts.eq('BoolLit', stmt.expr.type)
	asserts.eq(true, stmt.expr.value)
end)

test.case('fold: not true collapses to BoolLit(false)', function(asserts)
	local stmt = foldExpr('print(not true)')[1]

	asserts.eq('BoolLit', stmt.expr.type)
	asserts.eq(false, stmt.expr.value)
end)

test.case('fold: VarDecl rhs is folded', function(asserts)
	local stmt = foldExpr('local x = 10 - 4')[1]
	
	-- x's initialiser should be NumberLit(6)
	asserts.eq('NumberLit', stmt.expr.type)
	asserts.eq(6, stmt.expr.value)
end)
