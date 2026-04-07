--!strict

local State = require('../compiler-state')
type CodegenState = State.CodegenState

local Tape = {}

function Tape.emit(state: CodegenState, code: string)
	if code == '' then return end
	table.insert(state.output, code)
end

-- Move the pointer to the specified cell
function Tape.moveTo(state: CodegenState, target: number)
	local diff = target - state.pointer
	if diff == 0 then return end

	state.pointer = target

	local char = diff > 0 and '>' or '<'
	Tape.emit(state, string.rep(char, math.abs(diff)))
end

function Tape.allocTemp(state: CodegenState): number
	local cell = state.nextTemp
	state.nextTemp += 1
	return cell
end

function Tape.resetTemps(state: CodegenState)
	state.nextTemp = state.tempStart
end

function Tape.withTempFloor(state: CodegenState, floor: number, fn: () -> ())
	local oldStart = state.tempStart
	local oldNext = state.nextTemp

	state.tempStart = math.max(oldStart, floor)
	state.nextTemp = math.max(state.nextTemp, state.tempStart)

	fn()

	state.tempStart = oldStart
	state.nextTemp = oldNext -- Full restoration
end

-- Assigns a variable name to a cell on the tape
function Tape.allocVar(state: CodegenState, name: string): number
	local cell = state.nextVarCell
	state.variables[name] = cell
	state.nextVarCell += 1
	return cell
end

return Tape
