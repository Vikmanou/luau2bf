--!strict

local State = require('../compiler-state')
local Tape = require('./tape')

type CodegenState = State.CodegenState

local Cells = {}

local function put(state: CodegenState, cell: number, chars: string)
	Tape.moveTo(state, cell)
	Tape.emit(state, chars)
end

function Cells.emitZero(state: CodegenState, cell: number)
	put(state, cell, '[-]')
end

function Cells.emitSetCell(state: CodegenState, cell: number, value: number)
	Cells.emitZero(state, cell)
	if value > 255/2 then
		put(state, cell, string.rep('-', 256 - value))
	else
		put(state, cell, string.rep('+', value))
	end
end

function Cells.emitCopy(state: CodegenState, src: number, dst: number, tmp: number)
	Cells.emitZero(state, dst)
	Cells.emitZero(state, tmp)
	put(state, src, '[')
	put(state, dst, '+')
	put(state, tmp, '+')
	put(state, src, '-]')
	put(state, tmp, '[')
	put(state, src, '+')
	put(state, tmp, '-]')
end

function Cells.emitMoveAdd(state: CodegenState, src: number, dst: number)
	put(state, src, '[')
	put(state, dst, '+')
	put(state, src, '-]')
end

function Cells.emitMoveSub(state: CodegenState, src: number, dst: number)
	put(state, src, '[')
	put(state, dst, '-')
	put(state, src, '-]')
end

-- https://esolangs.org/wiki/Brainfuck_algorithms
function Cells.emitBoolNot(state: CodegenState, cell: number, tmp: number)
	Cells.emitZero(state, tmp)
	put(state, cell, '[')
	put(state, tmp, '+')
	put(state, cell, '[-]]+')
	put(state, tmp, '[')
	put(state, cell, '-')
	put(state, tmp, '-]')
end

-- dst += src, src preserved. https://esolangs.org/wiki/Brainfuck_algorithms
function Cells.emitAddVar(state: CodegenState, dst: number, src: number, tmp: number)
	Cells.emitZero(state, tmp)
	put(state, src, '[')
	put(state, dst, '+')
	put(state, tmp, '+')
	put(state, src, '-]')
	put(state, tmp, '[')
	put(state, src, '+')
	put(state, tmp, '-]')
end

-- dst -= src, src preserved. https://esolangs.org/wiki/Brainfuck_algorithms
function Cells.emitSubVar(state: CodegenState, dst: number, src: number, tmp: number)
	Cells.emitZero(state, tmp)
	put(state, src, '[')
	put(state, dst, '-')
	put(state, tmp, '+')
	put(state, src, '-]')
	put(state, tmp, '[')
	put(state, src, '+')
	put(state, tmp, '-]')
end

-- x = x * y, y preserved. https://esolangs.org/wiki/Brainfuck_algorithms
function Cells.emitMulVar(state: CodegenState, x: number, y: number, tmp0: number, tmp1: number)
	Cells.emitZero(state, tmp0)
	Cells.emitZero(state, tmp1)
	put(state, x, '[')
	put(state, tmp1, '+')
	put(state, x, '-]')
	put(state, tmp1, '[')
	put(state, y, '[')
	put(state, x, '+')
	put(state, tmp0, '+')
	put(state, y, '-]')
	put(state, tmp0, '[')
	put(state, y, '+')
	put(state, tmp0, '-]')
	put(state, tmp1, '-]')
end

function Cells.emitDivModVar(
	state: CodegenState,
	remainder: number,
	divisor: number,
	quotient: number,
	counter: number,
	isStepComplete: number,
	divisorCopy: number,
	shouldIncrement: number
)
	Cells.emitZero(state, quotient)
	Cells.emitZero(state, counter)

	put(state, remainder, '[-')
	put(state, counter, '+')

	Cells.emitCopy(state, counter, isStepComplete, shouldIncrement)
	Cells.emitCopy(state, divisor, divisorCopy, shouldIncrement)
	Cells.emitMoveSub(state, divisorCopy, isStepComplete)

	Cells.emitSetCell(state, shouldIncrement, 1)

	put(state, isStepComplete, '[')
	put(state, shouldIncrement, '-')
	put(state, isStepComplete, '[-]]')

	put(state, shouldIncrement, '[')
	put(state, quotient, '+')
	Cells.emitZero(state, counter)
	put(state, shouldIncrement, '-]')

	put(state, remainder, ']')

	Cells.emitMoveAdd(state, counter, remainder)
end

-- if cond then dst += ifTrue else dst += ifFalse. Consumes cond, ifTrue, ifFalse.
function Cells.emitSelect(
	state: CodegenState,
	cond: number,
	dst: number,
	ifTrue: number,
	ifFalse: number
)
	local chosen = Tape.allocTemp(state)
	Cells.emitSetCell(state, chosen, 1)

	-- taken branch
	Tape.moveTo(state, cond)
	Tape.emit(state, '[')
	Cells.emitMoveAdd(state, ifTrue, dst)
	Cells.emitZero(state, ifFalse)
	Tape.moveTo(state, chosen)
	Tape.emit(state, '-')
	Tape.moveTo(state, cond)
	Tape.emit(state, '[-]]')

	-- not-taken branch
	Tape.moveTo(state, chosen)
	Tape.emit(state, '[')
	Cells.emitMoveAdd(state, ifFalse, dst)
	Cells.emitZero(state, ifTrue)
	Tape.moveTo(state, chosen)
	Tape.emit(state, '-]')
end

-- result = left < right (1 or 0), stored in leftCell. Consumes both.
function Cells.emitLessThanCells(state: CodegenState, leftCell: number, rightCell: number): number
	local leftCopy = Tape.allocTemp(state)
	local copyTmp = Tape.allocTemp(state)
	local leftTmp = Tape.allocTemp(state)
	local flag = Tape.allocTemp(state)

	Cells.emitCopy(state, leftCell, leftCopy, copyTmp)
	Cells.emitSetCell(state, leftCell, 0)

	put(state, rightCell, '[')

	Cells.emitCopy(state, leftCopy, leftTmp, copyTmp)
	Cells.emitSetCell(state, flag, 1)

	put(state, leftTmp, '[')
	Cells.emitZero(state, flag)
	put(state, leftCopy, '-')
	Cells.emitZero(state, leftTmp)
	put(state, leftTmp, ']')

	put(state, flag, '[')
	Cells.emitSetCell(state, leftCell, 1)
	put(state, flag, '[-]]')

	put(state, rightCell, '-]')
	Cells.emitZero(state, leftCopy)

	state.nextTemp = leftCell + 1
	return leftCell
end

-- result = left <= right, stored in rightCell.
function Cells.emitLessOrEqualCells(state: CodegenState, leftCell: number, rightCell: number): number
	Cells.emitLessThanCells(state, rightCell, leftCell)
	local tmp = Tape.allocTemp(state)
	Cells.emitBoolNot(state, rightCell, tmp)
	state.nextTemp = rightCell + 1
	return rightCell
end

-- result = left >= right, stored in leftCell.
function Cells.emitGreaterOrEqualCells(state: CodegenState, leftCell: number, rightCell: number): number
	Cells.emitLessThanCells(state, leftCell, rightCell)
	local tmp = Tape.allocTemp(state)
	Cells.emitBoolNot(state, leftCell, tmp)
	state.nextTemp = leftCell + 1
	return leftCell
end

return Cells
