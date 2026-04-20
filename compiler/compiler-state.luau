--!strict

local Tables = require('./tables')

type TableInfo = Tables.TableInfo

export type CodegenState = {
	variables: { [string]: number },
	tables: { [string]: TableInfo },
	nextVarCell: number,
	tempStart: number,
	nextTemp: number,
	pointer: number,
	output: { string },
	breakStack: { number },
	diagnostics: { string },
}

local State = {}

function State.create(tempStart: number): CodegenState
	return {
		variables = {},
		tables = {},
		nextVarCell = 0,
		tempStart = tempStart,
		nextTemp = tempStart,
		pointer = 0,
		output = {},
		breakStack = {},
		diagnostics = {},
	}
end

function State.report(state: CodegenState, msg: string)
	table.insert(state.diagnostics, msg)
end

return State
