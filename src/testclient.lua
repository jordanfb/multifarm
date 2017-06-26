
require "imagemanager"
require "player"

TestClient = {}

function TestClient:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args then
		object:init(args)
	end
	return object
end

function TestClient:init(args)
	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.game = args.game

	self.imageManager = ImageManager:new{tilefiles = {"basicland", "farmhouse", "spacemanLarge"}, client = self}

	self.tiles = self.imageManager:getTiles() -- list of tile key to tile class. Tile class has images, quads, and magic.

	self.camera = {x = 128*32, y = 128*32, scale = .5, screenWidth = love.graphics.getWidth(), screenHeight = love.graphics.getHeight()}

	self.colorScheme = {grass = {163, 206, 39, 255}, grasshighlight = {68, 137, 26, 255}, sand = {246, 226, 107, 255},
						water = {49, 162, 242, 255}, waterhighlight = {0, 87, 132, 255},
						ice = {178, 220, 239, 255}, icehighlight = {49, 162, 242, 255},
						white = {255, 255, 255, 255}, lights = {246, 128, 17, 255}
					}

	self.tilewidth = 128
	self.tileheight = 128
	self.chunkSize = 64
	self:loadTestWorld()

	self.testPlayer = Player:new{client = self, tiles = self.tiles}
	self.camera.x = self.testPlayer.x
	self.camera.y = self.testPlayer.y
end

function TestClient:testLoadChunk(args)
	-- x, y, idk what else.
	local basex = args.x*self.chunkSize*self.tilewidth -- pass in the chunk coords, not the world coords
	local basey = args.y*self.chunkSize*self.tileheight
	local worldSeed = args.worldSeed
	local chunk = {} -- a table of [y][x] = tileData
	local hasWater = false

	for dy = 0, self.chunkSize-1 do
		chunk[dy] = {}
		for dx = 0, self.chunkSize-1 do
			local keys, isWater = self:testGetTileType(basex+dx, basey+dy, worldSeed)
			chunk[dy][dx] = {x = self.tilewidth*(dx+basex), y = self.tileheight*(dy+basey),
							keys = keys}
			hasWater = hasWater or isWater
		end
	end
	return chunk, hasWater
end

function TestClient:testGetTileType(inx, iny, worldSeed)
	local waterLevel = .3
	local surroundingsTable = {}
	local tileString = ""
	local scaleThing = 53
	local isWater = false
	for dy = -1, 1 do
		for dx = -1, 1 do
			-- print(worldSeed .. ", "..(x+dx)/scaleThing..", "..(y+dy)/scaleThing)
			-- print(love.math.noise(x+dx, y+dy, worldSeed))
			local x = self.world.xOffset+(inx + dx) % self.chunkSize / self.chunkSize
			local y = self.world.yOffset+(iny + dy) % self.chunkSize / self.chunkSize
			local tileValue = love.math.noise(x, y, worldSeed) + (love.math.noise(2*x, 2*y, worldSeed) - .5) + .25*(love.math.noise(4*x, 4*y, worldSeed) - .5)
			tileValue = math.min(math.max(tileValue, 0), 1)
			if tileValue <= waterLevel then
				isWater = true -- this is used to make sure there's water on the map
			end
			-- if love.math.noise(x, y, worldSeed/10000000000) < .5 then
				-- print(false)
			-- end
			-- print(love.math.noise(x, y, worldSeed/10000000000))
			table.insert(surroundingsTable, (tileValue > waterLevel))
			if surroundingsTable[#surroundingsTable] then
				tileString = tileString .. "l"
			else
				tileString = tileString .. "w"
			end
		end
	end
	local conversonTable = {"]", "8", "[", "4", "#", "6", "}", "2", "{"} 
	local edgeTable = {}
	for i = 1, 9 do
		if surroundingsTable[i] then
			table.insert(edgeTable, conversonTable[i])
		end
	end
	if surroundingsTable[5] then
		edgeTable = {"#"} -- the full grass block.
	else
		local cornerWallReplaceTable = {[{"}", "2"}]="2", [{"{", "2"}]="2",
									[{"}", "4"}]="4", [{"{", "4"}]="4",
									[{"[", "6"}]="6", [{"]", "6"}]="6",
									[{"]", "8"}]="8", [{"[", "8"}]="8"}
		self:replaceStuff(cornerWallReplaceTable, edgeTable)
		-- local fourWallReplacementTable = {[{"2", "4", "6", "8"}]="#"}
		-- self:replaceStuff(fourWallReplacementTable, edgeTable)
		-- local threeWallReplacementTable = {[{"2", "4", "6"}]="n", [{"8", "4", "6"}]="u", [{"2", "4", "8"}]="<", [{"2", "6", "8"}]=">"}
		-- self:replaceStuff(threeWallReplacementTable, edgeTable)
		local twoWallReplacementTable = {[{"2", "4"}]="1", [{"2", "6"}]="3", [{"4", "8"}]="7", [{"6", "8"}]="9"}--, [{"6", "4"}]="|", [{"2", "8"}]="="}
		self:replaceStuff(twoWallReplacementTable, edgeTable)
		table.insert(edgeTable, 1, "~")
	end
	return edgeTable, isWater
end

function TestClient:inTable(item, t)
	for i = 1, #t do
		if t[i] == item then
			return true, i
		end
	end
	return false, -1
end

function TestClient:replaceStuff(replacementGuide, replaceThisTable)
	for k, v in pairs(replacementGuide) do
		local removeTable = {}
		for i, checkIn in ipairs(k) do
			local isIn, index = self:inTable(checkIn, replaceThisTable)
			if isIn then
				removeTable[#removeTable+1] = index
			end
		end
		if #removeTable == #k then
			for i, checkIn in ipairs(k) do
				local isIn, index = self:inTable(checkIn, replaceThisTable)
				table.remove(replaceThisTable, index)
			end
			-- for i, removeIndex in ipairs(removeTable) do
			-- 	table.remove(replaceThisTable, removeIndex)
			-- end
			replaceThisTable[#replaceThisTable+1] = v
		end
	end
end

function TestClient:loadTestWorld()
	self.world = {seed = -1, chunks = {}, chunkCanvases = {}, players = {}, animals = {}} -- chunks is a set of chunks, makes sense.
	self.world.seed = love.math.random()*1000
	self.world.xOffset = love.math.random()*1000
	self.world.yOffset = love.math.random()*1000
	-- for y = -1, 1 do
	-- 	if self.world.chunks[y] == nil then
	-- 		self.world.chunks[y] = {}
	-- 	end
	-- 	for x = -1, 1 do
	-- 		self.world.chunks[y][x] = self:testLoadChunk{x = x, y = y, worldSeed = self.world.seed}
	-- 	end
	-- end
	local hasWater = false
	while not hasWater do
		self.world.chunks[0] = {}
		self.world.chunks[0][0], hasWater = self:testLoadChunk{x = 0, y = 0, worldSeed = self.world.seed}
		if not hasWater then
			self.world.seed = love.math.random()*1000
		end
	end
	self.world.chunkCanvases[0] = {}
	self.world.chunkCanvases[0][0] = love.graphics.newCanvas(self.tilewidth*self.chunkSize, self.tileheight*self.chunkSize)
	self:drawChunkOntoCanvas(0, 0, self.world.chunkCanvases[0][0])
end

function TestClient:load()
	-- run when the level is given control
end

function TestClient:leave()
	-- run when the level no longer has control
end

function TestClient:testTileDraw()
	local i = 0
	for k, v in pairs(self.tiles) do
		v:draw({x = i*128*1.5, y = 0}, self.camera, self.colorScheme)
		-- print(k)
		i = i + 1
	end
end

function TestClient:drawChunkOntoCanvas(chunkx, chunky, canvas)
	local tempCamera = {x = chunkx*self.tilewidth*self.chunkSize, y = chunky*self.tileheight*self.chunkSize,
					scale = 1, screenWidth = 0, screenHeight = 0}
	love.graphics.setCanvas(canvas)
	self:drawChunkRaw(chunkx, chunky, tempCamera)
	love.graphics.setCanvas()
end

function TestClient:drawChunkRaw(chunkx, chunky, camera)
	for y = 0, self.chunkSize-1 do
		for x = 0, self.chunkSize-1 do
			for _, tileType in ipairs(self.world.chunks[chunky][chunkx][y][x].keys) do
				-- print(tileType)
				self.tiles[tileType]:draw(self.world.chunks[chunky][chunkx][y][x], camera, self.colorScheme)
			end
		end
	end
end

function TestClient:drawChunk(chunkx, chunky, camera)
	-- check if the chunk image exists, if it doesn't, then draw chunk raw? or perhaps use an object pool for nearby chunks.
	local drawX = math.floor((chunkx*self.chunkSize*self.tilewidth - camera.x)*camera.scale+camera.screenWidth/2)
	local drawY = math.floor((chunky*self.chunkSize*self.tileheight - camera.y)*camera.scale+camera.screenHeight/2)

	if self.world.chunkCanvases[chunky][chunkx] then
		-- the canvas exists, draw it to screen
		love.graphics.draw(self.world.chunkCanvases[chunky][chunkx], drawX, drawY, 0, camera.scale, camera.scale, self.tilewidth/2, self.tileheight/2)
	else
		self:drawChunkRaw(chunkx, chunky, camera)
		-- love.graphics.setColor(255, 0, 0)
		-- love.graphics.draw(self.world.chunkCanvases[chunky][chunkx], drawX, drawY, 0, camera.scale, camera.scale)--, self.tilewidth/2, self.tileheight/2)
	end
end

function TestClient:draw()
	-- self:testTileDraw()
	self:drawChunk(0, 0, self.camera)
	self.tiles.farmhouse:draw({x = 0, y = 0, keys = {"farmhouse"}}, self.camera, self.colorScheme)
	self.testPlayer:draw(self.camera)
end

function TestClient:update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
	if love.keyboard.isDown("down") then
		self.camera.y = self.camera.y + 250*dt
	end
	if love.keyboard.isDown("up") then
		self.camera.y = self.camera.y - 250*dt
	end
	if love.keyboard.isDown("right") then
		self.camera.x = self.camera.x + 250*dt
	end
	if love.keyboard.isDown("left") then
		self.camera.x = self.camera.x - 250*dt
	end
	if love.keyboard.isDown("return") then
		self:loadTestWorld()
	end

	self.testPlayer:update(dt)
	self.camera.x = self.testPlayer.x
	self.camera.y = self.testPlayer.y
end

function TestClient:resize(w, h)
	--
end

function TestClient:handleinput(input)
	if input[2] == 1 then
		-- pressed
		if input[1] == "zoomin" then
			self.camera.scale = self.camera.scale*2
		elseif input[1] == "zoomout" then
			self.camera.scale = self.camera.scale/2
		end
	elseif input[2] == 0 then
		-- released
	end
	self.testPlayer:handleinput(input)
end