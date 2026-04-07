--!strict

local fs = require('@lute/fs')
local process = require('@lute/process')
local Compiler = require('./pipeline')

local args = process.args

if #args < 2 then
	print('Usage: lute compile.luau <input.luau>')
	process.exit(1)
end

local inputPath = args[2]
local outputPath = inputPath:gsub('%.luau$', '.bf')

local fh, openErr = fs.open(inputPath, 'r')
if not fh then
	print(`Error: Could not open file '{inputPath}': {tostring(openErr)}`)
	process.exit(1)
end
local source = fs.read(fh, '*a')
fs.close(fh)

local compileOk, result = pcall(function()
	return Compiler.compile(source)
end)

if not compileOk then
	print(tostring(result))
	process.exit(1)
end

local bf = result :: string

local wfh, writeErr = fs.open(outputPath, 'w')
if not wfh then
	print(`Error: Could not open file '{outputPath}' for writing: {tostring(writeErr)}`)
	process.exit(1)
end
fs.write(wfh, bf)
fs.close(wfh)

print(`Compiled {inputPath} -> {outputPath} ({#bf} characters)`)
