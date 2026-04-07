-- expected: 1\n
local x = 0
local y = 1
if x or y then
	print(1)
else
	print(0)
end
