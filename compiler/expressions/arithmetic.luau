--!strict

local Types = require('../../shared/types')
local State = require('../compiler-state')
local Primitives = require('../bf-emitter')

type ASTNode = Types.ASTNode
type CodegenState = State.CodegenState
type EmitExpr = (state: CodegenState, node: ASTNode) -> number


local function emitAdd(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local rightCell = emitExpr(state, node.right)
	
	Primitives.emitMoveAdd(state, rightCell, leftCell)
	state.nextTemp = rightCell -- "pops" the rightCell from temp
	return leftCell
end


local function emitSub(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local leftCell = emitExpr(state, node.left)
	local rightCell = emitExpr(state, node.right)
	
	Primitives.emitMoveSub(state, rightCell, leftCell)
	state.nextTemp = rightCell
	return leftCell
end


local function emitMul(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	local left = emitExpr(state, node.left)
	local right = emitExpr(state, node.right)

	Primitives.withTempFloor(state, state.nextTemp, function()
		local result = Primitives.allocTemp(state)
		local tmp = Primitives.allocTemp(state)
		local scratch = Primitives.allocTemp(state)

		Primitives.emitZero(state, result)
		
		-- while left != 0: result += right
		Primitives.moveTo(state, left)
		Primitives.emit(state, '[')
		Primitives.emitCopy(state, right, tmp, scratch)
		Primitives.emitMoveAdd(state, tmp, result)
		Primitives.moveTo(state, left)
		Primitives.emit(state, '-]')

		-- Move result back to the 'left' cell
		Primitives.emitZero(state, left)
		Primitives.emitMoveAdd(state, result, left)
	end)

	state.nextTemp = right -- Free everything after 'left'
	return left
end

-- 3. Division and Modulo
local function emitDivMod(state: CodegenState, node: ASTNode, emitExpr: EmitExpr, isDiv: boolean): number
	local left = emitExpr(state, node.left)
	local right = emitExpr(state, node.right)

	Primitives.withTempFloor(state, state.nextTemp, function()
		local quotient = Primitives.allocTemp(state)
		local counter = Primitives.allocTemp(state)
		local s1 = Primitives.allocTemp(state)
		local s2 = Primitives.allocTemp(state)
		local s3 = Primitives.allocTemp(state)

		Primitives.emitDivModVar(state, left, right, quotient, counter, s1, s2, s3)

		if isDiv then
			Primitives.emitZero(state, left)
			Primitives.emitMoveAdd(state, quotient, left)
		end
		-- If isDiv is false, 'left' naturally contains the remainder (modulo)
	end)

	state.nextTemp = right
	return left
end

local function emitDiv(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	return emitDivMod(state, node, emitExpr, true)
end


local function emitMod(state: CodegenState, node: ASTNode, emitExpr: EmitExpr): number
	return emitDivMod(state, node, emitExpr, false)
end


return {
	['+'] = emitAdd,
	['-'] = emitSub,
	['*'] = emitMul,
	['/'] = emitDiv,
	['%'] = emitMod,
}