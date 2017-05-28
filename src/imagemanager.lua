
require "tile" -- to make new tiles! duh!
ImageManager = {}

function ImageManager:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function ImageManager:init(args)
	self.tilefiles = args.tilefiles -- a table of tile file bases
	self.client = args.client
	self.tiles = {} -- this is just given straight back to the client

	self:loadFiles()
end

function ImageManager:loadFiles()
	-- as a comment, I may want to add additional things to the begining of files that specify what type of thing they are (building, tile, etc.) in order to
	-- have custom things like "center of building" for buildings and trees
	for _, tilefile in ipairs(self.tilefiles) do
		local image = love.graphics.newImage("images/"..tilefile.."_image.png")
		local loadState = 0
		local sizeOfPalette = 0
		local tileData = {x = 0, y = 0, tilewidth = 0, tileheight = 0, key = "", image = image, colorPalette = colorPalette, nextcolorwidth = 1}
		local loadTable = {
				[0] = {"tilewidth", 1, "number"}, -- starting state => what variable to set, and what state to go into, what type, and whether or not to make a quad
				[1] = {"tileheight", 2, "number"},
				[2] = {"key", -2, "string"},
				[3] = {"nextcolorwidth", 4, "number"},
				[4] = {"x", 5, "number"},
				[5] = {"y", 2, true, "number"}, -- because it has that fourth parameter, create whatever it is and cycle again
				} -- a turing machine esq thing for how to load files
		for line in love.filesystem.lines("images/"..tilefile.."_key.txt") do
			-- load the data about the image.
			if #line > 0 and string.sub(line, 1, 2) ~= "--" then
				-- if loadTable[loadState] then
				-- 	print("load table: "..loadTable[loadState][1])
				-- else
				-- 	print("loadState: "..loadState)
				-- end
				-- print("line: "..line)
				if loadState == -2 then
					-- this should be how many color palettes there are
					sizeOfPalette = tonumber(line)
					-- print("size of: "..sizeOfPalette)
					tileData.colorPalette = {}
					loadState = -1
				elseif loadState == -1 then
					-- it's loading the color palettes
					-- load the color palette, and how much each tile has to move over to the right to get the next section of color
					table.insert(tileData.colorPalette, line)
					if #tileData.colorPalette == sizeOfPalette then
						loadState = 3
					end
				else
					-- use the loading table to load this part
					if loadTable[loadState][3] == "number" then
						tileData[loadTable[loadState][1]] = tonumber(line)
					else
						tileData[loadTable[loadState][1]] = line -- just use the string otherwise
					end
					if loadTable[loadState] and loadTable[loadState][4] then
						-- make the tile
						-- print("\tmade tile: "..tileData.key)
						self.tiles[tileData.key] = Tile:new(tileData) -- pass in the tile data for creating a new tile, then move on
					end
					loadState = loadTable[loadState][2]
				end
			end
		end
	end
end

function ImageManager:getTiles()
	return self.tiles
end