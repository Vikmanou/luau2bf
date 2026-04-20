--!strict

local Math = require('./builtins/math')

local builtins: { [string]: any } = {}

for k, v in Math do builtins[k] = v end

return builtins
