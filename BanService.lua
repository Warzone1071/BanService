--███╗░░░███╗░█████╗░██████╗░███████╗  ██████╗░██╗░░░██╗
--████╗░████║██╔══██╗██╔══██╗██╔════╝  ██╔══██╗╚██╗░██╔╝
--██╔████╔██║███████║██║░░██║█████╗░░  ██████╦╝░╚████╔╝░
--██║╚██╔╝██║██╔══██║██║░░██║██╔══╝░░  ██╔══██╗░░╚██╔╝░░
--██║░╚═╝░██║██║░░██║██████╔╝███████╗  ██████╦╝░░░██║░░░
--╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝  ╚═════╝░░░░╚═╝░░░

--██████╗░██████╗░░█████╗░░██████╗░░█████╗░███╗░░██╗██████╗░██████╗░██████╗░██████╗░██████╗░
--██╔══██╗██╔══██╗██╔══██╗██╔════╝░██╔══██╗████╗░██║╚════██╗╚════██╗╚════██╗╚════██╗╚════██╗
--██║░░██║██████╔╝███████║██║░░██╗░██║░░██║██╔██╗██║░█████╔╝░█████╔╝░░███╔═╝░█████╔╝░█████╔╝
--██║░░██║██╔══██╗██╔══██║██║░░╚██╗██║░░██║██║╚████║░╚═══██╗░╚═══██╗██╔══╝░░░╚═══██╗░╚═══██╗
--██████╔╝██║░░██║██║░░██║╚██████╔╝╚█████╔╝██║░╚███║██████╔╝██████╔╝███████╗██████╔╝██████╔╝
--╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚═════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░╚═════╝░╚══════╝╚═════╝░╚═════╝░

-- [[ Services ]] --
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

-- [[ Modules ]] --
local BanDataTemplate = require(script:FindFirstChild("BanDataTemplate"))
local WebhookService = require(script:FindFirstChild("Libs").WebhookService)
local BanTypes = require(script:FindFirstChild("Types"))

-- [[ Types ]] --
type BanData = BanTypes.BanData
type BanType = BanTypes.BanType
type UnbanType = BanTypes.UnbanType
type WebhookObject = BanTypes.WebhookObject
type MessageType = BanTypes.MessageType

-- [[ DataStore ]] --
local DataStoreName: string = nil

if RunService:IsStudio() then
	DataStoreName = "BanDataStore_Test-".. script:GetAttribute("DataStoreVersion")
	print(DataStoreName)
else
	DataStoreName = "BanDataStore-".. script:GetAttribute("DataStoreVersion")
end

local BanDataStore = DataStoreService:GetDataStore(DataStoreName)

-- [[ Variables ]] --
local WebhookGlobal = nil
local HasUsedWebhookFunction = false
local DatastoreRequestUsed = 0
local SendPrintMessages = false -- if false then wont print anything
local SendWarnMessages = true

-- [[ Tables ]] --
local Internal = {}
local BanService = {}
local ValidBanType = {
	globalban = { Name = "globalban" },
	ban = { Name = "ban" },
	offlineban = { Name = "offlineban" }
}

-- MethodsCompleted
--Webhook
--GetBanData
--Ban
--Unban kind of still a little mor estuf to do
-- idk what other methods i should add

-- [[ Methods ]] --
function BanService:Webhook(WebhookURL: string): WebhookObject? -- you could use Webhook. for methods and functions or Webhook: but it wont be auto typed for you
	if HasUsedWebhookFunction then
		return WebhookGlobal
	end

	local ID: string?, Token: string? = WebhookService.separateWebhook(WebhookURL)
	if ID and Token then
		WebhookGlobal = WebhookService.new(ID, Token)
		HasUsedWebhookFunction = true
		Internal.SendMessage("Successfully created webhook", "print")
		return WebhookGlobal
	else
		Internal.SendMessage("Invalid Webhook URL", "warn")
		return nil
	end
end

function BanService:GetBanData(UserID: number): BanData?
	local attempts = 0
	local maxAttempts = 5
	local data
	local success, result

	repeat
		success, result = Internal.TrackDataStoreRequest(Enum.DataStoreRequestType.GetAsync, function()
			return BanDataStore:GetAsync(UserID)
		end)

		if not success then
			attempts += 1
			Internal.SendMessage("Error getting ban data for UserID " .. UserID .. ". Attempt " .. attempts .. "/" .. maxAttempts .. ": " .. tostring(result), "warn")
			task.wait(1)
		end
	until success or attempts >= maxAttempts

	if not success then
		Internal.SendMessage("Failed to retrieve ban data for UserID " .. UserID .. " after multiple attempts", "warn")
		return nil
	end

	data = result

	if data == nil then
		data = table.clone(BanDataTemplate)
		Internal.SendMessage("Data was nil so gave player the default data!", "warn")
	else
		data = Internal.ReconcileData(data, BanDataTemplate)
		Internal.SendMessage("Reconciling Data!", "print")
	end

	return data
end

function BanService:Ban(BanType: BanType, UserId: number, reason: string, duration: string | number, ModeratorUserID: number?): boolean
	if not Internal.BanArgChecks(BanType, reason, duration, ModeratorUserID) then
		Internal.SendMessage("Ban failed due to invalid arguments", "warn")
		return false
	end

	local FinalDuration = tonumber(duration) or 0
	if typeof(duration) == "string" then
		FinalDuration = string.lower(duration)
	end

	local LoweredBanType = string.lower(BanType)
	local Data: BanData? = self:GetBanData(UserId)

	if not Data then return false end

	if LoweredBanType == "globalban" then
		local success, err = pcall(function()
			MessagingService:PublishAsync("GlobalBan", {
				Topic = "GlobalBan",
				UserID = UserId,
				Reason = reason,
				Duration = FinalDuration,
				ModeratorUserId = ModeratorUserID or 0,
				BanTime = os.time(),
			})
		end)

		if not success then
			Internal.SendMessage("Failed to publish global ban message: " .. tostring(err), "warn")
			return false
		end

		Internal.SendMessage("Global ban message sent for UserID: " .. tostring(UserId), "print")
		return true

	elseif LoweredBanType == "ban" then
		local Player = Players:GetPlayerByUserId(UserId)

		Data.IsBanned = true
		Data.Reason = reason

		if FinalDuration == "inf" then
			Data.Duration = math.huge
		else
			Data.Duration = tonumber(duration) or 0
		end

		Data.BanTime = os.time()
		Data.BannedBy = ModeratorUserID or 0

		local msg = "You have been banned by UserID " .. tostring(Data.BannedBy) ..
			"\nReason: " .. tostring(Data.Reason) ..
			"\nDuration: " .. Internal.FormatNumber(Data.Duration)

		Internal.SavePlayerData(Player, Data)
		Player:Kick(msg)

		if WebhookGlobal then
			local HeadShotURL = Internal.GetPlayerHeadShotURL(Player.UserId) or ""
			pcall(function()
				WebhookGlobal:createEmbed(
					"🔨 Player Banned",
					"Player **[" .. Player.Name .. "](https://www.roblox.com/users/" .. Player.UserId .. "/profile)** (`" .. Player.UserId .. "`) was banned.",
					{
						{ name = "Reason", value = reason, inline = false },
						{ name = "Duration", value = Internal.FormatNumber(Data.Duration), inline = true },
						{ name = "Moderator UserId", value = tostring(Data.BannedBy), inline = true },
						{ name = "Time", value = os.date("%Y-%m-%d %H:%M:%S", Data.BanTime), inline = false },
					},
					HeadShotURL
				)
			end)

			Internal.SendMessage("Succesfully Banned Player: ".. Player.Name, "print", Data)
			return true
		else
			Internal.SendMessage("Failed to get ban data for player: " .. tostring(Player.Name), "warn")
			return false
		end

	else

		if Internal.IsPlayerInGame(UserId) then
			Internal.SendMessage("Player might be online. proceeding offline ban anyway.", "warn")
		end

		local DataDuration = nil

		local successUpdate, err = Internal.TrackDataStoreRequest(Enum.DataStoreRequestType.UpdateAsync, function()
			return BanDataStore:UpdateAsync(UserId, function(previous)
				local data = Internal.ReconcileData(previous or {}, BanDataTemplate)

				data.IsBanned = true
				data.Reason = reason
				data.Duration = (FinalDuration == "inf") and math.huge or tonumber(duration) or 0
				data.BanTime = os.time()
				data.BannedBy = ModeratorUserID or 0

				DataDuration = data.Duration
				Internal.SendMessage("Ban Data: ".. Data, "print")
				return data
			end)
		end)

		if not successUpdate then
			Internal.SendMessage("Failed to ban offline player " .. tostring(UserId) .. ": " .. tostring(err), "warn")
			return false
		end

		if WebhookGlobal then
			local HeadShotURL = Internal.GetPlayerHeadShotURL(UserId) or ""
			pcall(function()
				WebhookGlobal:createEmbed(
					"🔨 Offline Player Banned",
					"Offline UserId [`" .. UserId .. "`](https://www.roblox.com/users/" .. UserId .. "/profile) was banned.",
					{
						{ name = "Reason", value = reason, inline = false },
						{ name = "Duration", value = Internal.FormatNumber(DataDuration), inline = true },
						{ name = "Moderator UserId", value = tostring(ModeratorUserID or 0), inline = true },
						{ name = "Time", value = os.date("%Y-%m-%d %H:%M:%S", os.time()), inline = false },
					},
					HeadShotURL
				)
			end)
		end

		local successName, nameOrError = pcall(function()
			return Players:GetNameFromUserIdAsync(UserId)
		end)

		if successName then
			Internal.SendMessage("Successfully Banned: " .. nameOrError, "print")
		else
			Internal.SendMessage("Name lookup failed for UserId " .. UserId .. ": " .. tostring(nameOrError), "warn")
		end

		return true
	end
end

function BanService:Unban(UserID: number): boolean
	local success, err = Internal.TrackDataStoreRequest(Enum.DataStoreRequestType.UpdateAsync, function()
		return BanDataStore:UpdateAsync(UserID, function(previous)
			local data = Internal.ReconcileData(previous or {}, BanDataTemplate)

			data.IsBanned = false
			data.Reason = ""
			data.Duration = 0
			data.BanTime = 0
			data.BannedBy = 0

			return data
		end)
	end)

	if not success then
		Internal.SendMessage("Failed to unban offline player " .. tostring(UserID) .. ": " .. tostring(err), "warn")
		return false
	end

	local successName, nameOrError = pcall(function()
		return Players:GetNameFromUserIdAsync(UserID)
	end)

	if successName then
		Internal.SendMessage("Successfully Unbanned: " .. nameOrError, "print")
	else
		Internal.SendMessage("Name lookup failed for UserId " .. UserID .. ": " .. tostring(nameOrError), "warn")
	end

	return true
end

function BanService:IsPlayerBanned(userId: number): boolean
	local success, data = Internal.TrackDataStoreRequest(Enum.DataStoreRequestType.GetAsync, function()
		return BanDataStore:GetAsync(userId)
	end)

	if not success then
		Internal.SendMessage("Failed to check ban status for UserId " .. tostring(userId), "warn")
		return false
	end

	if not data or not data.IsBanned then
		Internal.SendMessage("No data or data issue!", "warn")
		return false
	end

	if data.Duration == math.huge then
		return true
	end

	local banEndTime = (data.BanTime or 0) + (data.Duration or 0)
	local now = os.time()

	return data.IsBanned == true and now < banEndTime
end

-- [[ Internal Functions ]] --
function Internal.TrackDataStoreRequest(requestType: Enum.DataStoreRequestType, action: () -> any): (boolean, any)
	local callingLine = debug.info(2, "l")
	local callingFunc = debug.info(2, "n") or "Anonymous"
	local callingScript = tostring(debug.info(2, "s"))

	Internal.SendMessage(
		string.format("DataStore Request: %s | Called from [%s] line %s in %s", requestType.Name, callingFunc, callingLine, callingScript),
		"print"
	)

	Internal.WaitForRequestBudget(requestType)

	local success, result = pcall(action)
	if not success then
		Internal.SendMessage("DataStore Request Failed: " .. tostring(result), "warn")
	end

	DatastoreRequestUsed += 1
	return success, result
end

function Internal.MessageRecieved(message): boolean
	local Data = message["Data"]
	if not Data then return false end

	local Topic: string = Data["Topic"]

	if Topic == "GlobalBan" then
		local UserID: number = Data["UserID"]
		local reason: string = Data["Reason"]
		local duration: string | number = Data["Duration"]
		local moderatorUserId: number = Data["ModeratorUserID"]
		local BanTime = Data["BanTime"]

		local player = Players:GetPlayerByUserId(UserID)
		if player then
			Internal.SendMessage("Found Player", "print")
			BanService:Ban("Ban", UserID, reason, duration, moderatorUserId)
		end
	end
end

function Internal.IsPlayerInGame(UserID: number): boolean
	local success, placeId, instanceId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(UserID)
	end)

	if success and placeId and instanceId then
		return true
	else
		return false
	end
end

function Internal.SendMessage(Message: string, Type: MessageType, Table: BanData?): ()
	local StringLowered = string.lower(Type)

	if StringLowered == "warn" then
		if SendWarnMessages then
			warn("[BanService] " .. tostring(Message))
			if Table then
				warn("DataTable: ", Table)
			end
		end
	elseif StringLowered == "print" then
		if SendPrintMessages then
			print("[BanService] " .. tostring(Message))
			if Table then
				print("DataTable: ", Table)
			end
		end
	else
		warn("Invalid Type")
	end
end

function Internal.BanArgChecks(BanType: string, reason: string, duration: string | number, ModeratorUserID: number?): boolean
	if not duration then
		return false
	end

	if typeof(duration) == "string" then
		local lowerDuration = string.lower(duration)

		if lowerDuration ~= "inf" then
			Internal.SendMessage("Invalid duration for offline ban: " .. tostring(duration), "warn")
			return false
		end
	end

	if typeof(duration) == "number" then
		if duration < 0 then
			Internal.SendMessage("Duration cannot be negative", "warn")
			return false
		end
	end

	if typeof(reason) ~= "string" then
		Internal.SendMessage("Invalid reason type", "warn")
		return false
	end

	if typeof(BanType) ~= "string" then
		Internal.SendMessage("Invalid bantype", "warn")
		return false
	end

	if ModeratorUserID and typeof(ModeratorUserID) ~= "number" then
		Internal.SendMessage("Invalid moderatorUserId type", "warn")
		return false
	end

	local LowercasedBanType = string.lower(BanType)

	if not ValidBanType[LowercasedBanType] then
		Internal.SendMessage("Invalid ban type: " .. tostring(LowercasedBanType), "warn")
		return false
	end

	return true
end


function Internal.FormatNumber(value: number): string
	if not value or typeof(value) ~= "number" then
		return "N/A"
	end

	if value == math.huge then
		return "Permanent"
	end

	local days = math.floor(value / 86400)
	local hours = math.floor((value % 86400) / 3600)
	local minutes = math.floor((value % 3600) / 60)
	local seconds = value % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end

	if hours > 0 or #parts > 0 then
		table.insert(parts, hours .. "h")
	end
	if minutes > 0 or #parts > 0 then
		table.insert(parts, minutes .. "m")
	end

	table.insert(parts, seconds .. "s")

	return table.concat(parts, " ")
end
-- I changed it to any and BanData
--function Internal.ReconcileData(data: {}, template: BanData) idk if i should use the BanDataTemplate Type or BanData so its a empty table
function Internal.ReconcileData(data: any, template: BanData): BanData
	for key, value in pairs(template) do
		if data[key] == nil then
			if typeof(value) == "table" then
				data[key] = table.clone(value)
			else
				data[key] = value
			end
		end
	end
	return data
end

function Internal.GetPlayerHeadShotURL(UserID: number, Size: string?): string?
	Size = Size or "420x420"
	local apiUrl = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. UserID .. "&size=" .. Size .. "&format=Png&isCircular=false"

	local success, result = pcall(function()
		local response = HttpService:GetAsync(apiUrl)
		return HttpService:JSONDecode(response)
	end)

	if success and result and result.data and result.data[1] and result.data[1].imageUrl then
		return result.data[1].imageUrl
	else
		Internal.SendMessage("Failed to get headshot URL: " .. tostring(result), "warn")
		return nil
	end
end

function Internal.WaitForRequestBudget(RequestType: Enum.DataStoreRequestType)
	local CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)

	while CurrentBudget < 1 do
		task.wait(1)
		CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
	end
end

function Internal.SavePlayerData(player: Player, data: BanData): boolean -- to reduce datastore calls i added the data argument
	local key = player.UserId
	local attempts = 0
	local maxAttempts = 5
	local success, err

	repeat
		success, err = Internal.TrackDataStoreRequest(Enum.DataStoreRequestType.UpdateAsync, function()
			return BanDataStore:UpdateAsync(key, function(previous)
				local merged = Internal.ReconcileData(previous or {}, BanDataTemplate)
				for k, v in pairs(data) do
					merged[k] = v
				end
				return merged
			end)
		end)

		if not success then
			attempts += 1
			Internal.SendMessage("Error saving data for " .. player.Name .. ". Attempt " .. attempts .. "/" .. maxAttempts .. ": " .. tostring(err), "warn")
			task.wait(1)
		end
	until success or attempts >= maxAttempts

	if not success then
		Internal.SendMessage("Failed to save ban data for " .. player.Name .. ": " .. tostring(err), "warn")
		return false
	end

	return true
end

function Internal.OnPlayerLeave(player: Player): ()
	local data = BanService:GetBanData(player.UserId)
	if data then
		Internal.SavePlayerData(player, data)
		Internal.SendMessage("DataStoreRequestsMade: ".. tostring(DatastoreRequestUsed), "print")
	else
		Internal.SendMessage("No ban data to save for player: " .. player.Name, "warn")
	end
end

function Internal.OnPlayerAdded(player: Player): ()
	local data = BanService:GetBanData(player.UserId)

	if data then
		local now = os.time()
		local banEndTime = (data.BanTime or 0) + (data.Duration or 0)
		local expired = data.IsBanned
			and typeof(data.Duration) == "number"
			and typeof(data.BanTime) == "number"
			and data.Duration ~= math.huge
			and now >= banEndTime

		if expired then
			data.IsBanned = false
			data.Reason = ""
			data.Duration = 0
			data.BanTime = 0
			data.BannedBy = 0

			local saveSuccess = Internal.SavePlayerData(player, data)

			if saveSuccess then
				print(data)
				Internal.SendMessage("Auto-unbanned: " .. player.Name, "print")
			end
		end

		Internal.SendMessage("Load success for " .. player.Name, "print")

		if data.IsBanned then
			local msg = "You have been banned by UserID " .. tostring(data.BannedBy or 0) ..
				"\nReason: " .. tostring(data.Reason) ..
				"\nDuration: " .. Internal.FormatNumber(data.Duration)
			player:Kick(msg)
		end
	else
		Internal.SendMessage("Failed to load data for " .. player.Name, "warn")
	end
end

-- [[ Events ]] --
Players.PlayerAdded:Connect(Internal.OnPlayerAdded)
Players.PlayerRemoving:Connect(Internal.OnPlayerLeave)

game:BindToClose(function()
	if not RunService:IsStudio() then
		for _, player in ipairs(Players:GetPlayers()) do
			local success, err = pcall(function()
				Internal.SavePlayerData(player)
			end)

			if not success then
				Internal.SendMessage("Error saving data on shutdown for " .. player.Name .. ": " .. tostring(err), "warn")
			end

			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	local success, err = pcall(function()
		MessagingService:SubscribeAsync("GlobalBan", Internal.MessageRecieved)
	end)

	if not success then
		warn("[BanService] Failed to subscribe to GlobalBan: " .. tostring(err))
	end
end)

-- There was too many bugs in this right after another i would fix one find another and then find a huge bug that caused me to change my
-- whole system this took too long to make and it probably has a bug or logic bug so its not the best still need to fix
-- a couple of stuff

Internal.SendMessage("BanService Running", "print")
Internal.SendMessage("Created By Dragon33233", "print")
return BanService
