--width and height of maze, must be odd
w = 15
h = 9
d = 15

--To keep track of current position within the maze
--Z is height
curX = 0
curY = 0
curZ = 0 -- maze relative z
worldZ = 0 --world relative z

--These are maze relative N/S/E/W
--Wherever you turtle is pointing when you start the maze is "north"
--Turtle will start in the 'Southwest' corner of the maze
-- 0=N 1=E 2=S 3=W
curRotation = 0

math.randomseed(os.time())
--math.randomseed(5)

--The light field below is only for debugging purposes
--You can remove it for performance reasons
cells = {}
--initialize cells
for i = 0, w - 1 do
	cells[i] = {}
	for j = 0, d - 1 do
		cells[i][j] = {}
		for k = 0, h - 1 do
			cell = { visited = false, x = i, y = j, z = k, light = false }
			cells[i][j][k] = cell
		end
	end
end

--neighbors are two and only two cells away in cardinal directions
--this leaves the perimeter maze walls solid
--we tag each neighbor as vertical or not so we can go vertical less often
--for a more pleasant to navigate maze
function getNeighbors(cell)
	neighbors = {}
	count = 0
	x = cell.x
	y = cell.y
	z = cell.z
	if x + 2 < w - 1 then
		neighbor = { cell = cells[x + 2][y][z], vertical = false }
		neighbors[count] = neighbor
		count = count + 1
	end
	if x - 2 >= 1 then
		neighbor = { cell = cells[x - 2][y][z], vertical = false }
		neighbors[count] = neighbor
		count = count + 1
	end
	if y + 2 < d - 1 then
		neighbor = { cell = cells[x][y + 2][z], vertical = false }
		neighbors[count] = neighbor
		count = count + 1
	end
	if y - 2 >= 1 then
		neighbor = { cell = cells[x][y - 2][z], vertical = false }
		neighbors[count] = neighbor
		count = count + 1
	end
	if z + 2 < h - 1 then
		neighbor = { cell = cells[x][y][z + 2], vertical = true }
		neighbors[count] = neighbor
		count = count + 1
	end
	if z - 2 >= 1 then
		neighbor = { cell = cells[x][y][z - 2], vertical = true }
		neighbors[count] = neighbor
		count = count + 1
	end

	return neighbors
end

--get a random neighbor cell that is unvisited
function getRandomUnvisitedNeighbor(cell)
	neighbors = getNeighbors(cell)
	unvisitedNeighbors = {}
	count = 0

	for k, v in pairs(neighbors) do
		if v.cell.visited == false then
			unvisitedNeighbors[count] = v
			count = count + 1
		end
	end

	--This holds off on vertical path choices until the last minute
	--So there are less up and down movements which are tiresome
	--for the player to navigate
	--you can just toss this if you prefer not to do this
	if count > 2 then
		for i = count - 1, 0, -1 do
			neighbor = unvisitedNeighbors[i]
			if neighbor.vertical == true then
				table.remove(unvisitedNeighbors, i)
				count = count - 1
			end
		end
	end

	if count == 0 then
		return nil
	end

	--get a random neihgbor
	r = math.random(count) - 1
	return unvisitedNeighbors[r].cell
end

--given two neighboring cells, get the cell between them
function cellBetween(cell1, cell2)
	if cell1.x > cell2.x then
		return cells[cell1.x - 1][cell1.y][cell1.z]
	end

	if cell1.x < cell2.x then
		return cells[cell1.x + 1][cell1.y][cell1.z]
	end

	if cell1.y > cell2.y then
		return cells[cell1.x][cell1.y - 1][cell1.z]
	end

	if cell1.y < cell2.y then
		return cells[cell1.x][cell1.y + 1][cell1.z]
	end

	if cell1.z > cell2.z then
		return cells[cell1.x][cell1.y][cell1.z - 1]
	end

	if cell1.z < cell2.z then
		return cells[cell1.x][cell1.y][cell1.z + 1]
	end
end

--the main recursive function to traverse the maze
function recur(curCell)
	--mark current cell as visited
	curCell.visited = true

	--check each neighbor cell
	for i = 1, 6 do
		nCell = getRandomUnvisitedNeighbor(curCell)
		if nCell ~= nil then
			-- clear the cell between the neighbors
			bCell = cellBetween(curCell, nCell)
			bCell.visited = true
			--push current cell onto the stack and move on the neighbor cell
			recur(nCell)
		end
	end
end

--start point needs to be inside the perimeter
--and odd
recur(cells[1][1][1])

--Now we are done with the maze algorithm, and have a maze complete
--in memory in the cells table
--We must being building it with our turtle

lightSlot = 1 --inventory slot for lights
ladderSlot = 2 --inventory slot for ladders
lightCount = 0 --how many blocks since we last placed a light?
lightThreshold = 4 --how often to place lights

--For debugging
function printWorldLocation()
	print("World: (" .. curX .. "," .. curY .. "," .. worldZ .. ")")
end

function printMazeLocation()
	print("Maze: (" .. curX .. "," .. curY .. "," .. curZ .. ")")
end

--find a slot with building material in it
function selectBlock()
	for i = 3, 16 do
		if turtle.getItemCount(i) > 0 then
			turtle.select(i)
			return true
		end
	end
	return false
end

--Place a block, first checking inventory
function blockDown()
	checkInventory()
	turtle.select(3)
	if turtle.getItemCount() == 0 then
		selectBlock()
	end
	turtle.placeDown()
end

--light can be anything that will place down on the floors
function placeLight()
	if lightCount > lightThreshold then
		if curZ + 1 < h then
			--we have to much sure this current block has no vertical passage
			--above or below it as torch will interfere with ladder
			if cells[curX][curY][curZ + 1].visited == false then
				if cells[curX][curY][curZ - 1].visited == false then
					turtle.select(lightSlot)
					turtle.placeDown()

					--below is for debugging only
					cells[curX][curY][curZ].light = true

					lightCount = 0
				end
			end
		end
	else
		lightCount = lightCount + 1
	end
end

--We always use these to turn to keep track of rotation
function turnRight()
	turtle.turnRight()
	curRotation = (curRotation + 1) % 4
end

function turnLeft()
	turtle.turnLeft()
	curRotation = (curRotation - 1) % 4
end

--Will orient to the direction specified
function orient(direction)
	while curRotation ~= direction do
		turnRight()
	end
end

--We use this to go forward to keep track of our x/y position
function forward()
	turtle.forward()
	if curRotation == 0 then
		curY = curY + 1
	elseif curRotation == 2 then
		curY = curY - 1
	elseif curRotation == 1 then
		curX = curX + 1
	elseif curRotation == 3 then
		curX = curX - 1
	end
end

--And we use these to go up and down to keep track of our Z position
function up()
	worldZ = worldZ + 1
	turtle.up()
end

function down()
	worldZ = worldZ - 1
	turtle.down()
end

function turnAroundOut()
	--if pointing "north" turn right
	if curRotation == 0 then
		turnRight()
		forward()
		turnRight()
	else
		turnLeft()
		forward()
		turnLeft()
	end
end

--when going back the other way
function turnAroundIn()
	if curRotation == 2 then
		turnRight()
		forward()
		turnRight()
	else
		turnLeft()
		forward()
		turnLeft()
	end
end

--Descends into vertical passages
--places ladders as it comes back up
function placeLadder()
	checkInventory()
	turtle.select(ladderSlot)
	down()
	down()
	turtle.placeDown()
	up()
	turtle.placeDown()
	up()
	turtle.placeDown()
end

function placeFloorLayerOut()
	print("FloorLayerOut")

	if curZ ~= 0 then
		up()
		turnRight()
		turnRight()
	end
	for x = 0, w - 1 do
		for y = 0, d - 1 do
			if cells[curX][curY][curZ].visited == false then
				blockDown()
			end
			if y < d - 1 then
				forward()
			end
		end
		if x < w - 1 then
			turnAroundOut()
		end
	end
end

function placeFloorLayerIn()
	print("FloorLayerIn")
	up()
	if curZ ~= 0 then
		turnRight()
		turnRight()
	end
	for x = w - 1, 0, -1 do
		for y = d - 1, 0, -1 do
			if cells[curX][curY][curZ].visited == false then
				blockDown()
			end
			if y > 0 then
				forward()
			end
		end
		if x > 0 then
			turnAroundIn()
		end
	end
end

function placeWallLayer1In()
	print("wallLayer1In")
	up()
	turnRight()
	turnRight()
	for x = w - 1, 0, -1 do
		for y = d - 1, 0, -1 do
			if cells[curX][curY][curZ].visited then
				placeLight()
			else
				blockDown()
			end
			if y > 0 then
				forward()
			end
		end
		if x > 0 then
			turnAroundIn()
		end
	end
end

function placeWallLayer2Out()
	print("wallLayer2Out")
	up()
	turnRight()
	turnRight()
	for x = 0, w - 1 do
		for y = 0, d - 1 do
			if cells[curX][curY][curZ].visited == false then
				blockDown()
			end
			if y < d - 1 then
				forward()
			end
		end
		if x < w - 1 then
			turnAroundOut()
		end
	end
end

--This could be made more efficient
--Turtle could go directly to each vertical passage
function placeLaddersOut()
	print("placeLaddersOut")
	if curZ == 0 then
		return
	end
	turnRight()
	turnRight()
	for x = 0, w - 1 do
		for y = 0, d - 1 do
			if cells[curX][curY][curZ].visited then
				placeLadder()
			end
			if y < d - 1 then
				forward()
			end
		end
		if x < w - 1 then
			turnAroundOut()
		end
	end
end

--checks if we are running low on blocks, torches, or ladders
function checkInventory()
	--check building blocks
	totalBlocks = 0
	for i = 3, 16 do
		totalBlocks = totalBlocks + turtle.getItemCount(i)
	end

	--check torches
	torchCount = turtle.getItemCount(1)

	--check ladders
	ladderCount = turtle.getItemCount(2)

	if totalBlocks < 5 or torchCount < 5 or ladderCount < 5 then
		returnToOrigin()
		getMoreBlocks()
		resumeBuild()
	end
end

--resume coordinates
resX = 0
resY = 0
resZ = 0
resRotation = 0

--returns to starting chest
function returnToOrigin()
	resX = curX
	resY = curY
	resZ = worldZ
	resRotation = curRotation

	--point south then go past the edge of the maze
	orient(2)
	for i = 0, resY do
		forward()
	end

	--point west then go to point above chest
	orient(3)
	for i = 0, resX - 1 do
		forward()
	end

	--drop down to above the chest
	for i = 0, resZ - 1 do
		down()
	end
end

--fill up on all 3 resources
function getMoreBlocks()
	--get building blocks from 1st chest
	while turtle.suckDown(64) do
	end

	--get torches from 2nd chest which is assumed to be 2 blocks east
	--point east
	orient(1)
	forward()
	forward()
	turtle.select(1)
	turtle.suckDown(64 - turtle.getItemCount()) --just enough to fill upt he stack

	--get ladders from 3rd chest assumed to be 2 more blocks east
	forward()
	forward()
	turtle.select(2)
	turtle.suckDown(64 - turtle.getItemCount()) --just enough

	--point west and go back to above the start chest
	orient(3)
	forward()
	forward()
	forward()
	forward()
end

--return to the position we left off
function resumeBuild()
	--back up
	for i = 0, resZ - 1 do
		up()
	end

	--point east
	orient(1)
	for i = 0, resX - 1 do
		forward()
	end

	orient(0)
	for i = 0, resY do
		forward()
	end
	--resume original rotation
	orient(resRotation)
end

--prints ton of text representing maze state
function fullDebug()
	for z = 0, h - 1 do
		for y = 0, d - 1 do
			for x = 0, w - 1 do
				if cells[x][y][z].light == true and cells[x][y][z].visited == false then
					io.write("(" .. x .. "," .. y .. "," .. z .. "):FF") --if you see this something went wrong
				elseif cells[x][y][z].light then
					io.write("(" .. x .. "," .. y .. "," .. z .. "):**")
				elseif cells[x][y][z].visited == false then
					io.write("(" .. x .. "," .. y .. "," .. z .. "):XX")
				else
					io.write("(" .. x .. "," .. y .. "," .. z .. "):  ")
				end
			end
			io.write("\n")
		end
		io.write("\n")
	end
end

--quick text representation of each layer of the maze
function debug()
	for z = 0, h - 1 do
		for y = 0, d - 1 do
			for x = 0, w - 1 do
				if (cells[x][y][z].light == true) and (cells[x][y][z].visited == false) then
					io.write("FF") --if you see this something went wrong
				elseif cells[x][y][z].light == true then
					io.write("**")
				elseif cells[x][y][z].visited == false then
					io.write("XX")
				else
					io.write("  ")
				end
			end
			io.write("\n")
		end
		io.write("\n")
	end
end

hush = true --silences stub api prints, has no effect in game

turtle.refuel()
turtle.forward() --move off the chest to starting position of maze
placeFloorLayerOut()
curZ = curZ + 1
placeWallLayer1In()
placeWallLayer2Out()
while true do
	print("loopstart")

	curZ = curZ + 1
	placeFloorLayerIn()

	if curZ == h - 1 then
		break
	end

	placeLaddersOut()
	curZ = curZ + 1

	placeWallLayer1In()
	placeWallLayer2Out()

	if turtle.getFuelLevel() == 0 then
		turtle.refuel()
	end
end

returnToOrigin()
