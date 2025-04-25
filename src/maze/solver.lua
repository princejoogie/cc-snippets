-- my test maze:
--
-- ++++++++
-- +     X+
-- +++ ++ +
-- +    + +
-- + ++ + +
-- +O+    +
-- ++++++++
--
-- moving forward from the start will "move up" the maze
-- === Utility ===
local function key(pos)
	return pos.x .. "," .. pos.y
end

local function heuristic(a, b)
	return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

-- === Direction State ===
local pos = { x = 0, y = 0 }
local dir = 0 -- 0=north, 1=east, 2=south, 3=west

local directions = {
	[0] = { x = 0, y = -1 },
	[1] = { x = 1, y = 0 },
	[2] = { x = 0, y = 1 },
	[3] = { x = -1, y = 0 },
}

local function turnTo(newDir)
	local diff = (newDir - dir) % 4
	if diff == 1 then
		turtle.turnRight()
	elseif diff == 2 then
		turtle.turnRight()
		turtle.turnRight()
	elseif diff == 3 then
		turtle.turnLeft()
	end
	dir = newDir
end

local function moveForward()
	if turtle.forward() then
		pos.x = pos.x + directions[dir].x
		pos.y = pos.y + directions[dir].y
		return true
	end
	return false
end

-- === World Map ===
local known = {} -- key(pos) -> "open" | "blocked"

local function isKnownBlocked(x, y)
	return known[key { x = x, y = y }] == "blocked"
end

local function canMoveTo(x, y)
	local k = key { x = x, y = y }
	if known[k] == "blocked" then
		return false
	elseif known[k] == "open" then
		return true
	end

	-- Face toward position to test
	for d = 0, 3 do
		local dx, dy = directions[d].x, directions[d].y
		if pos.x + dx == x and pos.y + dy == y then
			turnTo(d)
			if turtle.detect() then
				known[k] = "blocked"
				return false
			else
				known[k] = "open"
				return true
			end
		end
	end

	return false -- unknown and unreachable from current pos
end

-- === A* ===
local function popLowestF(openSet, fScore)
	local lowestIndex = 1
	for i = 2, #openSet do
		if fScore[openSet[i]] < fScore[openSet[lowestIndex]] then
			lowestIndex = i
		end
	end
	local node = openSet[lowestIndex]
	table.remove(openSet, lowestIndex)
	return node
end

local function neighbors(pos)
	return {
		{ x = pos.x, y = pos.y - 1, dir = 0 },
		{ x = pos.x + 1, y = pos.y, dir = 1 },
		{ x = pos.x, y = pos.y + 1, dir = 2 },
		{ x = pos.x - 1, y = pos.y, dir = 3 },
	}
end

local function aStar(start, goal)
	local openSet = { key(start) }
	local cameFrom = {}
	local gScore = { [key(start)] = 0 }
	local fScore = { [key(start)] = heuristic(start, goal) }
	local posMap = { [key(start)] = start }

	while #openSet > 0 do
		local currentKey = popLowestF(openSet, fScore)
		local current = posMap[currentKey]

		if current.x == goal.x and current.y == goal.y then
			local totalPath = { current }
			while cameFrom[currentKey] do
				currentKey = cameFrom[currentKey]
				table.insert(totalPath, 1, posMap[currentKey])
			end
			return totalPath
		end

		for _, neighbor in ipairs(neighbors(current)) do
			local nk = key(neighbor)
			posMap[nk] = neighbor

			if canMoveTo(neighbor.x, neighbor.y) then
				local tentativeG = gScore[currentKey] + 1
				if gScore[nk] == nil or tentativeG < gScore[nk] then
					cameFrom[nk] = currentKey
					gScore[nk] = tentativeG
					fScore[nk] = tentativeG + heuristic(neighbor, goal)

					local inOpenSet = false
					for _, k in ipairs(openSet) do
						if k == nk then
							inOpenSet = true
							break
						end
					end
					if not inOpenSet then
						table.insert(openSet, nk)
					end
				end
			end
		end
	end

	return nil -- no path
end

-- === Path Executor ===
local function followPath(path)
	for i = 2, #path do
		local curr = path[i - 1]
		local next = path[i]
		for d = 0, 3 do
			if curr.x + directions[d].x == next.x and curr.y + directions[d].y == next.y then
				turnTo(d)
				if not moveForward() then
					print("Failed to move to", next.x, next.y)
					return false
				end
				break
			end
		end
	end
	return true
end

-- === Refuel ===
if turtle.getFuelLevel() == 0 then
	turtle.select(1)
	turtle.refuel()
end

-- === MAIN ===
local GOAL = { x = 5, y = -4 } -- 'X' relative to 'O' at {0,0}

-- Probe adjacent blocks so A* has at least some data
for d = 0, 3 do
	local checkX = pos.x + directions[d].x
	local checkY = pos.y + directions[d].y
	canMoveTo(checkX, checkY)
end

print("Starting A* pathfinding...")
local path = aStar(pos, GOAL)

if path then
	print("Path found. Following...")
	followPath(path)
	print("Arrived at destination.")
else
	print("No path found!")
end
