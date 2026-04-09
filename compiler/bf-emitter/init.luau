--!strict

local Tape = require('./bf-emitter/tape')
local BfPatterns = require('./bf-emitter/bf-patterns')

return {
	emit = Tape.emit,
	moveTo = Tape.moveTo,
	allocTemp = Tape.allocTemp,
	resetTemps = Tape.resetTemps,
	withTempFloor = Tape.withTempFloor,
	allocVar = Tape.allocVar,

	emitZero = BfPatterns.emitZero,
	emitSetCell = BfPatterns.emitSetCell,
	emitCopy = BfPatterns.emitCopy,
	emitMoveAdd = BfPatterns.emitMoveAdd,
	emitMoveSub = BfPatterns.emitMoveSub,
	emitBoolNot = BfPatterns.emitBoolNot,
	emitAddVar = BfPatterns.emitAddVar,
	emitSubVar = BfPatterns.emitSubVar,
	emitMulVar = BfPatterns.emitMulVar,
	emitDivModVar = BfPatterns.emitDivModVar,
}
