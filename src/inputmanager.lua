
InputManager = {}

function InputManager:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function InputManager:init()
	self.keymap = {w = "moveup", a = "moveleft", s = "movedown", d = "moveright", ["-"] = "zoomout", ["="]="zoomin"}
	self.valuemap = {}
	self.mouseX = love.mouse.getX()
	self.mouseY = love.mouse.getY()
end

function InputManager:update(dt)
	self.mouseX = love.mouse.getX()
	self.mouseY = love.mouse.getY()
end

function InputManager:keypressed(key, unicode)
	return {self.keymap[key], 1}
end

function InputManager:keyreleased(key, unicode)
	return {self.keymap[key], 0}
end

function InputManager:mousepressed(button, x, y)
	return {}
end

function InputManager:mousereleased(button, x, y)
	return {}
end

function InputManager:mousemoved(x, y, dx, dy)
	return {}
end