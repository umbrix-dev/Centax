--[[ ============================== Centax ==============================
	// @umbrix (dc: umb.rph)
	// Asset Store: https://create.roblox.com/store/asset/91565758305206
	// Github: https://github.com/umbrix-dev/Centax/tree/main

	// Description
		Centax is a simple to use shared event manager.
		Wrap existing Roblox signals like "Players.PlayerAdded"
		and listen to them from anywhere on the same side,
		without scattered connections.
	
	// API
		- insert(eventName: string, signal: RBXScriptSignal?) -> { destroy: () -> () }
		- exists(eventName: string): boolean
		- yield(eventName: string, timeout: number?): boolean
		- listen<T...>(eventName: string, callback: (T...) -> ()): { cancel: () -> () }?
		- cancel<T...>(eventName: string, callback: (T...) -> ())
		- clear(eventName: string?)
		- destroy(eventName: string)
		- once<T...>(eventName: string, callback: (T...) -> ())
		
	// Examples usage (server)
	```
		local Players = game:GetService("Players")

		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Centax = require(ReplicatedStorage.Centax)

		Centax.insert("PlayerAdded", Players.PlayerAdded)

		Centax.listen("PlayerAdded", function(player: Player)
			Centax.insert("CharacterAdded", player.CharacterAdded)
			Centax.insert("CharacterRemoving", player.CharacterRemoving)
			
			Centax.listen("CharacterAdded", function(character: Model)
				print("Character:", character.Name, "got added!")
			end)
			
			Centax.listen("CharacterRemoving", function(character: Model)
				print("Character:", character.Name, "got removed!")
			end)
		end)
	```
]]

--!strict
--!optimize 2

local RunService = game:GetService("RunService")

type Handler = {
	Event: RBXScriptSignal,
	Callbacks: { { callback: (...any) -> (), priority: number } }
}

type Side = { [string]: Handler }

local Centax = {}

local server = {}
local client = {}
local connections: { [string]: RBXScriptConnection } = {}

local function getSide(): Side
	if RunService:IsServer() then
		return server
	else
		return client
	end
end

local function centaxError(message: string?)
	error("[Centax]: " .. tostring(message or "Error"))
end

local errors = {
	eventExists = function(eventName: string)
		centaxError("Event: " .. eventName .. " already exists")
	end,
	
	eventNoExist = function(eventName: string)
		centaxError("Event: " .. eventName .. " doesn't exist")
	end,
	
	noSignalPassed = function()
		centaxError("Missing 'signal' argument")
	end,
}

--[[
	Inserts an event attached to a signal.
	You can listen to an inserted event using 'Centax.listen("event name", callback)'.
	Returns a destroy function to completely remove the event.
]]
function Centax.insert(eventName: string, signal: RBXScriptSignal): { destroy: () -> () }
	if not signal then
		errors.noSignalPassed()
	end
	
	if Centax.exists(eventName) then
		Centax.destroy(eventName)
	end
	
	local data: Handler = {
		Event = signal,
		Callbacks = {}
	}
	
	local side = getSide()
	side[eventName] = data
	
	if signal then
		connections[eventName] = signal:Connect(function(...)
			for _, callbackData in ipairs(table.clone(side[eventName].Callbacks)) do
				callbackData.callback(...)
			end
		end)
	end
	
	return {
		destroy = function()
			Centax.destroy(eventName)
		end,
	}
end

--[[
	Check if a specific event exists.
	Returns a boolean to let you know.
]]
function Centax.exists(eventName: string): boolean
	return getSide()[eventName] ~= nil
end

--[[
	Yields the current thread until the event exists or the timeout is reached.
	Returns true if found, false if timed out. Yields indefinitely when no timeout is given.
]]
function Centax.yield(eventName: string, timeout: number?): boolean
	local elapsed = 0
	while not Centax.exists(eventName) do
		elapsed += task.wait()
		if timeout and elapsed >= timeout then
			return false
		end
	end
	
	return true
end

--[[
	Listen to a specific event and attach a callback that will run once it fires.
	Priority: 1 = Highest.
	Returns a cancel function which will remove the callback from the event or nil when the event was not found.
]]
function Centax.listen<T...>(eventName: string, callback: (T...) -> (), priority: number?): { cancel: () -> () }
	if not Centax.exists(eventName) then
		errors.eventNoExist(eventName)
	end

	priority = priority or math.huge
	local inserted = false
	
	local callbackDatas = getSide()[eventName].Callbacks
	local function insert(index: number?)
		local data = {
			callback = callback :: (...any) -> (),
			priority = priority :: number,
		}
		
		if index then
			table.insert(callbackDatas, index, data)
		else
			table.insert(callbackDatas, data)
		end
	end
	
	
	for index, callbackData in ipairs(callbackDatas) do
		if callbackData.priority > priority then
			insert(index)
			inserted = true
			break
		end
	end
	
	if not inserted then
		insert()
	end
	
	return {
		cancel = function()
			Centax.cancel(eventName, callback)
		end,
	}
end

-- Remove a event listener / callback from an event.
function Centax.cancel<T...>(eventName: string, callback: (T...) -> ())
	if not Centax.exists(eventName) then
		errors.eventNoExist(eventName)
	end
	
	local callbackDatas = getSide()[eventName].Callbacks
	for index = #callbackDatas, 1, -1 do
		if callbackDatas[index].callback == callback then
			table.remove(callbackDatas, index)
		end
	end
end

-- Clear all or a specific event's callbacks
function Centax.clear(eventName: string?)
	local side = getSide()
	
	if eventName then
		if not Centax.exists(eventName) then
			errors.eventNoExist(eventName)
		end
		
		local handler: Handler = side[eventName]
		handler.Callbacks = {}
	else
		for _, handler: Handler in pairs(side) do
			handler.Callbacks = {}
		end
	end
end

-- Remove a event
function Centax.destroy(eventName: string)
	if Centax.exists(eventName) then
		if connections[eventName] then
			connections[eventName]:Disconnect()
			connections[eventName] = nil
		end
		
		getSide()[eventName] = nil
	else
		errors.eventNoExist(eventName)
	end
end

-- Similar to "Centax.listen" but will cancel itself after being fired.
function Centax.once<T...>(eventName: string, callback: (T...) -> (), priority: number?)
	local newCallback
	newCallback = function(...)
		callback(...)
		Centax.cancel(eventName, newCallback :: (...any) -> ())
	end
	
	Centax.listen(eventName, newCallback, priority)
end

return Centax
