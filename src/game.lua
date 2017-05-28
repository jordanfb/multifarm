
require "inputmanager"
require "mainmenu"
require "server"
require "testclient"

Game = {}

function Game:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function Game:init(args)
	self.args = args
	self.inputManager = InputManager:new()
	self.inputManager:init()

	self.font = love.graphics.newFont(12)

	self.testClient = TestClient:new({game = self})

	self.mainMenu = MainMenu:new()
	self.mainMenu:init(self)

	-- self.server = Server:new()
	-- self.server:init({})


	self.screenStack = {}
	self.drawLayersStart = 0

	self:addToScreenStack(self.mainMenu)

	self.debug = true
end

function Game:calculateDrawUpdateLevels()
	self.drawLayersStart = 1 -- this will become the index of the lowest item to draw
	for i = #self.screenStack, 1, -1 do
		self.drawLayersStart = i
		if not self.screenStack[i].drawUnder then
			break
		end
	end
end

function Game:addToScreenStack(newScreen)
	if self.screenStack[#self.screenStack] ~= nil then
		self.screenStack[#self.screenStack]:leave()
	end
	self.screenStack[#self.screenStack+1] = newScreen
	newScreen:load()
	self:calculateDrawUpdateLevels()
end

function Game:popScreenStack()
	self.screenStack[#self.screenStack]:leave()
	self.screenStack[#self.screenStack] = nil
	self.screenStack[#self.screenStack]:load()
	self:calculateDrawUpdateLevels()
end

function Game:update(dt)
	--
end

function Game:draw()
	-- this is so that the things earlier in the screen stack get drawn first, so that things like pause menus get drawn on top.
	for i = self.drawLayersStart, #self.screenStack, 1 do
		self.screenStack[i]:draw()
	end

	-- love.graphics.setCanvas()
	-- love.graphics.setColor(255, 255, 255)
	if self.debug then
		love.graphics.setColor(255, 0, 0)
		love.graphics.print("FPS: "..love.timer.getFPS(), 10, love.graphics.getHeight()-45)
		love.graphics.setColor(255, 255, 255)
	end
end

function Game:update(dt)
	-- self.joystickManager:update(dt)
	for i = #self.screenStack, 1, -1 do
		self.screenStack[i]:update(dt)
		if self.screenStack[i] and not self.screenStack[i].updateUnder then
			break
		end
	end
	self.inputManager:update(dt)
end

function Game:handleinput(input)
	-- input is probably a table? or it could have x and y values and that'd be it...
	if input[1] then
		-- it's a thing that's happening here, not nil
		self.screenStack[#self.screenStack]:handleinput(input)
	end
end

function Game:keypressed(key, unicode)
	if key == "f1" then
		love.event.quit()
	elseif key == "escape" then
		if #self.screenStack == 1 then
			love.event.quit()
		end
	end
	self:handleinput(self.inputManager:keypressed(key, unicode))
end

function Game:keyreleased(key, unicode)
	self:handleinput(self.inputManager:keyreleased(key, unicode))
end

function Game:mousepressed(button, x, y)
	self:handleinput(self.inputManager:mousepressed(button, x, y))
end

function Game:mousereleased(button, x, y)
	self:handleinput(self.inputManager:mousereleased(button, x, y))
end

-- function love.gamepadpressed()
-- 	--
-- end
