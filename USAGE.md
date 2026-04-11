# Usage
## Setup
Place the Centax module in `ReplicatedStorage` or any other place and require it from any script.
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Centax = require(ReplicatedStorage.Centax)
```

---

## Inserting an event
Wrap an existing Roblox Studio signal and register it under a name.
```luau
local Players = game:GetService("Players")

Centax.insert("PlayerAdded", Players.PlayerAdded)
```
Inserting an event that already exists will override it, cleanly disconnecting the old
connection first.

---

## Listening to an event
Attach a callback to a registered event. Returns a `{ cancel }` object.
```luau
Centax.listen("PlayerAdded", function(player: Player)
    print(player.Name, "joined!")
end)
```
Listen from anywhere on the same side, no references needed.

---

## Priority
Lower numbers fire first. Callbacks without a priority are appended to the end.
```luau
Centax.listen("PlayerAdded", function(player: Player)
    print("fires third")
end)

Centax.listen("PlayerAdded", function(player: Player)
    print("fires first")
end, 1)

Centax.listen("PlayerAdded", function(player: Player)
    print("fires second")
end, 2)
```

---

## Canceling a listener
```luau
local listener = Centax.listen("PlayerAdded", function(player: Player)
    print(player.Name)
end)

listener.cancel()
```

---

## One-time listener
Fires once then automatically removes itself. Supports priority.
```luau
Centax.once("PlayerAdded", function(player: Player)
    print("First player:", player.Name)
end)
```

---

## Yielding
Yields the current thread until the event exists. Returns `true` if found, `false` if timed out.
```luau
-- Yield indefinitely
Centax.yield("PlayerAdded")
Centax.listen("PlayerAdded", callback)

-- Yield with timeout
if Centax.yield("PlayerAdded", 5) then
    Centax.listen("PlayerAdded", callback)
else
    warn("PlayerAdded never registered")
end
```

---

## Checking if an event exists
```luau
if Centax.exists("PlayerAdded") then
    Centax.listen("PlayerAdded", callback)
end
```

---

## Clearing callbacks
Clear all callbacks from a specific event, or all events at once.
```luau
Centax.clear("PlayerAdded") -- clears one event
Centax.clear()              -- clears all events
```

---

## Destroying an event
Completely removes the event and disconnects its signal.
```luau
local event = Centax.insert("Heartbeat", RunService.Heartbeat)

event.destroy()
-- or
Centax.destroy("Heartbeat")
```

---

## Server / Client
Centax is side-aware. Events inserted on the server are not visible on the client and vice
versa. The seperation is automatic, no manual intervention needed.
```luau
-- Server script
Centax.insert("PlayerAdded", Players.PlayerAdded)

-- LocalScript (client) — cannot see "PlayerAdded", completely isolated
print(Centax.exists("PlayerAdded")) -- false
```
