local path = {} -- to store the path
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

-- Function to check and move the turtle
local function tryMove()
	-- Check if there's a block in front
	print("Checking front...")
	if turtle.detect() then
		print("Block detected in front.")

		-- Both right and left checks
		turtle.turnRight()
		local rightBlocked = turtle.detect()
		turtle.turnLeft() -- Turn back to original position
		turtle.turnLeft() -- Now facing left

		local leftBlocked = turtle.detect()

		-- Print the status of right and left
		print("Right blocked: " .. tostring(rightBlocked))
		print("Left blocked: " .. tostring(leftBlocked))

		-- If right is blocked, go left, and vice versa
		if rightBlocked then
			if leftBlocked then
				print("Both directions blocked, turtle is stuck!")
				return false -- Both directions blocked, turtle is stuck
			else
				-- Left available, go left
				print("Right blocked, going left.")
				turtle.turnLeft()
				turtle.forward()
				table.insert(path, "L")
			end
		else
			-- Right available, go right
			print("Right available, going right.")
			turtle.turnRight()
			turtle.forward()
			table.insert(path, "R")
		end
	else
		-- No block, move forward
		print("No block in front, moving forward.")
		turtle.forward()
		table.insert(path, "F")
	end
	return true
end

-- Optional: refuel check
if turtle.getFuelLevel() == 0 then
	print("Fuel level is 0, refueling...")
	turtle.select(1)
	turtle.refuel()
end

-- Exploration loop: keep going indefinitely until iron ore is detected
print("Starting exploration...")

while true do
	if turtle.detect() then
		local present, blockType = turtle.inspect()
		if present then
			local name = blockType.name
			print("Detected block: " .. name)

			-- If iron ore is detected, stop exploring
			if name == "minecraft:iron_ore" then
				print("Iron ore detected! Stopping exploration.")
				break
			end
		end
	end

	-- Continue moving around
	if not tryMove() then
		print("Turtle is stuck!")
		break
	end
end

-- Return to start: backtrack path
print("Returning to start...")
for i = #path, 1, -1 do
	local move = path[i]
	if move == "F" then
		reverse.F()
		print("Going back: F")
	elseif move == "R" then
		reverse.R()
		print("Going back: R")
	elseif move == "L" then
		reverse.L()
		print("Going back: L")
	end
end

print("Back at start!")
