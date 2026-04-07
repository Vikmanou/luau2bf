--!strict

local Types = require('../../shared/types')
local State = require('../compiler-state')
local Primitives = require('../bf-emitter')
local Expr = require('../expressions')
local Constants = require('../../shared/constants')

type ASTNode = Types.ASTNode
type CodegenState = State.CodegenState
type EmitBlock = (state: CodegenState, stmts: { ASTNode }) -> ()

local NT = Constants.NodeType

local function emitNumericFor(state: CodegenState, node: ASTNode, emitBlock: EmitBlock)
    local iCell = Primitives.allocVar(state, node.name)
    local stopName = `__stop__{node.name}`
    local stopCell = Primitives.allocVar(state, stopName)

    -- Initialize i and stop
    Primitives.withTempFloor(state, state.nextTemp, function()
        local startVal = Expr.emitExpr(state, node.start)
        Primitives.emitMoveAdd(state, startVal, iCell)
        
        local stopVal = Expr.emitExpr(state, node.stop)
        Primitives.emitMoveAdd(state, stopVal, stopCell)
    end)

    -- Loop Condition Helper
    local function emitCondition(): number
        local condExpr: ASTNode = {
            type = 'BinOp',
            op = '<=',
            left = { type = 'VarRef', name = node.name, line = node.line },
            right = { type = 'VarRef', name = stopName, line = node.line }
        }
        return Expr.emitExpr(state, condExpr)
    end

    -- Start Loop
    local condCell = emitCondition()
    Primitives.moveTo(state, condCell)
    Primitives.emit(state, '[')
    
    -- Clear the condition cell inside the loop so it doesn't interfere with the next calculation
    Primitives.emitZero(state, condCell) 

    emitBlock(state, node.body)

    Primitives.moveTo(state, iCell)
    Primitives.emit(state, '+')

    -- Re-evaluate condition to determine if we loop again
    local nextCond = emitCondition()
    
    -- Move the new condition result back to the loop-control cell
    Primitives.emitMoveAdd(state, nextCond, condCell)
    
    Primitives.moveTo(state, condCell)
    Primitives.emit(state, ']')
    
    Primitives.resetTemps(state)
end

return {
    [NT.NumericFor] = emitNumericFor
}