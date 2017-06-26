-- this is a Player class, it loads on world generation or something, and it contains the interior that can be drawn. Probably.


Player = {}

function Player:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function Player:init(args)
	-- self.tilefiles = args.tilefiles -- a table of tile file bases
	self.client = args.client

	-- self:loadFiles()

	-- self.game = args.game
	self.colorScheme = args.colorScheme or {bodyColor = {128, 255, 128}, helmetColor = {128, 128, 255}}
	self.tile = args.tiles["spaceman"]

	self.x = args.x or 0
	self.y = args.y or 0
	self.dx = args.dx or 0
	self.dy = args.dy or 0
	-- self.ax = 0
	-- self.ay = 0
	self.f = args.f or 2 -- 0 is north? 3 is west.
	self.speed = args.speed or 128*2
	-- self.acceleration = 1000 -- top speed in a tenth of a second
	self.inputTable = {moveleft = 0, moveright = 0, moveup = 0, movedown = 0}
end

function Player:handleinputlist(lst)
	-- this is for re-doing things after the server confirms it, just pass in a table of times and things? Then it handles the input and then updates the time, and continues
	for _, v in ipairs(lst) do
		-- I'm currently assuming that it's {input, dt until next input}
		self:handleInput(v[1])
		self:update(v[2])
	end
end

function Player:handleinput(input)
	-- {input name, input value}
	local inputname = input[1]
	local inputvalue = input[2]
	-- local inputManagerTable = {moveleft = {"dx", -1}, moveright = {"dx", 1}, moveup = {"dy", -1}, movedown = {"dy", 1}}
	-- if inputvalue > 0 then
	-- 	-- it's a press
	-- 	self[inputManagerTable[inputname][1]] = inputManagerTable[inputname][2] * inputvalue
	-- end
	if self.inputTable[inputname] then
		self.inputTable[inputname] = inputvalue
	end
end

function Player:update(dt)
	self.dx = self.inputTable.moveright - self.inputTable.moveleft
	self.dy = self.inputTable.movedown - self.inputTable.moveup
	self.x = self.x + self.dx*self.speed*dt
	self.y = self.y + self.dy*self.speed*dt -- also should handle collisions...
end

function Player:draw(camera)
	self.tile:draw({x = self.x, y = self.y, keys = {"spaceman"}}, camera, self.colorScheme)
end

-- function Player:loadFiles()
-- 	-- as a comment, I may want to add additional things to the begining of files that specify what type of thing they are (Player, tile, etc.) in order to
-- 	-- have custom things like "center of Player" for Players and trees
-- 	for _, tilefile in ipairs(self.tilefiles) do
-- 		local image = love.graphics.newImage("images/"..tilefile.."_image.png")
-- 		local loadState = 0
-- 		local sizeOfPalette = 0
-- 		local tileData = {x = 0, y = 0, tilewidth = 0, tileheight = 0, key = "", image = image, colorPalette = colorPalette, nextcolorwidth = 1}
-- 		local loadTable = {
-- 				[0] = {"tilewidth", 1, "number"}, -- starting state => what variable to set, and what state to go into, what type, and whether or not to make a quad
-- 				[1] = {"tileheight", 2, "number"},
-- 				[2] = {"key", -2, "string"},
-- 				[3] = {"nextcolorwidth", 4, "number"},
-- 				[4] = {"x", 5, "number"},
-- 				[5] = {"y", 2, true, "number"}, -- because it has that fourth parameter, create whatever it is and cycle again
-- 				} -- a turing machine esq thing for how to load files
-- 		for line in love.filesystem.lines("images/"..tilefile.."_key.txt") do
-- 			-- load the data about the image.
-- 			if #line > 0 and string.sub(line, 1, 2) ~= "--" then
-- 				-- if loadTable[loadState] then
-- 				-- 	print("load table: "..loadTable[loadState][1])
-- 				-- else
-- 				-- 	print("loadState: "..loadState)
-- 				-- end
-- 				-- print("line: "..line)
-- 				if loadState == -2 then
-- 					-- this should be how many color palettes there are
-- 					sizeOfPalette = tonumber(line)
-- 					-- print("size of: "..sizeOfPalette)
-- 					tileData.colorPalette = {}
-- 					loadState = -1
-- 				elseif loadState == -1 then
-- 					-- it's loading the color palettes
-- 					-- load the color palette, and how much each tile has to move over to the right to get the next section of color
-- 					table.insert(tileData.colorPalette, line)
-- 					if #tileData.colorPalette == sizeOfPalette then
-- 						loadState = 3
-- 					end
-- 				else
-- 					-- use the loading table to load this part
-- 					if loadTable[loadState][3] == "number" then
-- 						tileData[loadTable[loadState][1]] = tonumber(line)
-- 					else
-- 						tileData[loadTable[loadState][1]] = line -- just use the string otherwise
-- 					end
-- 					if loadTable[loadState] and loadTable[loadState][4] then
-- 						-- make the tile
-- 						-- print("\tmade tile: "..tileData.key)
-- 						self.tiles[tileData.key] = Tile:new(tileData) -- pass in the tile data for creating a new tile, then move on
-- 					end
-- 					loadState = loadTable[loadState][2]
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- function Player:getTiles()
-- 	return self.tiles
-- end