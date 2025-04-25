local path = {} -- track steps
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

-- Attempt to move and return true if successful, false if stuck or iron ore found
local function tryMove()
	local hasBlock, data = turtle.inspect()
	if hasBlock then
		print("Detected block: " .. data.name)

		if data.name == "minecraft:iron_ore" then
			print("Iron ore found! Stopping.")
			return "found"
		end

		-- Try right
		turtle.turnRight()
		if not turtle.detect() then
			turtle.forward()
			table.insert(path, "R")
			return true
		end

		-- Try left
		turtle.turnLeft() -- face forward again
		turtle.turnLeft() -- now left
		if not turtle.detect() then
			turtle.forward()
			table.insert(path, "L")
			return true
		end

		-- Now facing original direction
		turtle.turnRight()
		print("Stuck! No path.")
		return false
	else
		-- No block, just move forward
		turtle.forward()
		table.insert(path, "F")
		return true
	end
end

-- Refuel if needed
if turtle.getFuelLevel() == 0 then
	print("Fuel is 0. Refueling from slot 1...")
	turtle.select(1)
	turtle.refuel()
end

print("Starting maze traversal...")

while true do
	local result = tryMove()
	if result == "found" then
		break
	elseif not result then
		print("Turtle stuck. Ending.")
		break
	end
end

-- Go back
print("Backtracking...")
for i = #path, 1, -1 do
	local move = path[i]
	reverse[move]()
	print("Backtracked: " .. move)
end

print("Returned to start.")
