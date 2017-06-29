
require "tile" -- to make new tiles! duh!
require "imageData"
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
	-- self.tilefiles = args.tilefiles -- a table of tile file bases
	self.imageKeyFilenames = args.imageKeyFilenames
	self.client = args.client
	-- self.tiles = {} -- this is just given straight back to the client

	self.images = {} -- now we're moving towards images, we should probably have a tile manager as well?

	self:loadImages(self.images, self.imageKeyFilenames)

	-- self:loadFiles()
end

function ImageManager:loadImages(imageTable, imageKeyFilenames, filepath)
	filepath = filepath or "images/"
	-- this is the new version of image handling.
	-- this requires each line be described the line before, since it just makes things easier to read.
	for _, keyFilename in ipairs(imageKeyFilenames) do
		-- What we can also do is have it load what image filename is inside the key file, since why not, right?
		local image = nil
		local loadstate = nil
		local imagename = ""
		local location = {x = -1, y = -1}
		local numberOfColors = 0
		local colorNames = {}
		local colorOffset = {x = 1, y = 0}
		local imageSize = {width = -1, height = -1}
		for line in love.filesystem.lines(filepath..keyFilename) do
			-- Things we need to load:
			-- image filename -- filename
			-- then for each sub-image in the image file, we need:
			-- name of sub image -- key
			-- size of sub image -- imagewidth, imageheight
			-- location, xloc, yloc
			-- number of colors -- numberofcolors then the number
			-- names of colors -- colornames, and then write down each name
			-- offset of colors -- xoffset, yoffset
			if #line > 0 and string.sub(line, 1, 2) ~= "--" then
				if loadstate == nil then
					loadstate = line:lower()
					if loadstate == "done" then
						-- it's done with that one, so make the image and go onto the next
						imageTable[imagename] = ImageData:new{image = image, key = imagename, location = location, colorPalette = colorNames,
									colorOffset = colorOffset, imageSize = imageSize}
						-- table.insert(imageTable, ImageData:new{image = image, key = imagename, location = location, colorPalette = colorNames,
						-- 			colorOffset = colorOffset, imageSize = imageSize})
						loadstate = nil
					end
				elseif loadstate == "colornames" then
					-- then we don't necissarily want to set loadstate to nil after this, so handle this here
					table.insert(colorNames, line)
					if #colorNames >= numberOfColors then
						loadstate = nil
					end
				else
					if loadstate == "filename" then
						image = love.graphics.newImage(filepath..line)
					elseif loadstate == "xloc" then
						location.x = tonumber(line)
					elseif loadstate == "yloc" then
						location.y = tonumber(line)
					elseif loadstate == "xoffset" then
						colorOffset.x = tonumber(line)
					elseif loadstate == "yoffset" then
						colorOffset.y = tonumber(line)
					elseif loadstate == "key" then
						imagename = line
					elseif loadstate == "imagewidth" then
						imageSize.width = tonumber(line)
					elseif loadstate == "imageheight" then
						imageSize.height = tonumber(line)
					elseif loadstate == "numberofcolors" then
						numberOfColors = tonumber(line)
						colorNames = {}
					else
						print("ERROR! Unknown load state: "..tostring(loadstate))
					end
					loadstate = nil
				end
			end
		end
	end
end

-- function ImageManager:loadFiles()
-- 	-- as a comment, I may want to add additional things to the begining of files that specify what type of thing they are (building, tile, etc.) in order to
-- 	-- have custom things like "center of building" for buildings and trees
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

function ImageManager:getImages()
	return self.images
end