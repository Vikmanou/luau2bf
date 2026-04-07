-- expected: 12\n
local x = 3
local y = 0
while x > 0 do
	if x == 2 then
		y = y + 10
	else
		y = y + 1
	end
	x = x - 1
end
print(y)
