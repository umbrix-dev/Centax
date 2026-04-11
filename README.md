![Centax](https://github.com/umbrix-dev/Centax/blob/main/BANNER.png)
A simple, lightweight shared event manager for Roblox Studio.

Instead of scattering connections across scripts, Centax gives you a single central place
to wrap existing Roblox Studio signals, and listen to them from
anywhere on the same side e.g. server or client, no references required.

## Installation
Quickly install it using the [**Roblox asset store**](https://create.roblox.com/store/asset/91565758305206) or 
download the .rblxm file from the [**Latest releases page**](https://github.com/umbrix-dev/Centax/releases/latest),
then just drag and drop it anywhere into Roblox Studio.

## Usage
Wrapping a Roblox Studio signal
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Centax = require(ReplicatedStorage.Centax)

local Players = game:GetService("Players")

-- Script A
Centax.insert("PlayerRemoving", Players.PlayerRemoving)

-- Script B
Centax.listen("PlayerRemoving", function(player: Player)
    print(player.Name, "left!")
end)
```

One-time listener
```luau
Centax.once("PlayerRemoving", function(player: Player)
    print("First player to leave:", player.Name)
end)
```

Removing a listener
```luau
local listener = Centax.listen("PlayerRemoving", function(player: Player)
    print(player.Name)
end)

listener.cancel()
```

Removing an event
```luau
local event = Centax.insert("Heartbeat", RunService.Heartbeat)

event.destroy()
-- or
Centax.destroy("Heartbeat")
```

> [!NOTE]
> Server and client each have their own isolated context, events created on the server are not accessible from the client and vice versa.
Inserting a duplicate event will override the last one.

License
MIT — see [LICENSE](https://github.com/umbrix-dev/Centax/blob/main/LICENSE).
