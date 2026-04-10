--[[
	// Project
		Centax by @umbrix | Licensed under the "MIT" license.
		Discord: umb.rph
		Github: https://www.github.com/umbrix-dev/centax
	
	// Description
		A simple to use shared context module.
		Create, listen and manage existing events like "Players.PlayerAdded"
		or custom events in a shared context which you can access from the same side
		it got created in e.g. server or client.
	
	// API
		- insert(eventName: string, signal: RBXScriptSignal?) -> { destroy: () -> () }
		- fire<T...>(eventName: string, ...: T...)
		- exists(eventName: string): boolean
		- listen<T...>(eventName: string, callback: (T...) -> ()): { cancel: () -> () }?
		- cancel<T...>(eventName: string, callback: (T...) -> ())
		- clear(eventName: string?)
		- destroy(eventName: string)
		- once<T...>(eventName: string, callback: (T...) -> ())
		- build()
		
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
local connections: { RBXScriptConnection } = {}

local function getSide(): Side
	if RunService:IsServer() then
		return server
	else
		return client
	end
end

--[[
	Inserts an event with or without a signal.
	You can listen to an inserted event using 'Centax.listen("event name", callback)'.
	When not passing in a signal it will be treated as a custom event.
	Custom events need to be fired manually using 'Centax.fire("event name")'.
	Returns a destroy function to completely remove the event.
]]
function Centax.insert(eventName: string, signal: RBXScriptSignal?): { destroy: () -> () }
	local data: Handler = {
		Event = signal or "Custom",
		Callbacks = {}
	}
	
	getSide()[eventName] = data
	
	Centax.build()
	
	return {
		destroy = function()
			Centax.destroy(eventName)
		end,
	}
end

-- Fires a event without a signal also called an custom event.
function Centax.fire<T...>(eventName: string, ...: T...)
	if not Centax.exists(eventName) then
		return
	end
	
	local handler: Handler = getSide()[eventName]
	if handler.Event ~= "Custom" then
		return
	end
	
	for _, callback in pairs(handler.Callbacks) do
		callback(...)
	end
end

--[[
	Check if a specific event exists.
	Returns a boolean to let you know.
]]
function Centax.exists(eventName: string): boolean
	local side = getSide()
	if not side[eventName] then
		return false
	else
		return true
	end
end

--[[
	Listen to a specific event and attach a callback that will run once it fires.
	Will work on events with and without a signal.
	Returns a cancel function which will remove the callback from the event or nil when the event was not found.
]]
function Centax.listen<T...>(eventName: string, callback: (T...) -> ()): { cancel: () -> () }?
	if not Centax.exists(eventName) then
		return nil
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
			return
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
		getSide()[eventName] = nil
		Centax.build()
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

-- Clean and build all connections and connect their callbacks.
-- Will be executed automatically when inserting or destroying a event.
function Centax.build()
	for _, connection: RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end
	
	table.clear(connections)
	
	for _, handler: Handler in pairs(getSide()) do
		if handler.Event == "Custom" then
			continue
		end
		
		local connection = handler.Event:Connect(function(...)
			for _, callback in pairs(handler.Callbacks) do
				callback(...)
			end
		end)
		
		table.insert(connections, connection)
	end
end

return Centax
