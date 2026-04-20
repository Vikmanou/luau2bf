local syntax = require('@std/syntax')
local json = require('@std/json')

local function dump(source)
    local result = syntax.parse(source)
    print(json.serialize(result.root))
end

dump([[local tbl = {10, 20, 30}
print(tbl[2])]])
print('---')
dump([[local tbl = {foo = 10, [5] = 20, ['bar'] = 30}
print(tbl['bar'])]])
