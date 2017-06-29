--[[
Image data class, used in anything which needs to be displayed.
Images are all split into colors at the moment, except for things which aren't. Cause yeah.
But there can also be single things
and there can also be strange shaped images.
Yeah.
]]--



-- this is the tile class

ImageData = {}

function ImageData:new(args)
	local object = {}
	setmetatable(object, self)
	self.__index = self
	if args ~= nil then
		object:init(args)
	end
	return object
end

function ImageData:init(args)
	-- self.game = args.game
	self.args = args
	self.key = args.key
	self.image = args.image
	self.colorPalette = args.colorPalette
	self.imagewidth = args.imageSize.width
	self.imageheight = args.imageSize.height

	-- location
	local x = args.location.x
	local y = args.location.y

	-- now make the quad for that image for that set of data, and be happy! lol
	self.quads = {}
	-- print("making tile "..self.key)
	for i = 1, #self.colorPalette do
		-- load the quad for each section of the color palette
		-- print("loading color quad at "..(args.x+(i-1)*args.nextcolorwidth))
		-- print("y: "..args.y)
		self.quads[self.colorPalette[i]] = love.graphics.newQuad((x+(i-1)*args.colorOffset.x)*self.imagewidth,
							y*self.imageheight, self.imagewidth, self.imageheight, self.image:getWidth(), self.image:getHeight())
	end
end

function ImageData:draw(locData, camera, colors)
	self:drawAll(locData, camera, colors)
end

function ImageData:drawAll(locData, camera, colors)
	-- draws each color in the order of colorPalette, useful for tiles, etc.
	for i = 1, #self.colorPalette do
		self:drawLayer(self.colorPalette[i], locData, camera, colors)
	end
end

function ImageData:drawLayer(layer, locData, camera, colors)
	-- it gets passed in the tile location, and maybe special animation things later, the camera coords, scale, and screenwidth+height, and the
	-- color table that determines what each of these colorPalatte colors are
	local drawX = math.floor((locData.x - camera.x)*camera.scale+camera.screenWidth/2)
	local drawY = math.floor((locData.y - camera.y)*camera.scale+camera.screenHeight/2)
	-- local drawR = self.loc.r + self.shipImageRotation - camera.r -- this R currently doesn't work at all...
	
	-- replacing this with drawing "loaded" chunk images and then using those, even with animations it should be better as long as they are in sync.
	-- -- check if it's outside the draw area:
	-- if drawX < 0 or drawX > camera.screenWidth or drawY < 0 or drawY > camera.screenHeight then
	-- 	return
	-- end

	if colors[layer] then
		love.graphics.setColor(colors[layer])
	else
		error("Color "..layer.." doesn't exist for drawing, so errored")
	end
	love.graphics.draw(self.image, self.quads[layer], drawX, drawY, 0, camera.scale, camera.scale, self.imagewidth/2, self.imageheight/2)

	-- for i = 1, #self.colorPalette do
	-- 	-- local offset = (i-1)*(self.imageheight*camera.scale)
	-- 	if colors[self.colorPalette[i]] then
	-- 		love.graphics.setColor(colors[self.colorPalette[i]])
	-- 	end
	-- 	-- then draw the quad for that color
	-- 	love.graphics.draw(self.image, self.quads[self.colorPalette[i]], drawX, drawY, 0, camera.scale, camera.scale)--, self.imagewidth/2, self.imageheight/2)
	-- end
	-- love.graphics.setColor(0, 0, 0)
	-- -- love.graphics.print(#tileData.keys, drawX, drawY)
end

--[[
This should probably be changed to support animations and buildings better
We have:
images with different colors per layer -- buildings, pretty much
animations with the same -- players and animals and scarecrows and trees and crops.

anything else? Not really. If that's the case, we may as well just have everything be "animated" with some things having only one frame because we only seem to have buildings
be still images.

each thing may have a slightly altered color palete, but it also may not. it probably depends on the object. Things like trees or wheat will be generated with the random seed
for that object. As will pretty much everything that's not player chosen.

]]--