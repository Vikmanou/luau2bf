--!strict
-- BF patterns

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Tape = require('./tape')

local Cells = {}

local function put(state: CodegenState, cell: number, chars: string)
	Tape.moveTo(state, cell)
	Tape.emit(state, chars)
end

function Cells.emitZero(state: CodegenState, cell: number)
	-- cell [ - ]: Zero the cell
	put(state, cell, '[-]')
end

function Cells.emitSetCell(state: CodegenState, cell: number, value: number)
	-- cell [ value ]: Set the cell to the specified value
	Cells.emitZero(state, cell)
	if value > 0 then
		put(state, cell, string.rep('+', value % 256))
	end
end

function Cells.emitCopy(state: CodegenState, src: number, dst: number, tmp: number)
	Cells.emitZero(state, dst)
	Cells.emitZero(state, tmp)

	-- src [ dst+ tmp+ src- ]: Move src to dst and tmp while zeroing src
	put(state, src, '[')
	put(state, dst, '+')
	put(state, tmp, '+')
	put(state, src, '-]')
	
	-- tmp [ src+ tmp- ]: Move tmp back to src while zeroing tmp
	put(state, tmp, '[')
	put(state, src, '+')
	put(state, tmp, '-]')
end

function Cells.emitMoveAdd(state: CodegenState, src: number, dst: number)
	-- src [ dst+ src- ]: Move src to dst while zeroing src
	put(state, src, '[')
	put(state, dst, '+')
	put(state, src, '-]')
end

function Cells.emitMoveSub(state: CodegenState, src: number, dst: number)
	-- src [ dst- src- ]: Move src to dst while zeroing src
	put(state, src, '[')
	put(state, dst, '-')
	put(state, src, '-]')
end

-- x' = not x: result is 0 if x nonzero, 1 if x zero. Modifies cell in-place.
-- Algorithm: https://esolangs.org/wiki/Brainfuck_algorithms
-- tmp[-] cell[tmp+ cell[-]]+ tmp[cell- tmp-]
function Cells.emitBoolNot(state: CodegenState, cell: number, tmp: number)
	Cells.emitZero(state, tmp)

	put(state, cell, '[')
	put(state, tmp, '+')
	put(state, cell, '[-]]+')
	put(state, tmp, '[')
	put(state, cell, '-')
	put(state, tmp, '-]')
end

-- dst += src, src is preserved. Uses 1 temp.
-- Algorithm: https://esolangs.org/wiki/Brainfuck_algorithms
-- tmp[-] src[dst+ tmp+ src-] tmp[src+ tmp-]
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

-- dst -= src, src is preserved. Uses 1 temp.
-- Algorithm: https://esolangs.org/wiki/Brainfuck_algorithms
-- tmp[-] src[dst- tmp+ src-] tmp[src+ tmp-]
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

-- x = x * y, y is preserved. Uses 2 temps.
-- Algorithm: https://esolangs.org/wiki/Brainfuck_algorithms
-- tmp0[-] tmp1[-] x[tmp1+x-] tmp1[y[x+tmp0+y-]tmp0[y+tmp0-]tmp1-]
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

    -- remainder [ counter+ remainder- ]: Move remainder to counter while zeroing remainder
    put(state, remainder, '[-')
    put(state, counter, '+')

    -- Setup to check if we have reached the divisor
    Cells.emitCopy(state, counter, isStepComplete, shouldIncrement)
    Cells.emitCopy(state, divisor, divisorCopy, shouldIncrement)
    Cells.emitMoveSub(state, divisorCopy, isStepComplete)

    -- Default the 'flag' to true (1)
    Cells.emitSetCell(state, shouldIncrement, 1)

	-- isStepComplete [ shouldIncrement- isStepComplete- ]: If we haven't hit the divisor, set shouldIncrement to 0
    put(state, isStepComplete, '[')
    put(state, shouldIncrement, '-')
    put(state, isStepComplete, '[-]]')

	-- counter [ divisorCopy+ counter- ]: Move counter back to itself while decrementing divisorCopy
    put(state, shouldIncrement, '[')
    put(state, quotient, '+')
    Cells.emitZero(state, counter)
    put(state, shouldIncrement, '-]')

	-- Close the loop.
    put(state, remainder, ']')

    -- Move anything left in counter back to remainder
    Cells.emitMoveAdd(state, counter, remainder)
end

return Cells
