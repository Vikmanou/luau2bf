--!strict

local Tables = require('./tables')

type TableInfo = Tables.TableInfo

export type FlowEntry = {
	kind: string,        -- 'break' or 'return'
	cell: number,        -- gate cell that emitBlock checks
	resultCell: number?, -- only for 'return': where to store return value
}

export type FunctionDef = {
	params: { string },
	body: any,
	line: number,
}

export type CodegenState = {
	variables: { [string]: number },
	tables: { [string]: TableInfo },
	nextVarCell: number,
	tempStart: number,
	nextTemp: number,
	pointer: number,
	output: { string },
	breakStack: { FlowEntry },
	diagnostics: { string },
	functions: { [string]: FunctionDef },
	callStack: { string },
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
		functions = {},
		callStack = {},
	}
end

function State.report(state: CodegenState, msg: string)
	table.insert(state.diagnostics, msg)
end

return State
