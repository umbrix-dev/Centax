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
For the whole usage guide see: [USAGE.md](https://github.com/umbrix-dev/Centax/blob/main/USAGE.md)
#

> [!NOTE]
> Server and client each have their own isolated context, events created on the server are not accessible from the client and vice versa.
Inserting a duplicate event will override the last one.

License
MIT — see [LICENSE](https://github.com/umbrix-dev/Centax/blob/main/LICENSE).
