--[[
	// Project
		Centax by @umbrix | Licensed under the "MIT" license.
		Discord: umb.rph
		Github: https://www.github.com/umbrix-dev/centax
		Asset: https://create.roblox.com/store/asset/91565758305206
	
	// Description
		Centax is a simple to use shared event manager.
		Wrap existing Roblox signals like "Players.PlayerAdded"
		or create custom events and listen to them from anywhere,
		without scattered connections.
	
	// API
		- insert(eventName: string, signal: RBXScriptSignal?) -> { destroy: () -> () }
		- fire<T...>(eventName: string, ...: T...)
		- exists(eventName: string): boolean
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
	Event: RBXScriptSignal | "Custom",
	Callbacks: { (...any) -> () }
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
	
	nonCustomEvent = function(eventName: string)
		centaxError("Cannot fire non-custom event with signal: " .. eventName)
	end,
}

--[[
	Inserts an event with or without a signal.
	You can listen to an inserted event using 'Centax.listen("event name", callback)'.
	When not passing in a signal it will be treated as a custom event.
	Custom events need to be fired manually using 'Centax.fire("event name")'.
	Returns a destroy function to completely remove the event.
]]
function Centax.insert(eventName: string, signal: RBXScriptSignal?): { destroy: () -> () }
	if Centax.exists(eventName) then
		errors.eventExists(eventName)
	end
	
	local data: Handler = {
		Event = signal or "Custom",
		Callbacks = {}
	}
	
	local side = getSide()
	side[eventName] = data
	
	if signal then
		connections[eventName] = signal:Connect(function(...)
			for _, callback in ipairs(side[eventName].Callbacks) do
				callback(...)
			end
		end)
	end
	
	return {
		destroy = function()
			Centax.destroy(eventName)
		end,
	}
end

-- Fires a event without a signal also called an custom event.
function Centax.fire<T...>(eventName: string, ...: T...)
	if not Centax.exists(eventName) then
		errors.eventNoExist(eventName)
	end
	
	local handler: Handler = getSide()[eventName]
	if handler.Event ~= "Custom" then
		errors.nonCustomEvent(eventName)
	end
	
	for _, callback in ipairs(handler.Callbacks) do
		callback(...)
	end
end

--[[
	Check if a specific event exists.
	Returns a boolean to let you know.
]]
function Centax.exists(eventName: string): boolean
	return getSide()[eventName] ~= nil
end

--[[
	Listen to a specific event and attach a callback that will run once it fires.
	Will work on events with and without a signal.
	Returns a cancel function which will remove the callback from the event or nil when the event was not found.
]]
function Centax.listen<T...>(eventName: string, callback: (T...) -> ()): { cancel: () -> () }
	if not Centax.exists(eventName) then
		errors.eventNoExist(eventName)
	end

	local callbacks = getSide()[eventName].Callbacks
	table.insert(callbacks, callback :: (...any) -> ())
	
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
	
	local callbacks = getSide()[eventName].Callbacks
	local index = table.find(callbacks, callback :: (...any) -> ())
	if not index then
		return
	end
	
	table.remove(callbacks, index)
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
function Centax.once<T...>(eventName: string, callback: (T...) -> ())
	local newCallback
	newCallback = function(...)
		callback(...)
		Centax.cancel(eventName, newCallback :: (...any) -> ())
	end
	
	Centax.listen(eventName, newCallback)
end

return Centax
