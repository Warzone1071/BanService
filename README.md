# 🔨 BanService

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

⚙️ Setup Instructions
Require the BanService module in a server script.

Add your BanDataTemplate module.

(Optional) Use BanService:CreateWebhook to log bans to Discord.

The service automatically handles saving/loading on player join/leave.

📘 API Reference
BanService:CreateWebhook(WebhookURL: string): Webhook
Initializes a global webhook instance to log bans to a Discord webhook.

BanService:GetBanData(Player: Player): table?
Gets the in-session ban data for a player.

BanService:GetBanDataOffline(UserId: number): table?
Loads a player’s ban data from DataStore, for offline moderation.

BanService:Ban(Player: Player, Reason: string, Duration: number|string, ModeratorUserId?: number)
Bans an online player, saves the data, and kicks them with a message.

Duration can be a number (seconds) or "INF" for permanent.

BanService:Unban(Player: Player)
Unbans an online player by resetting their ban data.

BanService:BanOffline(UserId: number, Reason: string, Duration: number|string, ModeratorUserId?: number)
Bans a player who is not in the server using UpdateAsync.

BanService:UnbanOffline(UserId: number)
Unbans an offline player by resetting their DataStore entry.

BanService:IsPlayerBanned(UserId: number): boolean
Checks whether a player's ban is still active.

📥 Internal Functions
These are inside the module and automatically handled.

ModuleFunctions.LoadPlayerData(player)

ModuleFunctions.SavePlayerData(player)

ModuleFunctions.GetPlayerHeadShotURL(userId)

ModuleFunctions.WaitForRequestBudget(requestType)

ModuleFunctions.OnPlayerAdded(player)

🧪 Example Usage
lua
Copy
Edit
local BanService = require(ServerScriptService.BanService)

BanService:CreateWebhook("https://discord.com/api/webhooks/WEBHOOK_ID/TOKEN")

-- Ban a player
BanService:Ban(player, "Toxic behavior", "INF", moderator.UserId)

-- Offline ban
BanService:BanOffline(12345678, "Exploiting", 86400, 87654321)

-- Check if a player is banned
if BanService:IsPlayerBanned(12345678) then
	print("This user is banned.")
end
📎 Dependencies
BanDataTemplate (ModuleScript with default ban data)

WebhookService (custom module for Discord webhooks)

HttpService, Players, DataStoreService

