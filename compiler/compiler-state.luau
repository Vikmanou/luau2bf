--!strict

export type CodegenState = {
	variables: { [string]: number }, -- variable name -> cell index
	nextVarCell: number, -- next cell to allocate for a variable
	tempStart: number, -- first cell index reserved for temporaries
	nextTemp: number, -- next temp cell to allocate
	pointer: number, -- current BF tape pointer position
	output: { string }, -- accumulated BF code fragments
	breakStack: { number }, -- stack of break-flag cell indices for nested loops
	diagnostics: { string }, -- accumulated compile errors
}

local State = {}

function State.create(tempStart: number): CodegenState
	return {
		variables = {},
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
