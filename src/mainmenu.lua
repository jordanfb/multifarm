
MainMenu = {}

require "button"

function MainMenu:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function MainMenu:init(game)
	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.game = game
	self.inputManager = game.inputManager

	-- stuff:
	local buttonTable = {x = love.graphics.getWidth()/2, y = love.graphics.getHeight()/2, game = self.game, key = "space",
						text = "Play", callbackFunction = MainMenu.buttonCallback, callbackArea = self}
	self.playButton = Button:new()
	self.playButton:init(buttonTable)

	self.game = game
end

function MainMenu:buttonCallback(id, value)
	if value == 1 then
		if id == "Play" then
			-- start playing! Yay!
			print("play")
			self.game:addToScreenStack(self.game.testClient)
			self.game.inputManager:setContext("gameplay")
		end
	end
end

function MainMenu:load()
	-- run when the level is given control
end

function MainMenu:leave()
	-- run when the level no longer has control
end

function MainMenu:draw()
	self.playButton:draw()
end

function MainMenu:update(dt)
	self.playButton:update(dt)
end

function MainMenu:resize(w, h)
	--
end

function MainMenu:handleinput(input)
	--
end