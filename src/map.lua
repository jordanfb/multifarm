

--[[
This is a map class that will be given the changes to the world based on tiles, and update them. This also handles setting up the images to be drawn for performance reasons.
Thus, this is given the camera for update and for draw, and just draws everything it needs, possibly including handling animations.
This may also be given to the server class, so it will handle updating things growing as well, as long as it's given permission to do so.

If it's given to the server though then I want to keep all of the graphics separate. Hmmm.

]]--

Map = {}

function Map:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function Map:init(args)
	-- self.tilefiles = args.tilefiles -- a table of tile file bases
	self.client = args.client
	self.chunkSize = args.chunkSize or 16 -- the size length of a chunk in tiles
	self.waterLevel = args.waterLevel or .25
	self.isServer = args.isServer or false -- if it is, then we need to keep track of all of the changes so we know what to send to people, and we need to generate and send entities,
	self.tileSize = args.tileSize or 128 -- used for converting world pos into chunk coords. Normally integers are tiles, but when converting more things it's helpful to actually have things
	self.world = {chunks = {}, seed = args.seed or love.math.random()*1000} -- chunk y then chunk x are the keys in chunks, and then it goes into more stuff like tiles and entities
end

function Map:standardizeCoords(xloc, yloc)
	if yloc == nil then
		return xloc
	end
	return {x = xloc, y = yloc}
end

function Map:generateChunk(chunkCoords)
	-- do your magic and generate literally everything that we need including animals and plants and tiles. Yeah, just do it!
	-- We'll probably just have animals appear where they first spawn unless it's a client based thing, in which case they'll already have been moved, in which case the server will have to send updates, or not have been moved?
	-- Maybe it'll just send a list of entities per chunk upon loading it, since they change so much more.
	if not self.world.chunks[chunkCoords.y] then
		self.world.chunks[chunkCoords.y] = {}
	end
	if not self.world.chunks[chunkCoords.y][chunkCoords.x] then
		self.world.chunks[chunkCoords.y][chunkCoords.x] = {tiles = {}, entities = {}, coords = chunkCoords, drawDirtyFlag = true} -- draw dirty flag is only set to true when it's used by a drawable map, otherwise ignore
	end
	self:generateChunkTiles(chunkCoords, self.world.chunks[chunkCoords.y][chunkCoords.x])
	if self.isServer then
		-- then it has the authority on generating entites, so it should go ahead and do that
	end
end

function Map:generateChunkTiles(chunkCoords, chunkTable)
	for dy = 0, self.chunkSize-1 do
		local y = chunkCoords.y+dy
		chunkTable.tiles[y] = {}
		for dx = 0, self.chunkSize-1 do
			local x = chunkCoords.x+dx
			local gx = x / self.chunkSize -- gx and gy are used for generating the noise
			local gy = y / self.chunkSize
			chunkTable.tiles[y][x] = {base = {}, top = {}} -- the tile table
			local tileValue = love.math.noise(gx, gy, self.world.seed) + (love.math.noise(2*gx, 2*gy, self.world.seed) - .5) + .25*(love.math.noise(4*gx, 4*gy, self.world.seed) - .5)
			-- if tileValue < 0 then -- this does happen, so I should handle it.
			-- 	print("<0")
			-- elseif tileValue > 1 then
			-- 	print(">1")
			-- end
			if tileValue <= self.waterLevel then
				-- it's water
				table.insert(chunkTable.tiles[y][x].base, "tile~")
			else
				-- it's grass
				table.insert(chunkTable.tiles[y][x].base, "tile#")
			end
		end
	end
end

function Map:chunkExists(chunkCoords)
	-- returns whether the chunk has been generated (i.e. if there's a table under the chunk coordinates)
	return self.world.chunks[chunkCoords.y] and self.world.chunks[chunkCoords.y][chunkCoords.x]
end

function Map:getTileChunkCoords(loc)
	local t = {x = math.floor(loc.x/self.chunkSize)*self.chunkSize, y = math.floor(loc.y/self.chunkSize)*self.chunkSize}
	-- print(t.x .. ", "..t.y)
	return t
end

function Map:getChunkCoords(loc)
	-- this one is for entities to chunks, because it accounts for the tile size
	local t = {x = math.floor(loc.x/self.chunkSize/self.tileSize)*self.chunkSize, y = math.floor(loc.y/self.chunkSize/self.tileSize)*self.chunkSize}
	-- print(t.x .. ", "..t.y)
	return t
end

function Map:setEntity(newEntity)
	-- this is for making things like trees, buildings, or plants, which probably need updating. Somehow there will also be animals here...
	-- trees and plants will have a type, a seed, and a plant time, and from that the game should be able to figure out their current state given the current time.
	-- how are animals and other players going to be handled? They may need interpolation stuff, which could be an issue.
	-- I'm assuming the entity has a .loc, which is going to be used for determining what chunk to put it in.
	local loc = newEntity.loc
	local chunkCoords = self:getChunkCoords(loc)
	if not self:chunkExists(chunkCoords) then
		self:generateChunk(chunkCoords)
	end
	-- then do the stuff with putting the entity somewhere.
	table.insert(self.world.chunks[chunkCoords.y][chunkCoords.x].entities, newEntity)
end

function Map:setTile(x, y, newTile)
	-- This should just set basic tile type, like grass, water, hoed earth, and the map should figure out the specific version of it and of the surrounding tiles that are updated.
	local loc = self:standardizeCoords(x, y)
	local chunkCoords = self:getTileChunkCoords(loc)
	if not self:chunkExists(chunkCoords) then
		-- then the chunk isn't generated, so make it.
		self:generateChunk(chunkCoords)
	end
	self.world.chunks[chunkCoords.y][chunkCoords.x].tiles[loc.y][loc.x] = newTile
	self.world.chunks[chunkCoords.y][chunkCoords.x].drawDirtyFlag = true
end

function Map:getTile(x, y)
	local loc = self:standardizeCoords(x, y)
	local chunkCoords = self:getTileChunkCoords(loc)
	if not self:chunkExists(chunkCoords) then
		-- then the chunk isn't generated, so make it.
		self:generateChunk(chunkCoords)
	end
	return self.world.chunks[chunkCoords.y][chunkCoords.x].tiles[loc.y][loc.x]
end

function Map:generateChunksForPlayer(x, y, sidelengthOfChunksGenerated)
	-- ensures that the chunks at the location are generated, and generates them if they aren't.
	local loc = self:standardizeCoords(x, y)
	local centerChunk = self:getChunkCoords(loc)
	local chunksGenerated = false
	sidelengthOfChunksGenerated = sidelengthOfChunksGenerated or 3
	local offset = sidelengthOfChunksGenerated + 1
	offset = -math.floor(offset/2)
	for fdy = 1, sidelengthOfChunksGenerated do
		for fdx = 1, sidelengthOfChunksGenerated do
			local dx = fdx + offset
			local dy = fdy + offset
			if not self:chunkExists{x = centerChunk.x + dx*self.chunkSize, y = centerChunk.y + dy*self.chunkSize} then
				self:generateChunk{x = centerChunk.x + dx*self.chunkSize, y = centerChunk.y + dy*self.chunkSize}
				chunksGenerated = true
			end
		end
	end
	-- print(chunksGenerated)
	return chunksGenerated
end

function Map:update(dt)
	-- what does update do? Maybe it updates entities for the server?
end


--[[
MapDrawable is what keeps track of all the things to draw and gets drawn. This is separate, but closely intertwined with the map class.
The MapDrawable creates a map object, and forwards most if not all of its functions to the Map object, but it also keeps track of what to draw, etc.
The client will create a MapDrawable, but the server only needs a Map.
]]--

MapDrawable = {}

function MapDrawable:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function MapDrawable:init(args)
	-- self.tilefiles = args.tilefiles -- a table of tile file bases
	self.client = args.client
	self.camera = args.camera -- this can also be set later with MapDrawable:setCamera(camera)
	self.chunkSize = args.chunkSize or 16
	self.tileSize = args.tileSize or 128 -- in pixels, for determining the size of the canvases to keep.
	self.canvasArraySize = args.canvasArraySize or 5 -- this is the length of one side of the array, so 9 total by default
	self.isServer = args.isServer or false
	self.map = Map:new{client = args.client, chunkSize = self.chunkSize, waterLevel = args.waterLevel, isServer = self.isServer, tileSize = self.tileSize}
	self.images = args.images
	self.colorScheme = args.colorScheme -- this really kinda needs to be passed in...

	self:createCanvasArray()
	self.oldCameraChunkCoords = {x = 0, y = 0}
	
	self:update(0) -- draw the required nearby images
end

function MapDrawable:createCanvasArray()
	self.canvasArray = {}
	self.canvasArrayKey = {}
	for y = 1, self.canvasArraySize do
		self.canvasArray[y] = {}
		for x = 1, self.canvasArraySize do
			table.insert(self.canvasArray[y], {chunkX = 0, chunkY = 0, canvas = love.graphics.newCanvas(self.chunkSize*self.tileSize, self.chunkSize*self.tileSize)})
		end
	end
end

function MapDrawable:setCamera(camera)
	self.camera = camera
	self:update(0) -- make sure that it's focused on the new camera and re-generate surrounding images if needed.
end

function MapDrawable:draw()
	self:drawCanvasesToScreen()
end

function MapDrawable:drawCanvasesToScreen()
	-- for i = 1, self.canvasArraySize do
	-- local i = 1
	love.graphics.setColor({255, 255, 255})
	for y = 1, self.canvasArraySize do
		for x = 1, self.canvasArraySize do
			local canvasTable = self.canvasArray[y][x]
			local drawX = math.floor((canvasTable.chunkX*self.tileSize - self.camera.x)*self.camera.scale+self.camera.screenWidth/2)
			local drawY = math.floor((canvasTable.chunkY*self.tileSize - self.camera.y)*self.camera.scale+self.camera.screenHeight/2)
			-- if love.keyboard.isDown(tostring(i)) then
			love.graphics.draw(canvasTable.canvas, drawX, drawY, 0, self.camera.scale, self.camera.scale)--, self.tileSize/2, self.tileSize/2)
			-- end
			-- i = i + 1
		end
	end
end

function MapDrawable:drawChunkToCanvas(chunkCoords, canvasTable)
	-- this looks up the chunk, and if it exists, it draws it to the canvas
	if not self.map:chunkExists(chunkCoords) then
		error("chunk doesn't exist when it should")
		return false -- note this should never occur, since it pretty much will always have updated before changing what it draws, and update should create the chunk.
	end
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("fill", 0, 0, 100, 100)
	-- we know it exists now, so we draw it to the canvas.
	local x = -1
	local y = -1
	local tileData = -1
	local chunkTable = self.map.world.chunks[chunkCoords.y][chunkCoords.x] -- .tiles[y][x].base
	canvasTable.chunkX = chunkCoords.x
	canvasTable.chunkY = chunkCoords.y
	love.graphics.setCanvas(canvasTable.canvas)
	for dy = 0, self.chunkSize-1 do
		y = chunkCoords.y + dy
		for dx = 0, self.chunkSize-1 do
			x = chunkCoords.x + dx
			tileData = chunkTable.tiles[y][x]
			for i, image in ipairs(tileData.base) do
				self.images[image]:drawAll({x = dx*self.tileSize, y = dy*self.tileSize}, {x = 0, y = 0, scale = 1, screenWidth = 0, screenHeight = 0}, self.colorScheme)
			end
		end
	end
	love.graphics.setCanvas()
end

function MapDrawable:updateCanvasArray(forceDraw)
	forceDraw = forceDraw or false -- only use this if you moved chunks for instance
	local chunkCoords = self.map:getChunkCoords(self.map:standardizeCoords(self.camera.x, self.camera.y))
	local offset = -math.floor((self.canvasArraySize+1)/2)
	for fdy = 1, self.canvasArraySize do
		for fdx = 1, self.canvasArraySize do
			local dx = fdx + offset
			local dy = fdy + offset
			if forceDraw or self.map.world.chunks[chunkCoords.y + dy * self.chunkSize][chunkCoords.x + dx * self.chunkSize].drawDirtyFlag then
				self:drawChunkToCanvas({x = chunkCoords.x + dx * self.chunkSize, y = chunkCoords.y + dy * self.chunkSize}, self.canvasArray[fdy][fdx])
				self.map.world.chunks[chunkCoords.y + dy * self.chunkSize][chunkCoords.x + dx * self.chunkSize].drawDirtyFlag = false
			end
		end
	end
end

function MapDrawable:trySwappingCanvases(oldChunkCoords, newChunkCoords)
	-- this tries to keep performance up by only re-drawing the chunks that we need to, i.e. the ones that we forgot about, and just swapping the other tiles around
	local dy = (newChunkCoords.y - oldChunkCoords.y)/self.chunkSize
	local dx = (newChunkCoords.x - oldChunkCoords.x)/self.chunkSize
	-- otherwise swap only the ones that matter
	-- local tempCanvasList = {}
	if math.abs(dy) + math.abs(dx) > 1 then
		print("why? "..dx..", "..dy)
		return false -- I don't want to deal with moving both at once.
	elseif math.abs(dy) == 1 then
		print("swapping y")
		if dy == -1 then
			for y = self.canvasArraySize, 2, -1 do
				-- swap each row with the one above it.
				local temp = self.map.world.chunks[y]
				self.map.world.chunks[y] = self.map.world.chunks[y-1]
				self.map.world.chunks[y-1] = temp
			end
			local y = newChunkCoords.y - math.floor((self.canvasArraySize+1)/2-1)*self.chunkSize -- this is the newest row that needs to be drawn
			print( math.floor((self.canvasArraySize+1)/2))
			local x = newChunkCoords.x - math.floor((self.canvasArraySize+1)/2)*self.chunkSize
			for dx = 0, self.canvasArraySize-1 do
				if self.map:chunkExists{x = x+dx*self.chunkSize, y = y} then
					self.map.world.chunks[y][x+dx*self.chunkSize].drawDirtyFlag = true
				else
					print("does't ed  "..x.." <- the base "..x+dx*self.chunkSize..", "..y)
				end
			end
		else
			for y = 1, self.canvasArraySize-1 do
				-- swap each row with the one below it.
				local temp = self.map.world.chunks[y]
				self.map.world.chunks[y] = self.map.world.chunks[y+1]
				self.map.world.chunks[y+1] = temp
			end
			local y = newChunkCoords.y - math.floor((self.canvasArraySize+1)/2)*self.chunkSize -- this is the newest row that needs to be drawn
			for x = 0, self.canvasArraySize-1 do
				if self.map:chunkExists{x = x*self.chunkSize, y = y} then
					self.map.world.chunks[y][x*self.chunkSize].drawDirtyFlag = true
				else
					print("doksjlskj "..x..", "..y)
				end
			end
		end
		return true
	elseif math.abs(dx) == 1 then
		print("trying x swap")
		return false
	end
end

function MapDrawable:update(dt)
	self.map:update(dt)
	-- check to see if all of the chunks the camera is looking at are generated and if we need to draw new ones.
	self.map:generateChunksForPlayer(self.camera.x, self.camera.y, self.canvasArraySize) -- now we know that the three chunks centered around that are existant.
	-- now we check to see that we can draw each of the important chunks!
	local forceDraw = false
	local chunkCoords = self.map:getChunkCoords(self.map:standardizeCoords(self.camera.x, self.camera.y))
	if self.oldCameraChunkCoords.x ~= chunkCoords.x or self.oldCameraChunkCoords.y ~= chunkCoords.y then
		-- so now we try to handle it nicely by swapping chunks around rather than re-drawing each and every one of them, but it may not be possible. But we try.
		-- forceDraw = not self:trySwappingCanvases(self.oldCameraChunkCoords, chunkCoords) -- if it can't handle it, we force a re-draw.
		self.oldCameraChunkCoords = chunkCoords
		forceDraw = true --forceDraw or love.keyboard.isDown("f")
	end
	self:updateCanvasArray(forceDraw)
end

function MapDrawable:setTile(x, y, newTile)
	self.map:setTile(x, y, newTile)
end

function MapDrawable:getTile(x, y)
	return self.map:getTile(x, y)
end

function MapDrawable:setEntity(newEntity)
	self.map:setEntity(newEntity)
end

function MapDrawable:convertScreenToTileCoords(x, y)
	local loc = self.map:standardizeCoords(x, y)
	-- now figure it out, Alexander!
	local tileX = (loc.x - self.camera.screenWidth/2)/self.camera.scale + self.camera.x
	local tileY = (loc.y - self.camera.screenHeight/2)/self.camera.scale + self.camera.y
	tileX = tileX -- / self.camera.scale
	tileY = tileY -- / self.camera.scale
	tileX = tileX / 128
	tileY = tileY / 128
	return {x = math.floor(tileX), y = math.floor(tileY), xfloat = tileX, yfloat = tileY} -- I could put this through the map class, but I may want x and y floats at some point??? Maybe?
end

function MapDrawable:testMouse()
	-- print("test function called")
	local loc = self:convertScreenToTileCoords(love.mouse.getX(), love.mouse.getY())
	-- print(loc.x .. ", "..loc.y)
	local tileTable = self:getTile(loc)
	if tileTable.base[#tileTable.base] == "tile~" then
		-- tileTable.base[#tileTable.base] = "tile#"
		self:setTile(loc.x, loc.y, {base = {"tile#"}, top = {}})
	else
		-- tileTable.base[#tileTable.base] = "tile~"
		self:setTile(loc.x, loc.y, {base = {"tile~"}, top = {}})
	end
end