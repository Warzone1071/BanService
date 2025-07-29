# 🔨 BanService
Credits to luascapes WebhookService it made making the webhook system 10x easier

A fully-featured **Roblox BanService** module that handles player bans (online/offline), unbans, duration handling, session saving/loading, and Discord webhook logging.

---

## 📦 Features

- ✅ Ban players online or offline
- ✅ Temporary and permanent bans
- ✅ Unban support
- ✅ Player session data handling with DataStore
- ✅ Auto-kicks banned players
- ✅ Discord webhook logging (with avatars)
- ✅ Data reconciliation from a ban data template
- ✅ Robust error handling and retry logic

---

## 🧱 Data Structure

```lua
{
	IsBanned = false,
	Reason = "",
	Duration = 0,
	BanTime = 0,
	BannedBy = 0
}
```

---

## ⚙️ Setup Instructions

- **put code inside a module script inside ServerScriptService**

- **make a folder named "Libs" inside the module script**

- get the WebhookService module from luascapes discord server **https://discord.gg/hzxbz89MGW**

- **put the module inside the libs folder and name it "WebhookService"**

- **create a module script inside "BanService" module and name it "BanDataTemplate" put the BanDataTemplate Default data table code inside it**

- **Now lastly just require the module thats how you get the module to run look below for the example scripts**

The service automatically handles saving/loading on player join/leave.


## Example Scripts

**Script to run BanService and setup the webhook**

```lua
local BanService = require(Path.To.Module) -- put the module in ServerScriptService -- this is all you need to set it up

BanService:CreateWebhook("WEBHOOK_URL") -- Optional this is just to create the webhook
```

**Example BanDataTemplate | Note it should be a module script that is a child of BanService named "BanDataTemplate"**

```lua
return {
	IsBanned = false,
	Reason = "",
	Duration = 0,
	BanTime = 0, 
	BannedBy = 0,
}

-- Note if u change the data here and you want to change something with how they ban or remove something you will have to change the banservice functions slightly
```

---

## 📘 API Reference
```lua
BanService:CreateWebhook(WebhookURL: string): Webhook
```
**Initializes a global webhook instance to log bans to a Discord webhook and returns the webhook so you can send your own messages using luascapes webhookservice methods.**

```lua
BanService:GetBanData(Player: Player): table?
```
**Gets the in-session ban data for a player.**

```lua
BanService:GetBanDataOffline(UserId: number): table?
```
**Loads a player’s ban data from DataStore, for offline moderation.**

```lua
BanService:Ban(Player: Player, Reason: string, Duration: number|string, ModeratorUserId?: number)
```
**Bans an online player, saves the data, and kicks them with a message.**

**Duration can be a number (seconds) or "INF" for permanent.**
```lua
BanService:Unban(Player: Player)
```
**Unbans an online player by resetting their ban data.**
```lua
BanService:BanOffline(UserId: number, Reason: string, Duration: number|string, ModeratorUserId?: number)
```
**Bans a player who is not in the server using UpdateAsync.**
```lua
BanService:UnbanOffline(UserId: number)
```
**Unbans an offline player by resetting their DataStore entry.**
```lua
BanService:IsPlayerBanned(UserId: number): boolean
```
**Checks whether a player's ban is still active.**

## 📥 Internal Functions
These are inside the module and automatically handled.
```lua
ModuleFunctions.LoadPlayerData(player)

ModuleFunctions.SavePlayerData(player)

ModuleFunctions.GetPlayerHeadShotURL(userId)

ModuleFunctions.WaitForRequestBudget(requestType)

ModuleFunctions.OnPlayerAdded(player)
```

## 🧪 Example Usage
```lua
local BanService = require(ServerScriptService.BanService)

BanService:CreateWebhook("Webhook_URL")

-- Ban a player
BanService:Ban(player, "Toxic behavior", "INF", moderator.UserId)

-- Offline ban
BanService:BanOffline(12345678, "Exploiting", 86400, 87654321)

-- Check if a player is banned
if BanService:IsPlayerBanned(12345678) then
	print("This user is banned.")
end
```
---

## 📎 Dependencies
**BanDataTemplate (ModuleScript with default ban data)**

**WebhookService (custom module for Discord webhooks)** -- from luascapes discord server

**HttpService, Players, DataStoreService**

