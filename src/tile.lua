-- this is the tile class

Tile = {}

function Tile:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function Tile:init(args)
	-- self.game = args.game
	self.tileData = args
	self.key = args.key
	self.image = args.image
	self.colorPalette = args.colorPalette
	self.tilewidth = args.tilewidth
	self.tileheight = args.tileheight
	-- now make the quad for that image for that set of data, and be happy! lol
	self.quads = {}
	-- print("making tile "..self.key)
	for i = 1, #self.colorPalette do
		-- load the quad for each section of the color palette
		-- print("loading color quad at "..(args.x+(i-1)*args.nextcolorwidth))
		-- print("y: "..args.y)
		self.quads[self.colorPalette[i]] = love.graphics.newQuad((args.x+(i-1)*args.nextcolorwidth)*self.tilewidth,
							args.y*self.tileheight, self.tilewidth, self.tileheight, self.image:getWidth(), self.image:getHeight())
	end
end


function Tile:draw(tileData, camera, colors)
	-- it gets passed in the tile location, and maybe special animation things later, the camera coords, scale, and screenwidth+height, and the
	-- color table that determines what each of these colorPalatte colors are
	local drawX = math.floor((tileData.x - camera.x)*camera.scale+camera.screenWidth/2)
	local drawY = math.floor((tileData.y - camera.y)*camera.scale+camera.screenHeight/2)
	-- local drawR = self.loc.r + self.shipImageRotation - camera.r -- this R currently doesn't work at all...

	for i = 1, #self.colorPalette do
		-- local offset = (i-1)*(self.tileheight*camera.scale)
		if colors[self.colorPalette[i]] then
			love.graphics.setColor(colors[self.colorPalette[i]])
		end
		-- then draw the quad for that color
		love.graphics.draw(self.image, self.quads[self.colorPalette[i]], drawX, drawY, 0, camera.scale, camera.scale, self.tilewidth/2*camera.scale, self.tileheight/2*camera.scale)
	end
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(#tileData.keys, drawX, drawY)
end