--!strict

local Math = require('./builtins/libraries/math')

local builtins: { [string]: any } = {}

for key, handler in Math do
	builtins[key :: string] = handler
end

return builtins
