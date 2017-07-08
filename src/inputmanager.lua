
InputManager = {}

function InputManager:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function InputManager:init()
	self.context = "menu"
	self.menumap = {space = "select", up = "up", down = "down", left = "left", right = "right", enter = "select"}
	self.gameplaymap = {w = "moveup", a = "moveleft", s = "movedown", d = "moveright", ["-"] = "zoomout", ["="]="zoomin", space = "test", f2 = "fullscreen"}
	self.allmaps = {menu = self.menumap, gameplay = self.gameplaymap}
	self.valuemap = {}
	self.mouseX = love.mouse.getX()
	self.mouseY = love.mouse.getY()

	-- I'm going to need to deal with contexts for this.

	self.inputBuffer = {}
	-- this is a list of all inputs along with delays until the next input, along with context at the time of the input, all so that it can recreate
	-- things for multiplayer.
	-- 1 = {input = "inputType", value = "inputValue", dt = time until next input or -1, time = time it occured, context = "context input was made in"}
	-- we only care about the first context, since that was what was confirmed. All the other contexts should be re-evaluated after you get an input confirmation by the
	-- server. That way we avoid having issues like opening chests when we shouldn't have, and instead we open the player's inventory instead of closing the chest.
end

function InputManager:pruneInputHistory(pruneTime)
	-- walk through the history list and remove all the things before the time.
	local i = 1
	for i, input in ipairs(self.inputBuffer) do
		if input.time > pruneTime then
			break
		end
	end
	for i = i -1, 1, -1 do
		table.remove(self.inputBuffer, i)
	end
end

--[[
I think what needs to happen is that everything has to be undoable? So that when something is confirmed or denied, what happens is that the input manager prunes to that time,
the client unwinds everything, then the changes are made (or not made? If it accepts it then do we need to do this? probably not.), then the inputs are all re-simulated, (and the
things not controlled by the player are just stepped forward however they are.) -- what happens when you hit someone in the re-wind but not the original?

This farming game is pretty basic. The only things we may need to be able to roll back are ground types (i.e. both people try to plant something at the same time, or chop down a
tree, or whatever.) and there's also animal attraction, but that doesn't need to be rolled back neccisarily, since it can just occur, and be less precise. I may want leads though,
but that's a simple thing of "lead denied" and the lead will just stop. The planting issue is easy as well since the server will just send the definitive ground type when it
occurs. Thus all that needs to happen in this game is re-simulation of movements based on the confirmed player location.

Next games will be harder, but that's fine. For now we can do this.

My goal is to do things. I want to have the base game done within the week. I can work on art later. For now I want to do collision and changing the ground type on the test
client. I should then make a fake networking connection between the server and the real client to test things easier? May as well.
]]

function InputManager:update(dt)
	self.mouseX = love.mouse.getX()
	self.mouseY = love.mouse.getY()
end

function InputManager:keypressed(key, unicode)
	return {self.allmaps[self.context][key], 1}
end

function InputManager:keyreleased(key, unicode)
	return {self.allmaps[self.context][key], 0}
end

function InputManager:setContext(newContext)
	self.context = newContext
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