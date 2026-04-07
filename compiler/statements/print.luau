--!strict
-- Print statement codegen: decimal output followed by newline.

local Types = require('../../shared/types')
type ASTNode = Types.ASTNode

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Primitives = require('../bf-emitter')

local Expr = require('../expressions')
local Constants = require('../../shared/constants')

local NT = Constants.NodeType

-- Print a single digit: copy digitCell, add ASCII '0', output, clear.
local function emitDigit(state: CodegenState, digitCell: number, cpTmp: number, scratch: number)
	Primitives.emitCopy(state, digitCell, scratch, cpTmp)
	Primitives.moveTo(state, scratch)
	Primitives.emit(state, string.rep('+', 48))
	Primitives.emit(state, '.')
	Primitives.emitZero(state, scratch)
end

local function emitPlaceValue(state: CodegenState, work: number, divisorVal: number, printed: number)
    Primitives.withTempFloor(state, state.nextTemp, function()
        local divisor = Primitives.allocTemp(state)
        local quot = Primitives.allocTemp(state)
        local cnt = Primitives.allocTemp(state)
        local sc1 = Primitives.allocTemp(state)
        local sc2 = Primitives.allocTemp(state)
        local sc3 = Primitives.allocTemp(state)
        local cpTmp = Primitives.allocTemp(state)
        local dig = Primitives.allocTemp(state)

        Primitives.emitSetCell(state, divisor, divisorVal)
        Primitives.emitDivModVar(state, work, divisor, quot, cnt, sc1, sc2, sc3)

        Primitives.emitCopy(state, quot, dig, cpTmp)
        Primitives.emitCopy(state, printed, sc1, cpTmp)
        Primitives.emitMoveAdd(state, sc1, dig) -- dig = digit + printed
        
        Primitives.moveTo(state, dig)
        Primitives.emit(state, '[')
        emitDigit(state, quot, cpTmp, sc1)
        Primitives.emitSetCell(state, printed, 1) -- Mark that we've printed a digit
        Primitives.moveTo(state, dig)
        Primitives.emit(state, '[-]]')
    end)
end

local function emitPrint(state: CodegenState, node: ASTNode)
    local val = Expr.emitExpr(state, node.expr)

    Primitives.withTempFloor(state, state.nextTemp, function()
        local work = Primitives.allocTemp(state)
        local printed = Primitives.allocTemp(state)
        local cpTmp = Primitives.allocTemp(state)
        local scratch = Primitives.allocTemp(state)

        Primitives.emitCopy(state, val, work, cpTmp)
        Primitives.emitSetCell(state, printed, 0)

        emitPlaceValue(state, work, 100, printed)
        emitPlaceValue(state, work, 10, printed)
        emitDigit(state, work, cpTmp, scratch)

        -- Newline
        Primitives.emitSetCell(state, scratch, 10)
        Primitives.moveTo(state, scratch)
        Primitives.emit(state, '.')
        Primitives.emitZero(state, scratch)
    end)
end

return {
	[NT.Print] = emitPrint
}
