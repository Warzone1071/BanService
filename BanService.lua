-- [[ Services ]] --
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- [[ Modules ]] --
local BanDataStore = DataStoreService:GetDataStore("BanDataStore")
local BanDataTemplate = require(script:FindFirstChild("BanDataTemplate"))
local WebhookService = require(script:FindFirstChild("Libs").WebhookService)

-- [[ Variables ]] --
local WebhookGlobal = nil

-- [[ Tables ]] --
local SessionData = {}
local ModuleFunctions = {}
local BanService = {}

-- Note: Use this once or else it might break
function BanService:CreateWebhook(WebhookURL: string)
	local ID, Token = WebhookService.separateWebhook(WebhookURL)
	if ID and Token then
		WebhookGlobal = WebhookService.new(ID, Token)
		return WebhookGlobal
	else
		error("[BanService] Invalid Webhook URL")
	end
end

function BanService:GetBanData(Player: Player)
	return SessionData[Player]
end

function BanService:GetBanDataOffline(UserID: number)
	ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
	local success, data = pcall(function()
		return BanDataStore:GetAsync(UserID)
	end)

	if success then
		return data
	else
		warn("[BanService] Failed to load offline ban data for UserID " .. tostring(UserID) .. ": " .. tostring(data))
		return nil
	end
end

local function ReconcileData(data, template)
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

function BanService:Ban(player: Player, reason: string, duration, moderatorUserId: number?)
	local data = self:GetBanData(player)

	if data == nil then
		warn("[BanService] Cannot ban, data not found for " .. player.Name)
		return
	end

	data.IsBanned = true
	data.Reason = reason
	if duration == "INF" then
		data.Duration = math.huge
	else
		data.Duration = tonumber(duration) or 0
	end
	data.BanTime = os.time()
	data.BannedBy = moderatorUserId or 0

	local msg = "You have been banned by UserID " .. tostring(data.BannedBy) ..
		"\nReason: " .. tostring(data.Reason) ..
		"\nDuration: " .. tostring(data.Duration) .. " seconds."
	player:Kick(msg)

	if WebhookGlobal then
		local HeadShotURL = ModuleFunctions.GetPlayerHeadShotURL(player.UserId)
		WebhookGlobal:createEmbed(
			"?? Player Banned",
			"Player **[" .. player.Name .. "](https://www.roblox.com/users/" .. player.UserId .. "/profile)** (`" .. player.UserId .. "`) was banned.",
			{
				{ name = "Reason", value = reason, inline = false },
				{ name = "Duration", value = tostring(data.Duration), inline = true },
				{ name = "Moderator UserId", value = tostring(data.BannedBy), inline = true },
				{ name = "Time", value = os.date("%Y-%m-%d %H:%M:%S", data.BanTime), inline = false },
			},
			HeadShotURL
		)
	end
end

function BanService:Unban(player: Player)
	local data = self:GetBanData(player)

	if data == nil then
		warn("[BanService] Cannot unban, data not found for " .. player.Name)
		return
	end

	data.IsBanned = false
	data.Reason = ""
	data.Duration = 0
	data.BanTime = 0
	data.BannedBy = 0
end

function BanService:BanOffline(userId: number, reason: string, duration, moderatorUserId: number?)
	ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
	local success, err = pcall(function()
		BanDataStore:UpdateAsync(userId, function(previous)
			local data = previous or table.clone(BanDataTemplate)

			data.IsBanned = true
			data.Reason = reason
			if duration == "INF" then
				data.Duration = math.huge
			else
				data.Duration = tonumber(duration) or 0
			end
			data.BanTime = os.time()
			data.BannedBy = moderatorUserId or 0

			return data
		end)
	end)

	if not success then
		warn("[BanService] Failed to ban offline player " .. tostring(userId) .. ": " .. tostring(err))
	else
		if WebhookGlobal then
			local HeadShotURL = ModuleFunctions.GetPlayerHeadShotURL(userId)
			WebhookGlobal:createEmbed(
				"?? Offline Player Banned",
				"Offline UserId [`" .. userId .. "`](https://www.roblox.com/users/" .. userId .. "/profile) was banned.",
				{
					{ name = "Reason", value = reason, inline = false },
					{ name = "Duration", value = tostring(duration), inline = true },
					{ name = "Moderator UserId", value = tostring(moderatorUserId or 0), inline = true },
					{ name = "Time", value = os.date("%Y-%m-%d %H:%M:%S", os.time()), inline = false },
				},
				HeadShotURL
			)
		end
	end
end

function BanService:UnbanOffline(userId: number)
	ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
	local success, err = pcall(function()
		BanDataStore:UpdateAsync(userId, function(previous)
			local data = previous or table.clone(BanDataTemplate)

			data.IsBanned = false
			data.Reason = ""
			data.Duration = 0
			data.BanTime = 0
			data.BannedBy = 0

			return data
		end)
	end)

	if not success then
		warn("[BanService] Failed to unban offline player " .. tostring(userId) .. ": " .. tostring(err))
	end
end

function BanService:IsPlayerBanned(userId: number): boolean
	ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
	local success, data = pcall(function()
		return BanDataStore:GetAsync(userId)
	end)

	if not success then
		warn("[BanService] Failed to check ban status for UserId " .. tostring(userId))
		return false
	end

	if not data or not data.IsBanned then
		return false
	end

	local banEndTime = (data.BanTime or 0) + (data.Duration or 0)
	local now = os.time()

	return data.IsBanned == true and now < banEndTime
end

-- [[ Script Functions ]] --

function ModuleFunctions.GetPlayerHeadShotURL(UserID: number, Size: string?): string?
	Size = Size or "420x420"
	local apiUrl = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. UserID .. "&size=" .. Size .. "&format=Png&isCircular=false"

	local success, result = pcall(function()
		local response = HttpService:GetAsync(apiUrl)
		return HttpService:JSONDecode(response)
	end)

	if success and result and result.data and result.data[1] and result.data[1].imageUrl then
		return result.data[1].imageUrl
	else
		warn("[BanService] Failed to get headshot URL:", result)
		return nil
	end
end

function ModuleFunctions.WaitForRequestBudget(RequestType: Enum.DataStoreRequestType)
	local CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)

	while CurrentBudget < 1 do
		task.wait(2)
		CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
	end
end

function ModuleFunctions.LoadPlayerData(player: Player)
	local key = player.UserId
	local data
	local success, err
	local attempts = 0
	local maxAttempts = 5

	repeat
		ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
		success, err = pcall(function()
			data = BanDataStore:GetAsync(key)
		end)

		if not success then
			attempts += 1
			warn("[BanService] Error loading data for " .. player.Name .. ". Attempt " .. attempts .. "/" .. maxAttempts .. ": " .. tostring(err))
			task.wait(1)
		end
	until success or attempts >= maxAttempts or not Players:FindFirstChild(player.Name)

	if not success then
		player:Kick("Failed to load data. Please rejoin or contact support. Error: " .. tostring(err))
		return false
	end

	if data == nil then
		data = table.clone(BanDataTemplate)
	else
		data = ReconcileData(data, BanDataTemplate)
	end

	local now = os.time()
	local banEndTime = (data.BanTime or 0) + (data.Duration or 0)

	if data.IsBanned and now >= banEndTime then
		data.IsBanned = false
		data.Reason = ""
		data.Duration = 0
		data.BanTime = 0
		data.BannedBy = 0
	end

	SessionData[player] = data
	return true
end

function ModuleFunctions.SavePlayerData(player: Player)
	local key = player.UserId
	local data = BanService:GetBanData(player)

	if data == nil then
		warn("[BanService] No data to save for " .. player.Name)
		return
	end

	local success, err
	local attempts = 0
	local maxAttempts = 5

	repeat
		ModuleFunctions.WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
		success, err = pcall(function()
			BanDataStore:UpdateAsync(key, function()
				return data
			end)
		end)

		if not success then
			attempts += 1
			warn("[BanService] Error saving data for " .. player.Name .. ". Attempt " .. attempts .. "/" .. maxAttempts .. ": " .. tostring(err))
			task.wait(1)
		end
	until success or attempts >= maxAttempts

	if not success then
		warn("[BanService] Failed to save ban data for " .. player.Name .. ": " .. tostring(err))
	end

	SessionData[player] = nil
end

function ModuleFunctions.OnPlayerAdded(player: Player)
	local success = ModuleFunctions.LoadPlayerData(player)

	if success then
		local data = BanService:GetBanData(player)
		if data and data.IsBanned then
			local msg = "You have been banned by UserID " .. tostring(data.BannedBy or 0) ..
				"\nReason: " .. tostring(data.Reason) ..
				"\nDuration: " .. tostring(data.Duration) .. " seconds."
			player:Kick(msg)
		end
	end
end

-- [[ Events ]] --
Players.PlayerAdded:Connect(ModuleFunctions.OnPlayerAdded)
Players.PlayerRemoving:Connect(ModuleFunctions.SavePlayerData)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local success, err = pcall(function()
			ModuleFunctions.SavePlayerData(player)
		end)

		if not success then
			warn("[BanService] Error saving data on shutdown for " .. player.Name .. ": " .. tostring(err))
		end

		task.wait(0.1)
	end
end)

return BanService
