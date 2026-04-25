--!strict

local Math = require('./builtins/libraries/math')
local String = require('./builtins/libraries/string')
local Table = require('./builtins/libraries/table')

local builtins: { [string]: any } = {}

for key, handler in Math do
	builtins[key :: string] = handler
end

for key, handler in String do
	builtins[key :: string] = handler
end

for key, handler in Table do
	builtins[key :: string] = handler
end

return builtins
