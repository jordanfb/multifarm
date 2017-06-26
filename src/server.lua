
require "socket"

Server = {}

function Server:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

function Server:init(args)
	self.worldname = args.worldname
	self.headlessServer = args.headlessServer or true -- idk?
	self.allowMultiplayer = args.allowMultiplayer or true -- for not allowing people to join a singleplayer
	-- world? then wouldn't respond to broadcasts.

	self.serverPort = 12345
	self.ipAddress = self:getIpAddress()

	if not self:loadWorld(self.worldname) then
		-- somehow we have to show errors?
	end

	self.udp = socket.udp()
	self.udp:settimeout(0)
	if self.allowMultiplayer then
		self.udp:setsockname('*', self.serverPort) -- This should listen to any ip connecting to that port?
	else
		self.udp:setsockname(self.ipAddress, self.serverPort) -- only listen to yourself
	end
	self.connections = {} -- 1 - n of tables
	self.connectionMap = {} -- ip..port to 1-n index for connections
	-- self.responseManagerTable = {} -- this is a table that is used by the server to make sure things are transmitted
	-- that's created by the protocol creator, which also creates exactly what we need in it (the list of all response packets)
	self.latestPacketID = 1

	-- creating the protocol stuff.
	local gameProtocol = {} -- this has things like player move, shoot weapon, etc. -- changed per game
	--format is: {"packet name", bool is response required, "list of things in packet like:", "negint", "float", "str", "bool"}
	--now don't touch things!
	local defaultProtocol = {{"_ping", false, "int", "str", "negfloat", "float", "negint"}}
	-- local defaultProtocol = {{"_ping", false, "bool"}}
	local inProtocol = defaultProtocol
	for k, v in ipairs(gameProtocol) do
		table.insert(inProtocol, v)
	end
	self:createProtocol(inProtocol)
	-- done creating the protocol stuff

	-- self.protocol = {}
	-- self.protocolMap = {} -- created by interpreting the protocol
	-- the packet names can't start with _ because we use that for special things. Probably.
	-- we should interpret the protocol upon loading, and insert things like "recieved packet" etc.
	-- we make these by 
	-- I'm sending strings, ints, floats, and bools over the interwebs.
	-- we may want negative numbers? Combine bools with ints, and bools with floats


	-- what if we have three different channels inside this. we have,
	-- delivery guarentee not required, 
	-- delivery guarentee required
	-- and file transfer/large packets which delivery is required for. idk. do I need all three? hmmm.
	-- that seems overly complicated for now. As it is, there'll be the first two kinda.

	-- ping is going to be time server sent to you, time you send to server?
	self:packetTest(10000)
end

function Server:packetTest(numTries, printTests)
	local startTime = os.clock()
	local worked = true
	for i = 1, numTries do
		local struct = self.protocol[math.random(1, #self.protocol)]
		local comparisonTable = {struct[1]}
		if printTests then
			print("testing '"..struct[1].."'' packet")
		end
		for i = 5, #struct do
			if struct[i] == "int" then
				table.insert(comparisonTable, math.random(0, 100))
			elseif struct[i] == "negint" then
				table.insert(comparisonTable, math.random(-1000, 1000))
			elseif struct[i] == "bool" then
				table.insert(comparisonTable, math.random(0, 1) == 1)
			elseif struct[i] == "float" then
				table.insert(comparisonTable, math.random()*1000)
			elseif struct[i] == "negfloat" then
				table.insert(comparisonTable, math.random()*1000-500)
			elseif struct[i] == "str" then
				local strTable = {"what", "hello world", "swordfish", "idk", "tbt", "lots of really long text oh yeah you like that do you?"}
				table.insert(comparisonTable, strTable[math.random(1, #strTable)])
			else
				error("either an error with testing or with the packet. No such thing as "..tostring(struct[i]))
			end
		end
		if printTests then
			print("Comparison Table:")
			for k, v in pairs(comparisonTable) do
				print(v)
			end
			print("end")
		end
		local sendPacket = self:makePacket(comparisonTable)
		table.insert(comparisonTable, 2, self.latestPacketID-1)
		local recievePacket = self:interpretPacket(sendPacket)
		for i, v in pairs(recievePacket) do
			if v ~= comparisonTable[i] then
				if tonumber(comparisonTable[i]) ~= nil then
					if v-comparisonTable[i] > math.pow(10, -10) then
						error("ERROR! "..tostring(v).." != "..tonumber(tostring(comparisonTable[i])))
					end
				else
					error("ERROR! "..tostring(v).." != "..comparisonTable[i])
				end
				worked = false
			elseif printTests then
				print(tostring(v).." worked")
			end
		end
		if printTests then
			print() -- an extra line
		end
	end
	local timeTaken = os.clock()-startTime
	print("Tested "..numTries.." packets in "..timeTaken.." seconds.")
	print("All packet tests worked!")
end

function Server:createProtocol(inProtocol)
	self.protocol = {}
	self.protocolMap = {}
	self.responseManagerTable = {}
	for i, packet in ipairs(inProtocol) do
		table.insert(packet, 3, "") -- this is so that all packets are the same length
		-- it will be replaced in _response packets with the packet they respond to.
		table.insert(packet, 4, "int") -- this adds a packet id so that we know what it is. hmmm.
		if packet[2] then
			packet[3] = "_response"..packet[1]
		end
		table.insert(self.protocol, packet)
		if self.protocolMap[packet[1]] then
			error("Error on protocol making: Duplicates of: '"..packet[1].."'")
		else
			self.protocolMap[packet[1]] = #self.protocol
		end
		-- then make the response packet if it's needed:
		if packet[2] then
			-- then it needs confirmation that it was recieved, so make the special packet back
			local responsePacket = {}
			for k, v in ipairs(packet) do
				table.insert(responsePacket, v)
			end
			responsePacket[3] = responsePacket[1]
			responsePacket[2] = false -- because we don't want the response packet to need a response :P
			responsePacket[1] = "_response"..responsePacket[1]
			self.responseManagerTable[responsePacket[1]] = {} -- this table will be populated by the packets that are waiting for responses
			table.insert(self.protocol, responsePacket)
			if self.protocolMap[responsePacket[1]] then
				error("Error on protocol making: Duplicates of: '"..responsePacket[1].."'")
			else
				self.protocolMap[responsePacket[1]] = #self.protocol
			end
		end
	end
	if #self.protocol > 255 then
		error("Error creating protocol: more than 255 packet types, so you have to change the implimentation to handle that")
	end
end

function Server:sendUDPPacket(ip, port, packet)
	-- send it, but also record the stats for later
	error("We currenlty aren't actually sending packets. Just so you know.")
end

function Server:handlePacket(ip, port, packetTable)
	local packetType = packetTable[1]
	local packetID = packetTable[2] -- I'm going to make this guarenteed
	if self.protocol[self.protocolMap[packetType]][2] then
		-- if it's a packet we need to respond to, then make and send the changed packet back
		packetTable[1] = "_response"..packetTable[1]
		local responsePacket = self:makePacket(packetTable)
		-- send it out to the place we got it from
		self:sendUDPPacket(ip, port, responsePacket)
		packetTable[1] = packetType -- then fix it back to how it came to us.
	elseif #self.protocol[self.protocolMap[packetType]][3] > 0 then
		-- if it's a response to a packet that WE sent out that we wanted a response to, handle that here, then return
		-- we know that's the case, since it's not a thing we have to respond to, but it has a link to another packet in the third index
		if self.responseManagerTable[packetType][packetID] ~= nil then
			-- the packet made it and made it back, so hooray!
			self.responseManagerTable[packetType][packetID] = nil -- just remove it, we're probably just going to assume it's fine
		end
		return true
	end

	if false then
		-- if it's a network packet (starts with _ and isn't a response packet) then we handle it here
	else
		-- otherwise give the packet to the game
	end
end

function Server:interpretPacket(packet, printPacket)
	-- byte 1 is length of packet
	local packetLen = string.byte(packet, 1)
	local packetType = string.byte(packet, 2)
	local structure = self.protocol[packetType]
	if structure == nil then
		print("ERROR INTERPRETING PACKET!")
		error("I'm erroring here atm, because I want to make sure this gets done right")
		return {"_erroredPacket", packet}, "Packet type non-existant" -- return an error packet? it'll get ignored
	end
	if printPacket then
		print("Printing packet:")
		for i = 1, string.byte(packet)+1 do
			print(string.byte(packet, i))
		end
		print("Finished printing packet")
	end
	local packetContent = {structure[1]}
	local errorMessage = ""
	local i = 3 -- byte 3 is the start of the packet data?
	-- for j, packetComponent in ipairs(structure) do
	for j = 4, #structure do
		local packetComponent = structure[j]
		-- interpret that part of the packet
		if i > packetLen+1 then
			errorMessage = "Packet too short"
			error("Packet too short")
			break
		end
		if packetComponent == "int" then
			local intLen = string.byte(packet, i)
			local intStr = string.sub(packet, i+1, i+intLen)
			local int = self:charsToInt(intStr)
			table.insert(packetContent, int)
			i = i + intLen + 1 -- move along in the packet
		elseif packetComponent == "negint" then
			local isPositive = string.byte(packet, i) == 1 -- if it's equal to 1 then it's true, otherwise (like a zero) then it's false
			i = i + 1 -- after this it's pretty much just a regular int
			local intLen = string.byte(packet, i)
			local intStr = string.sub(packet, i+1, i+intLen)
			local int = self:charsToInt(intStr)
			if not isPositive then
				int = -int
			end
			table.insert(packetContent, int)
			i = i + intLen + 1
		elseif packetComponent == "bool" then
			local bool = string.byte(packet, i) == 1
			table.insert(packetContent, bool)
			i = i + 1
		elseif packetComponent == "str" then
			local strLen = string.byte(packet, i)
			local str = string.sub(packet, i+1, i+strLen)
			table.insert(packetContent, str)
			i = i + strLen + 1
		elseif packetComponent == "float" then
			-- get the integer part
			local intLen = string.byte(packet, i)
			local intStr = string.sub(packet, i+1, i+1+intLen)
			local intComponent = self:charsToInt(intStr)
			i = i + intLen + 1 -- move along in the packet
			-- then the fractional part
			local powerLed = string.byte(packet, i)
			local powerStr = string.sub(packet, i+1, i+1+powerLed)
			local powerComponent = self:charsToInt(powerStr)
			i = i + powerLed + 1 -- move along in the packet
			-- then make the float by combining the two values
			table.insert(packetContent, intComponent/math.pow(10, powerComponent))
		elseif packetComponent == "negfloat" then
			local isPositive = string.byte(packet, i) == 1
			i = i + 1
			-- get the integer part
			local intLen = string.byte(packet, i)
			local intStr = string.sub(packet, i+1, i+intLen)
			local intComponent = self:charsToInt(intStr)
			i = i + intLen + 1 -- move along in the packet
			-- then the fractional part
			local powerLed = string.byte(packet, i)
			local powerStr = string.sub(packet, i+1, i+powerLed)
			local powerComponent = self:charsToInt(powerStr)
			i = i + powerLed + 1 -- move along in the packet
			-- then make the float by combining the two values
			if not isPositive then
				intComponent = -intComponent
			end
			table.insert(packetContent, intComponent/math.pow(10, powerComponent))
		else
			-- it's not supported as of yet
			errorMessage = "Packet has non-supported type in protocol'"..tostring(packetComponent).."'"
			error(errorMessage)
		end
	end
	if i <= #packet then
		-- error because the packet should be over now
		errorMessage = "Packet too long"
	end
	return packetContent, errorMessage
end

function Server:interpretRecievedData(data)
	-- use self.protocol. that makes sense.
	local i = 1
	while i < #data do
		local packetLen = string.byte(data, i)
		local subPacket = string.sub(data, i, i+packetLen)
		-- packet is: packetLen, packet type, packet id in arbitrary int form, then other stuff in the packet.
		local interpretedPacket, errorMessage = self:interpretPacket(subPacket)
		self:handlePacket(interpretedPacket)
		i = i + packetLen + 1
	end
end

function Server:makePacket(packetData)
	-- packet is a table which passes in {name, content1, content2, etc.}
	-- we already know their types from the protocol definition we've made.
	-- we also already know whether or not we have to wait for a response for them.
	-- what's passed in is {packetname, packetvar1, packetvar2, packetvar3...}
	local structure = self.protocol[self.protocolMap[packetData[1]]]
	-- first we make the entire packet but ignore the packet type, because if it requires a response we want to save both types

	-- add packet ID to packet
	local packet = self:intToChars(self.latestPacketID)
	packet = string.char(#packet)..packet
	-- done adding packet ID to packet

	for i = 5, #structure do
		-- start with 5 because 1 is packet name, 2 is require response, 3 is a blank thing, and 4 is packet id (which we added earlier)
		if structure[i] == "int" then
			local intStr = self:intToChars(packetData[i-3])
			packet = packet .. string.char(#intStr) .. intStr
		elseif structure[i] == "negint" then
			local intval = packetData[i-3]
			if packetData[i-3] > 0 then
				packet = packet .. string.char(1)
			else
				packet = packet .. string.char(2)
				intval = -intval -- make it positive
			end
			local intStr = self:intToChars(intval)
			packet = packet .. string.char(#intStr) .. intStr
		elseif structure[i] == "bool" then
			if packetData[i-3] then
				packet = packet .. string.char(1)
			else
				packet = packet .. string.char(0)
			end
		elseif structure[i] == "str" then
			packet = packet .. string.char(#packetData[i-3]) .. packetData[i-3]
		elseif structure[i] == "float" then
			local value = packetData[i-3]
			local fpart = 0
			-- local ipart, fpart = math.modf(packetData[i-3])
			-- local istr = self:intToChars(ipart)
			while value - math.floor(value) ~= 0 do
				value = value * 10
				fpart = fpart + 1
			end
			local istr = self:intToChars(value)
			local fstr = self:intToChars(fpart)
			packet = packet .. string.char(#istr) .. istr .. string.char(#fstr) .. fstr
		elseif structure[i] == "negfloat" then
			local floatVal = packetData[i-3]
			if packetData[i-3] > 0 then
				packet = packet .. string.char(1)
			else
				floatVal = -packetData[i-3]
				packet = packet .. string.char(0)
			end
			local fpart = 0
			while floatVal - math.floor(floatVal) ~= 0 do
				floatVal = floatVal * 10
				fpart = fpart + 1
			end
			local istr = self:intToChars(floatVal)
			local fstr = self:intToChars(fpart)
			packet = packet .. string.char(#istr) .. istr .. string.char(#fstr) .. fstr
		else
			-- error?
			error("Non-supported packet content tried to be created: " .. structure[i])
		end
	end
	local packetType = string.char(self.protocolMap[packetData[1]])
	local outgoingPacket = packetType .. packet
	outgoingPacket = string.char(#outgoingPacket) .. outgoingPacket
	local returnPacketTable = nil
	if structure[2] then
		-- it wants a response, so add it and extra data to responseManagerTable
		-- repsonsemanagerTable is going to have:
		-- {ipofrecipient, portofrecipient, time since last sent, packetToSend, packetToExpect}
		local returnPacketType = string.char(self.protocolMap[packet[3]])
		local returnPacket = returnPacketType .. packet
		returnPacket = string.char(#returnPacket) .. returnPacket
		returnPacketTable = {outgoingPacket, returnPacket, self.latestPacketID, 0, "", -1} -- the last three are time since last sent, ip, and port of recipient
		-- self.responseManagerTable[packet[3]][self.latestPacketID] = returnPacketTable
		-- this is going to be handled elsewhere, because it shouldn't be here
	end
	self.latestPacketID = self.latestPacketID + 1 -- we may want to do something with modding this, but IDK ATM.
	return outgoingPacket, returnPacketTable
end

function Server:intToChars(int)
	local out = ""
	while int > 0 do
		out = string.char(int % 256) .. out
		int = math.floor(int / 256)
	end
	return out
end

function Server:charsToInt(str)
	local multiple = 1
	local out = 0
	for i = #str, 1, -1 do
		out = out + string.byte(str, i)*multiple
		multiple = multiple * 256
	end
	return out
end

function Server:floatToChars(float)
	--
end

function Server:charsToFloat(chars)
	--
end

function Server:loadWorld(worldname)
	local worldExists = false
	if not self.headlessServer then
		-- then check the saves folder?
		-- it uses love, so we have to check whether we have that? idk.
		if love.filesystem.exists("saves/"..worldname) then
			if love.filesystem.isdir("saves/"..worldname) then
				worldExists = true
				-- load the world, yeah, do that. Use LOVE.
				self.worldData = {}
				self.playerData = {}
			end
		end
	else
		-- then check the folder the file is in?
	end
	if worldExists == false then
		print("error loading non-existant world folder")
		return false
	end
end

function Server:recieve()
	local data, msg_or_ip, port_or_nil = self.udp:receivefrom()
	if data then
		-- do stuff to it
	end
end

function Server:update(dt)
	--
end

function Server:draw()
	-- lol
end

function Server:getIpAddress()
	local s = socket.udp()
	s:setpeername("74.125.115.104", 80) -- connects to google, should work when offline
	local ip, _ = s:getsockname()
	return ip
end