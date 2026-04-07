--!strict
-- All cells are unsigned bytes (0–255, wrapping).
-- No input support (`,` sets the cell to 0).

local MAX_STEPS = 10_000_000

local BFInterp = {}

function BFInterp.run(code: string, maxSteps: number?): string
	local tape: { [number]: number } = {}
	local ptr, ip, steps = 0, 1, 0
	local out: { string } = {}
	local max = maxSteps or MAX_STEPS

	local jump: { [number]: number } = {}
	local stack: { number } = {}

	for i = 1, #code do
		local c = code:sub(i, i)
		if c == '[' then
			table.insert(stack, i)
		elseif c == ']' then
			local open = table.remove(stack)
			if not open then error(`BF: unmatched ']' at {i}`) end
			jump[open], jump[i] = i, open
		end
	end

	if #stack > 0 then
		error(`BF: unmatched '[' at position {stack[#stack]}`)
	end

	local commands = {
		['>'] = function() ptr += 1 end,
		['<'] = function() ptr -= 1 end,
		['+'] = function() tape[ptr] = ((tape[ptr] or 0) + 1) % 256 end,
		['-'] = function() tape[ptr] = ((tape[ptr] or 0) - 1) % 256 end,
		['.'] = function() table.insert(out, string.char(tape[ptr] or 0)) end,
		[','] = function() tape[ptr] = 0 end,
		['['] = function() if (tape[ptr] or 0) == 0 then ip = jump[ip] end end,
		[']'] = function() if (tape[ptr] or 0) ~= 0 then ip = jump[ip] end end,
	}

	while ip <= #code do
		local c = code:sub(ip, ip)

		if commands[c] then
			if steps >= max then error(`BF: exceeded {max} steps`) end
			steps += 1
			commands[c]()
		end

		ip += 1
	end

	return table.concat(out)
end

return BFInterp
