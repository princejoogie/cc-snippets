local path = {}
local reverse = {
	F = function()
		turtle.back()
	end,
	R = function()
		turtle.turnLeft()
	end,
	L = function()
		turtle.turnRight()
	end,
}

local function tryMove()
	if turtle.detect() then
		turtle.turnRight()
		table.insert(path, "R")
		if turtle.detect() then
			-- Turn around (left twice from current position)
			turtle.turnLeft()
			turtle.turnLeft()
			table.insert(path, "L")
			table.insert(path, "L")
			if turtle.detect() then
				return false -- Stuck!
			else
				turtle.forward()
				table.insert(path, "F")
			end
		else
			turtle.forward()
			table.insert(path, "F")
		end
	else
		turtle.forward()
		table.insert(path, "F")
	end
	return true
end

-- Optional: refuel check
if turtle.getFuelLevel() == 0 then
	turtle.select(1)
	turtle.refuel()
end

-- Exploration phase
for i = 1, 100 do
	if not tryMove() then
		print("Turtle is stuck!")
		break
	end
end

-- Reverse phase
print("Returning to start...")
for i = #path, 1, -1 do
	local move = path[i]
	if move == "F" then
		reverse.F()
	elseif move == "R" then
		reverse.R()
	elseif move == "L" then
		reverse.L()
	end
end

print("Back at start!")
