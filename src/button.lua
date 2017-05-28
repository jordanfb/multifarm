
Button = {}

function Button:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function Button:init(args)
	-- self.args = args
	self.x = args.x
	self.y = args.y
	self.width = args.width or 100
	self.height = args.height or 50
	self.text = args.text or "hello world"
	self.id = args.id or self.text -- this is an idea in case I want several buttons with the same text?
	self.color = args.color or {255, 255, 255, 255}
	self.textColor = args.textColor or {0, 0, 0, 255}
	self.highlightColor = args.highlightColor or {100, 100, 100, 255}

	self.game = args.game
	self.font = args.font or args.game.font
	self.inputManager = args.inputManager or args.game.inputManager

	self.key = args.key or nil
	self.allowMouse = args.allowMouse or true
	self.callbackFunction = args.callbackFunction
	self.callbackArea = args.callbackArea

	self.highlighted = false
	self.pressed = false
	self.drawText = love.graphics.newText(self.font, self.text)
end

function Button:draw()
	if self.highlighted then
		love.graphics.setColor(self.highlightColor)
	else
		love.graphics.setColor(self.color)
	end
	love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2, self.width, self.height)
	love.graphics.setColor(self.textColor)
	-- love.graphics.printf(self.text, self.x-self.width/2, self.y, self.width, "center")
	love.graphics.draw(self.drawText, self.x-self.drawText:getWidth()/2, self.y-self.drawText:getHeight()/2)
end

function Button:update(dt)
	if self.allowMouse then
		self.highlighted = self:coordsOverButton(self.inputManager.mouseX, self.inputManager.mouseY)
		if self.highlighted then
			if love.mouse.isDown(1) then
				-- it's clicked. We should do things with things, probably. and inputmanager
				self:buttonPressed()
			else
				self:buttonReleased()
			end
		end
	end
	if self.key and love.keyboard.isDown(self.key) then
		self:buttonPressed()
		self:buttonReleased()
	end
end

function Button:buttonPressed()
	-- the button sends value 0 when released, 1 when first pressed, and 2 when held down for more than an update
	if not self.pressed then
		if self.callbackFunction then
			self.callbackFunction(self.callbackArea, self.id, 1)
		end
		self.pressed = true
	else
		-- it's being held down?
		if self.callbackFunction then
			self.callbackFunction(self.callbackArea, self.id, 2)
		end
	end
end

function Button:buttonReleased()
	if self.pressed then
		if self.callbackFunction then
			self.callbackFunction(self.callbackArea, self.id, 0)
		end
		self.pressed = false
	end
end

function Button:coordsOverButton(x, y)
	if x > self.x - self.width/2 and x < self.x + self.width/2 then
		if y > self.y - self.height/2 and y < self.y + self.height/2 then
			return true
		end
	end
	return false
end