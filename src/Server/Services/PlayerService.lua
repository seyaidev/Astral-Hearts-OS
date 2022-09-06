-- Player Service
-- oniich_n
-- December 19, 2018

--[[
	HOW TO LOAD EVENT DATA:
		- When a character is loading into the place from the Title Screen, the Data should already be event specified
		- CharacterId will be global instead of unique, but stored under a player
		- if the character id exists in EventData, then use that!
]]

--[[

	Server:

		PlayerService:GetPlayerData(Player)
			Returns requested Player's data with gameplay objects

		PlayerService:SavePlayer(Player)
			Sets Player data without gameplay objects to DataStore2

		PlayerService:UpdatePlayer(Player, package)
			Updates Player information with new information from package.
			Iterates through the package and only updates information found in the package

				Original data:
				{
					Munny = 200;
					...
					ToolInventory = {"old tool"}
				}

				Typical package:
				{
					Munny = 100;
					ToolInventory = {"new tool", "old tool"}
				}



	Client:

		PlayerService:GetPlayerData()
			Returns LocalPlayer's data without gameplay objects
		PlayerService:FormParty(RequestedUnits)
			Creates a party from the units requested
			Uses UniqueIds to request party

--]]



local PlayerService = {Client = {}}
PlayerService.__aeroOrder = 1
local PLAYER_ADDED_EVENT = "PLAYER_ADDED_EVENT"
local PLAYER_REMOVED_EVENT = "PLAYER_REMOVED_EVENT"
local PLAYER_CHARACTER_ADDED_EVENT = "PLAYER_CHARACTER_ADDED_EVENT"

local EQUIP_SLOT_EVENT = "EQUIP_SLOT_EVENT"
local UPDATE_BLOB_EVENT = "UpdateBlob"
local CLIENT_EFFECT_EVENT = "CLIENT_EFFECT_EVENT"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")

local DataStore2 = require(game:GetService("ServerStorage"):FindFirstChild("DataStore2", true))

local Maid = {}
local AppearanceCache = {}
local PlayerCache = {}
local Connections = {}
local HumDescCache = {}

--Data manipulation methods

function PlayerService:GetCharacter(Player)
	return Player.Character
end

function PlayerService:GetPlayerData(Player, t)
	if not Player then return end
	if t == "Appearance" then
		if typeof(Player) == "number" then
			return AppearanceCache[Player]
		end
		return AppearanceCache[Player.UserId]
	end

	if typeof(Player) == "number" then
		return PlayerCache[Player]
	end
	return PlayerCache[Player.UserId]
end

function PlayerService:SetPlayerData(Player, Data)
	PlayerCache[Player.UserId] = Data
		
	self:FireClientEvent(UPDATE_BLOB_EVENT, Player, Data)
	self:SavePlayer(Player, Data)
end

function PlayerService:GetPartial(Player, key)
	return PlayerCache[Player.UserId][key]
end

function PlayerService.Client:GetPartial(Player, key)
	return PlayerCache[Player.UserId][key]
end

function PlayerService:SetPartial(Player, key, data)
	if typeof(Player) == "number" then
		PlayerCache[Player][key] = data

		local pPlayer = game.Players:GetPlayerByUserId(Player)

		if pPlayer then
			self:FireClientEvent(UPDATE_BLOB_EVENT, pPlayer, PlayerCache[Player])
			self:SavePlayer(pPlayer, PlayerCache[Player])
		end
		return
	end

	if Player == nil then return end
	if PlayerCache[Player.UserId] then
		PlayerCache[Player.UserId][key] = data
		self:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerCache[Player.UserId])
		self:SavePlayer(Player, PlayerCache[Player.UserId])
	end
end

function PlayerService.Client:GetPlayerData(Player, t)
	if t == "Appearance" then
		return AppearanceCache[Player.UserId]
	end

	return PlayerCache[Player.UserId]
end


function PlayerService.Client:GetVault(Player)
	local EXPVaultStore = self.Server.CachedDS2[Player.UserId .. "_EXPVault"]
	if EXPVaultStore then
		return EXPVaultStore:Get()
	end

	return 0
end

--Data saving methods

function PlayerService:UpdatePlayer(Player, package)
	local PlayerData = self:GetPlayerData(Player)
	if PlayerData == nil then return end

	for key, value in pairs(package) do
		PlayerData[key] = value
	end

	PlayerCache[Player.UserId] = PlayerData
end

function PlayerService:SavePlayer(Player, PlayerData)
	PlayerData = PlayerData or self:GetPlayerData(Player) or PlayerCache[Player.UserId]
	local PlayerDataStore = self.CachedDS2[Player.UserId .. "_PlayerData"]
	local AppearanceStore = self.CachedDS2[Player.UserId .. "_Appearance"]
	local InboxStore = self.CachedDS2[Player.UserId .. "_Inbox"]
	local SkinsStore = self.CachedDS2[Player.UserId .. "_Skins"]
	
	self:FireClientEvent("SaveNotif", Player, 2) -- display save in progress

	if PlayerData and PlayerDataStore then
		PlayerData.DataId = PlayerData.DataId+1
		-- PlayerData.T = os.time()
		PlayerDataStore:Set(PlayerData)

		local Skins = SkinsStore:Get({})
		for i, v in pairs(PlayerData.Inventory) do
			if typeof(v) == "table" then
				if v.Type == "Skin" then
					if Skins[i] == nil then
						Skins[i] = v
					end
				end
			end
		end
		
		local HasSkin = {}

		for i, v in pairs(Skins) do
			if TableUtil.IndexOf(HasSkin, v.Id) or TableUtil.IndexOf(HasSkin, v.ItemId) then
				Skins[i] = nil
			else
				table.insert(HasSkin, v.Id or v.ItemId)
			end
		end
		
		-- print('E21')
		SkinsStore:Set(Skins)
	else
		self.Services.RavenService:FireEvent("RavenDebug", "Could not save data! Missing: " .. tostring(PlayerData) .. " or " .. tostring(PlayerDataStore), "Fatal")
	end

	local AppearanceData = self:GetPlayerData(Player, "Appearance")-- or AppearanceCache[Player.UserId]
	local InboxBlob = self.Services.MailService:GetBlob(Player)

	if AppearanceData and AppearanceStore then
		AppearanceStore:Set(AppearanceData)
	end

	if InboxBlob and InboxStore then
		InboxStore:Set(InboxBlob)
	end

	--check to see if cache is secure
	local CachedPD = PlayerDataStore:Get()
	if PlayerDataStore:IsBackup() then
		self:FireClientEvent("SaveNotif", Player, 0)
		local Notice = ReplicatedStorage.Assets.Interface:FindFirstChild("BackupNotice")
		if Notice == nil then return end
		FastSpawn(function()
			local NewNotice = Notice:Clone()
			NewNotice.Parent = Player:WaitForChild("PlayerGui", 3)
		end)
	end
end

local APStats = {"STR", "DEX", "LCK", "INT"}

function PlayerService.Client:DistributeAPToStat(Player, Stat)
	local PlayerData = self:GetPlayerData(Player)
	if PlayerData == nil then print("No data found for", Player) return end

	if PlayerData.Stats.AbilityPoints == nil then PlayerData.Stats.AbilityPoints = 0 end
	
	if PlayerData.Stats.AbilityPoints > 0 then

		--calculate if this stat increase is possible
		local TotalCount = 1
		for i, v in ipairs(APStats) do
			TotalCount = TotalCount+PlayerData.Stats[v]
		end

		local TotalAP = (5*(PlayerData.Stats.Level))+30

		if TotalAP < TotalCount then return end --throw error to sentry later on

		PlayerData.Stats[Stat] = PlayerData.Stats[Stat] + 1
		PlayerData.Stats.AbilityPoints = PlayerData.Stats.AbilityPoints-1

		PlayerCache[Player.UserId] = PlayerData

		wait()
		self.Server:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerData)
		return true
	end
end

function PlayerService.Client:AutoDistributeAP(Player, ClassParams)
	local PlayerData = self:GetPlayerData(Player)
	if PlayerData == nil then print("No data found for", Player) return end
	if PlayerData.Stats == nil then print("Could not find stats") return end
	
	local ClassParams = self.Server.Shared.ClassParams:Get(PlayerData.Stats.Class)

	print(PlayerData.Stats.AbilityPoints)
	if PlayerData.Stats.AbilityPoints > 0 then
		local ToPrimary = GlobalMath:round(PlayerData.Stats.AbilityPoints*0.8)
		local ToSecondary = PlayerData.Stats.AbilityPoints-ToPrimary --remainder

		--calculate if this stat increase is possible
		local TotalCount = PlayerData.Stats.AbilityPoints
		for i, v in ipairs(APStats) do
			TotalCount = TotalCount+PlayerData.Stats[v]
		end

		local TotalAP = (5*(PlayerData.Stats.Level))+30

		print(TotalAP, TotalCount)
		if TotalAP < TotalCount then return end

		PlayerData.Stats[ClassParams.PrimaryStat] = PlayerData.Stats[ClassParams.PrimaryStat] + ToPrimary
		PlayerData.Stats[ClassParams.SecondaryStat] = PlayerData.Stats[ClassParams.SecondaryStat] + ToSecondary
		PlayerData.Stats.AbilityPoints = 0

		PlayerCache[Player.UserId] = PlayerData
		wait()
		self.Server:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerData)
		return true
	end
	return false
end

local LevelCap = 35

function PlayerService:Reward(UserId, Rewards, BaseMultiplier)
	local Player = game.Players:GetPlayerByUserId(UserId)
	if Player == nil then return end

	local PlayerData = self:GetPlayerData(UserId)
	if PlayerData == nil then print("No data found for", UserId) return end

	-- print(repr(Rewards))

	BaseMultiplier = BaseMultiplier or 1
	local IsFounder = self.Services.PerkService:IsFounder(Player)
	local IsHero = self.Services.PerkService:IsHero(Player)
	
	--change this to account for all sorts of :b:oosts
	local FinalMultiplier = BaseMultiplier
	if IsFounder then
		FinalMultiplier = FinalMultiplier+0.35
	elseif IsHero then
		FinalMultiplier = FinalMultiplier+0.2
	end

	if self.Services.PerkService:HasPerk(Player, "10Bonus") then
		FinalMultiplier = FinalMultiplier+0.1
	end

	local ClassParams = self.Shared.ClassParams:Get(PlayerData.Stats.Class)
	local function CheckLevelUp()
		if PlayerData.Stats.EXP >= GlobalData.Levels[PlayerData.Stats.Level] then
			if PlayerData.Stats.Level >= LevelCap then
				PlayerData.Stats.Level = LevelCap
				PlayerData.Stats.EXP = GlobalData.Levels[PlayerData.Stats.Level]
				return
			else
				PlayerData.Stats.EXP = PlayerData.Stats.EXP - GlobalData.Levels[PlayerData.Stats.Level]
				PlayerData.Stats.Level = PlayerData.Stats.Level+1

				PlayerData.Stats.AbilityPoints = PlayerData.Stats.AbilityPoints + 5
				PlayerData.Stats.SkillPoints = PlayerData.Stats.SkillPoints + 2

				PlayerData.Stats.ATK = FormulasModule:CalculateAttack(PlayerData)

				print(PlayerData.Stats.AbilityPoints, PlayerData.Stats.SkillPoints)

				if Player.Character then
					local NameTag = Player.Character:FindFirstChild("NameTag", true)
					if NameTag ~= nil then
						NameTag.Label.Text = Player.Name
						NameTag.PlayerToHideFrom = Player
						
						if self.Services.PerkService:IsDev(Player) then
							NameTag.Label.TextColor3 = Color3.fromRGB(255, 180, 180)
						elseif IsFounder then
							NameTag.Label.TextColor3 = Color3.fromRGB(224, 222, 104)
						elseif IsHero then
							NameTag.Label.TextColor3 = Color3.fromRGB(104, 156, 224)
						end

						NameTag.Info.Text = "Level " .. tostring(PlayerCache[Player.UserId].Stats.Level)
					end
				end

				--play level up effect
				self:FireClientEvent(CLIENT_EFFECT_EVENT, Player, "LevelUp")

				if PlayerData.Stats.EXP >= GlobalData.Levels[PlayerData.Stats.Level] then
					CheckLevelUp()
				else
					DataStore2.SaveAll(Player)
				end
			end
			return true
		end
		return false
	end
	if Rewards.EXP ~= nil then
		PlayerData.Stats.EXP = PlayerData.Stats.EXP + (GlobalMath:round(Rewards.EXP*FinalMultiplier)*2)
		CheckLevelUp()

		local EXPVaultStore = self.CachedDS2[Player.UserId .. "_EXPVault"]
		if EXPVaultStore then
			if PlayerData.Stats.Level < 35 then
				local vaultamt = GlobalMath:round((Rewards.EXP)*0.2)
				if EXPVaultStore:Get() < 5000 then
					EXPVaultStore:Increment(vaultamt)
				end
			end
		end
	end

	if Rewards.Munny ~= nil then
		PlayerData.Stats.Munny = PlayerData.Stats.Munny + GlobalMath:round(Rewards.Munny*FinalMultiplier)
	end

	self:SetPlayerData(Player, PlayerData)
	self:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerData)
end

--give Player a new item, whether it be created by a shop or from a drop
function PlayerService:GiveItem(Player, Item, IsImportant)
	local PlayerData = self:GetPlayerData(Player)
	if PlayerData == nil or Item == nil then return end

	PlayerData.Inventory[Item.UniqueId] = Item
	self:SetPartial(Player, "Inventory", PlayerData.Inventory)

	-- self:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerData)
	if IsImportant then
		local pobj = game.Players:GetPlayerByUserId(Player)
		if pobj then
			DataStore2.SaveAll(pobj)
		end
	end
	print("Got item")
	return true
end

--change the Player's munny amount
function PlayerService:UpdateMunny(UserId, Change)
	local PlayerData = self:GetPlayerData(UserId)
	if PlayerData == nil then return end

	PlayerCache[UserId].Stats.Munny = PlayerCache[UserId].Stats.Munny + Change
	return true
end

function PlayerService:SubtractCredits(Player, quantity)
	if quantity < 1 then return end
	local CreditStore = self.CachedDS2[tostring(Player.UserId) .. "_SayoCredits"]
	if CreditStore then

		local SCStore = DataStore2("SCHistory", Player)
        local SCHistory = SCStore:Get({})
		table.insert(SCHistory, -quantity)
		
		local CurrentCredits = 0
		for i,v in pairs(SCHistory) do
			if typeof(v) == "number" then
				CurrentCredits = CurrentCredits + v
			end
		end

		CreditStore:Set(CurrentCredits)
		SCStore:Set(SCHistory)
		DataStore2.SaveAll(Player)
		return true
	else
		return false
	end
end

--purchase SayoCredits for account
function PlayerService:PurchaseCredits(UserId, quantity)
	if quantity < 1 then return true end
	local CreditStore = self.CachedDS2[tostring(UserId) .. "_SayoCredits"]
	if CreditStore then
		local Player = game.Players:GetPlayerByUserId(UserId)
		if Player then
			local SCStore = DataStore2("SCHistory", Player)
			local SCHistory = SCStore:Get({})
			table.insert(SCHistory, quantity)

			local CurrentCredits = 0
			for i,v in pairs(SCHistory) do
				if typeof(v) == "number" then
					CurrentCredits = CurrentCredits + v
				end
			end

			CreditStore:Set(CurrentCredits)
			SCStore:Set(SCHistory)
			self:FireClientEvent(UPDATE_BLOB_EVENT, Player, self:GetPlayerData(UserId))
			print(tostring(UserId) .. " purchased " .. tostring(quantity) .. " SayoCredits!")
			DataStore2.SaveAll(Player)
			return true
		end
	else
		return false
	end
end

function PlayerService.Client:GetCredits(Player)
	return self.Server:GetCredits(Player)
end

function PlayerService:GetCredits(Player)
	local CreditStore = self.CachedDS2[tostring(Player.UserId) .. "_SayoCredits"]
	if CreditStore then
		return CreditStore:Get()
	end
	return 0
end

--mainly for equipping items and skills

function PlayerService:ResetStats(Player)
	local PlayerData = self:GetPlayerData(Player)
	if not PlayerData.Stats.Class then return end
	local DefaultStats = GlobalData.DefaultStats[PlayerData.Stats.Class]

	local defaultAP = 5*(PlayerData.Stats.Level-1)

	if PlayerData.Stats.AbilityPoints == defaultAP then
		self:FireClientEvent("NotifyPlayer", Player, {
			Text = "Stats are already reset";
			Time = 3;
		})

		return
	end

	PlayerData.Stats.AbilityPoints = 5*(PlayerData.Stats.Level-1)
	
	for stat, value in pairs(DefaultStats) do
		PlayerData.Stats[stat] = value
	end

	PlayerData.Stats.ATK = FormulasModule:CalculateAttack(PlayerData)


	self:SetPartial(Player, "Stats", PlayerData.Stats)
	DataStore2.SaveAll(Player)
	return true
end

local WeaponSubclass = {
	["BladeDancer"] = "Blade";
	["Reaper"] = "Scythe";
}

function PlayerService:EquipSlot(Player, Slot, UniqueId)
	local PlayerData = self:GetPlayerData(Player)
	local pBackpack = Player:WaitForChild("pBackpack")
	if PlayerData.Inventory == nil then print("Not in inventory") return false end

	if Slot == "PrimaryWeapon" or Slot == "PrimarySkin" then--or Slot == "SecondaryWeapon" then
		local TrueSlot = "PrimaryWeapon"
		local ItemData = PlayerData.Inventory[UniqueId]
		if ItemData == nil then return false end
		if ItemData["Type"] ~= "Weapon" and ItemData["Type"] ~= "Skin" then return end
		if ItemData["Subclass"] ~= WeaponSubclass[PlayerData.Stats.Class] then return end
		if ItemData["LevelReq"] then
			print(PlayerData.Stats.Level, ItemData["LevelReq"], PlayerData.Stats.Level < ItemData["LevelReq"])
			if PlayerData.Stats.Level < ItemData["LevelReq"] then
				return
			end
		end

		for i, v in pairs(pBackpack:GetChildren()) do
			if CollectionService:HasTag(v, TrueSlot) then
				v:Destroy()
			end
		end

		if Slot == "PrimaryWeapon" then
			PlayerData.Equipment[Slot] = UniqueId
			self:SetPartial(Player, "Equipment", PlayerData.Equipment)
		elseif Slot == "PrimarySkin" then
			PlayerData.Skins[Slot] = UniqueId
			self:SetPartial(Player, "Skins", PlayerData.Skins)
		end
		
		local Base = ReplicatedStorage.Assets.Weapons:FindFirstChild(ItemData.ItemId, true)
		if Base then
			local Clone = Base:Clone()
			Clone.Parent = pBackpack

			CollectionService:AddTag(Clone, TrueSlot)
			wait(0.5)
			-- self.Services.WeaponService:LoadWeapons(Player)
		end
		return true

	elseif Slot == "Head" or Slot == "UpperArmor" or Slot == "LowerArmor" then
		local ItemData = PlayerData.Inventory[UniqueId]
		if ItemData == nil then return false end
		if ItemData["Type"] ~= "Gear" and ItemData["Type"] ~= "Skin" then return end
		if ItemData["LevelReq"] then
			print(PlayerData.Stats.Level, ItemData["LevelReq"], PlayerData.Stats.Level < ItemData["LevelReq"])
			if PlayerData.Stats.Level < ItemData["LevelReq"] then
				return
			end
		end
		
		-- update the humanoid desc
		local pHumDesc = HumDescCache[Player]
		if not pHumDesc then print('wellw ell well, if it isnt bartholomew baxter') return end
		
		--check if this id is already inside the description
		local aid = self.Modules.AssetIds[ItemData.ItemId]
		if not aid then print("asset id doesnt exist") return end
		local has = pHumDesc.WaistAccessory:match("(" .. tostring(aid) .. ")")
		if has then print('found the asset id') return end

		pHumDesc.WaistAccessory = pHumDesc.WaistAccessory .. "," .. tostring(aid)
		if Player.Character then
			Player.Character.Humanoid:ApplyDescription(pHumDesc)
		end

		print("Equipped", ItemData.ItemId)
	elseif Slot == "Slot1" or Slot == "Slot2" or Slot == "Slot3" then --assume equipping to Skills
		local SkillData = PlayerData.SkillInfo[UniqueId]
		if not SkillData then return end
		if SkillData > 0 then
			PlayerData.ActiveSkills[Slot] = UniqueId
			self:SetPartial(Player, "ActiveSkills", PlayerData.ActiveSkills)
			return true
		else
			return false
		end
	end

	print("Successfully equipped", UniqueId, "to", Slot)
end

function PlayerService:UnequipSlot(Player, Slot)
	local PlayerData = self:GetPlayerData(Player)
	local pBackpack = Player:WaitForChild("pBackpack")

	if Slot == "PrimaryWeapon" then
		self:FireClientEvent("NotifyPlayer", Player, {
			Text = "Cannot unequip Primary Weapon";
			Time = 3
		})
		return
	end

	if Slot == "PrimarySkin" then
		local TrueSlot = "PrimaryWeapon"
		PlayerData.Skins[Slot] = ""
		self:SetPartial(Player, "Skins", PlayerData.Skins)

		for i, v in pairs(pBackpack:GetChildren()) do
			if CollectionService:HasTag(v, TrueSlot) then
				v:Destroy()
			end
		end
		wait()
		local ItemData = PlayerData.Inventory[PlayerData.Equipment[TrueSlot]]
		local Base = ReplicatedStorage.Assets.Weapons:FindFirstChild(ItemData.ItemId, true)
		if Base then
			local Clone = Base:Clone()
			Clone.Parent = pBackpack

			CollectionService:AddTag(Clone, TrueSlot)
			wait(0.2)
			-- self.Services.WeaponService:LoadWeapons(Player)
		end		
	elseif Slot == "Slot1" or Slot == "Slot2" or Slot == "Slot3" then
		PlayerData.ActiveSkills[Slot] = ""
		self:SetPartial(Player, "ActiveSkills", PlayerData.ActiveSkills)
	end
	return true
end

function PlayerService.Client:EquipSlot(Player, Slot, UniqueId)
	return self.Server:EquipSlot(Player, Slot, UniqueId)
end

function PlayerService.Client:UnequipSlot(Player, Slot)
	return self.Server:UnequipSlot(Player, Slot)
end

function PlayerService:UpgradeSkill(Player, SkillId)
	--check if their class can learn this skill
	--check if they are at the correct rank
	--check if they have the right amount of skill points
	--check if they can still upgrade/need to learn the skill
	local Blob = self:GetPlayerData(Player)
	local SkillInfo = SkillCache:Get(SkillId)
	if SkillInfo.Class ~= Blob.Stats.Class then return end
	if SkillInfo.Promotion < Blob.Stats.ClassPromotion then return end
	if SkillInfo.UpgradeCost > Blob.Stats.SkillPoints then return end

	if Blob.SkillInfo[SkillId] == nil then
		Blob.SkillInfo[SkillId] = 1
		Blob.Stats.SkillPoints = Blob.Stats.SkillPoints-SkillInfo.UpgradeCost
	elseif Blob.SkillInfo[SkillId] < SkillInfo.Max then
		Blob.SkillInfo[SkillId] = Blob.SkillInfo[SkillId]+1
		Blob.Stats.SkillPoints = Blob.Stats.SkillPoints-SkillInfo.UpgradeCost
	end

	self:SetPlayerData(Player, Blob)
	self:FireClientEvent(UPDATE_BLOB_EVENT, Player, Blob)
		--update damage calculator for skills
	return Blob.SkillInfo[SkillId]
end

function PlayerService.Client:UpgradeSkill(Player, SkillId)
	return self.Server:UpgradeSkill(Player, SkillId)
end

local Locations = {
	["Title"] = 1090923299;
	["Floor1"] = 2230731085;
	["Floor2"] = 4453150092;

	["Overworld"] = 3018748854;
	["FloorW"] = 4434324454;
}


function PlayerService:Teleport(Player, Location)
	-- if true then return end
	local AppearanceData = self:GetPlayerData(Player, "Appearance")
	local PlayerData = self:GetPlayerData(Player)
	self:SavePlayer(Player, PlayerData)
	DataStore2.SaveAll(Player)
	-- wait(2)
	if AppearanceData ~= nil and PlayerData ~= nil then
		delay(1.5, function()
			self:FireClientEvent("Fade", Player, "In")
			wait(0.5)
			game:GetService("TeleportService"):Teleport(Locations[Location], Player, {
				Appearance = AppearanceData;
				PlayerData = PlayerData;
			}, ReplicatedStorage:FindFirstChild("LoadingFrame", true))
		end)
	end
end

function PlayerService.Client:GetOptions(Player)
	local OptionStore = self.Server.CachedDS2[Player.UserId .. "_Options"]
	if OptionStore then
		return OptionStore:GetTable({
			AvatarAppearance = false;
			Immersive = false;
			Music = true;
			SFX = true;
		})
	end
end


--== CORE FUNCTIONALITY FOR PLAYERSERVICE ==--


function PlayerService:Start()
	local Players = game:GetService("Players")

	self:ConnectEvent("IsBackup", function(Player)
		self:FireClientEvent("SaveNotif", Player, 0)
		PlayerDataStore:ForceBackup()
		local Notice = ReplicatedStorage.Assets.Interface:FindFirstChild("BackupNotice")
		if Notice == nil then return end
		FastSpawn(function()
			local NewNotice = Notice:Clone()
			NewNotice.Parent = Player:WaitForChild("PlayerGui", 3)
		end)
	end)

	self.CachedDS2 = {}

	local Version = GlobalData.DATA_VERSION
	if game.GameId == 514087790 then
		--Version = GlobalData.TEST_VERSION
	end

	print("VERSION:", Version)

	DataStore2.Combine(Version, "EXPVault")
	DataStore2.Combine(Version, "SayoCredits")
	DataStore2.Combine(Version, "Options")
	DataStore2.Combine(Version, "Skins")
    DataStore2.Combine(Version, "SCHistory")
    DataStore2.Combine(Version, "SingleCode")

	self:ConnectClientEvent("EQUIP_SLOT_EVENT", function(Player, Slot, UniqueId)
		self:EquipSlot(Player, Slot, UniqueId)
	end)

	self:ConnectClientEvent("UPGRADE_SKILL_EVENT", function(Player, SkillId)
		self:UpgradeSkill(Player, SkillId)
	end)

	self:ConnectClientEvent("ControllerLoaded", function(Player, req)
		if req then
			if Player.Character then
				if Player.Character.PrimaryPart ~= nil then
					Player.Character.PrimaryPart.Anchored = false
					for i, v in pairs(Player.Character:GetDescendants()) do
						if v:IsA("BasePart") then
							v:SetNetworkOwner(Player)
						end
					end
				end
			end
			return
		end
		self.ReadyControllers[Player.UserId] = true
	end)

	--- change the value of a player's option
	-- @param player the player object
	-- @param okey key name of the option
	-- @param oval value for this option
	self:ConnectClientEvent("EditOption", function(player, okey, oval)
		--ensure that the key exists and that the value is a valid option type
		local OptionStore = self.CachedDS2[player.UserId .. "_Options"]
		if OptionStore then
			local theseOptions = OptionStore:Get()
			if theseOptions[okey] then
				if typeof(theseOptions[okey]) == typeof(theseOptions[okey]) then
					theseOptions[okey] = oval
					OptionStore:Set(theseOptions)
				end
			end
		end
	end)

	local function StartPlayer(Player)
		local ReplicateTimeout = 0
		-- repeat
		-- 	wait(1)
		-- 	ReplicateTimeout = ReplicateTimeout + 1
		if PlayerCache[Player.UserId] ~= nil then return end
		local JoinData = Player:GetJoinData()

		local DefaultClass = "Reaper"
		-- Process apperance based on JoinData. JoinData also used to identify character slot to load Player data from
		if JoinData["TeleportData"] ~= nil then
			if JoinData["TeleportData"]["Appearance"] == nil then
				JoinData["TeleportData"]["Appearance"] = {
					Slot = 0;

					Tone = {
						r = 255/255, g = 229/255, b = 200/255
					};
					BodyType = "m";
					Proportions = {
						Height = 0.75;
						Width = 0.25;
						Depth = 0;
						Head = 0;
					};

					Class = DefaultClass;
					Shirt = "black_BladeDancer";
					Pants = "black_BladeDancer";
					HairStyle = "Action Ponytail";
					HairColor = {
						r = 1, g = 1, b = 1
					};
				}
			end
			print("OH snap")
		else
			JoinData["TeleportData"] = {}
			JoinData["TeleportData"]["Appearance"] = {
				Slot = 0;
				CharacterId = 0;

				Tone = {
					r = 255/255, g = 229/255, b = 200/255
				};
				BodyType = "m";
				Proportions = {
					Height = 0.75;
					Width = 0.25;
					Depth = 0;
					Head = 0;
				};

				Class = DefaultClass;
				Shirt = "black_BladeDancer";
				Pants = "black_BladeDancer";
				HairStyle = "Action Ponytail";
				HairColor = {
					r = 1, g = 1, b = 1
				};
			}
			JoinData["TeleportData"]["PlayerData"] = TableUtil.Copy(GlobalData.DEFAULT_DATA)
			JoinData["TeleportData"]["PlayerData"].Stats.Class = DefaultClass
			JoinData["TeleportData"]["PlayerData"].CharacterId = JoinData["TeleportData"]["Appearance"].CharacterId

			if not RunService:IsStudio() then	
				JoinData["TeleportData"]["PlayerData"].BC = true
			end
		end

		local ce = ReplicatedStorage:FindFirstChild("CurrentEvent")
		if ce and RunService:IsStudio() then
			if ce.Value == "EH20" then
				JoinData["TeleportData"]["Appearance"] = TableUtil.Copy(self.Shared.EventData["EH20Alice"].Appearance)
				JoinData["TeleportData"]["PlayerData"] = TableUtil.Copy(self.Shared.EventData["EH20Alice"].PlayerData)
			end
		end

		local CharacterId = JoinData["TeleportData"]["Appearance"].CharacterId
		-- print(repr(JoinData["TeleportData"]))
		-- print(CharacterId)
		DataStore2.Combine(Version, CharacterId .. "_A")
		DataStore2.Combine(Version, CharacterId .. "_PD")
		DataStore2.Combine(Version, CharacterId .. "_I")

		local PlayerDataStore = DataStore2(CharacterId .. "_PD", Player)

		PlayerDataStore:BeforeInitialGet(function(serialized)
			local deserializedInventory = {}

			if serialized.Inventory then
				for i, v in pairs(serialized.Inventory) do
					if typeof(v) == "table" then
						if v.Name == nil and v.ItemId ~= nil then
							local Data = ItemLibrary[v.ItemId]

							for j, k in pairs(Data) do
								if j ~= "Stats" then
									v[j] = k
								end
							end
						end
						deserializedInventory[i] = v
					end
				end
				serialized.Inventory = deserializedInventory
			end

			if serialized.S then
				if typeof(serialized.S) == "number" then
					local deSpawn = GlobalData.Spawns[serialized.S]
					if deSpawn then
						serialized.S = deSpawn
					end
				end
			end

			--initialize instance variables
			serialized._lastHit = 0
			return serialized
		end)

		PlayerDataStore:BeforeSave(function(original)
			-- ItemId
			-- UniqueId
			local condensedInventory = {}

			if original.Inventory then
				for UniqueId, Item  in pairs(original.Inventory) do
					if typeof(Item) == "table" then
						if Item.Type ~= "Skin" then
							if typeof(Item) == "table" then
								for Index, Value in pairs(Item) do
									if Index ~= "UniqueId"
									and Index ~= "ItemId"
									and Index ~= "Stats"
									and Index ~= "Id"
									and Index ~= "Augments" then
										Item[Index] = nil
									end
								end
							end

							condensedInventory[UniqueId] = Item
						end
					end
				end

				original.Inventory = condensedInventory
			end

			if original.StarterInventory then original.StarterInventory = nil end
			if original.StarterEquipment then original.StarterEquipment = nil end

			if original.S then
				if typeof(original.S) == "string" then
					local index = TableUtil.IndexOf(GlobalData.Spawns, original.S)
					if index then
						original.S = index
					end
				end
			end

			original.DATA_VERSION = nil
			original.GAME_VERSION = GlobalData.GAME_VERSION
			original.DEFAULT_DATA = nil
			original._events = nil
			original.Levels = nil

			original.T = os.time()

			--remove instance variables from save
			original._lastHit = nil
			return original
		end)


		local AppearanceStore = DataStore2(CharacterId .. "_A", Player)
		local InboxStore = DataStore2(CharacterId .. "_I", Player)

		AppearanceStore:BeforeSave(function(original)
			original.GAME_VERSION = GlobalData.GAME_VERSION
			return original
		end)

		InboxStore:BeforeSave(function(original)
			original.GAME_VERSION = GlobalData.GAME_VERSION
			return original
		end)

		local EXPVaultStore = DataStore2("EXPVault", Player)
		local SayoCreditsStore = DataStore2("SayoCredits", Player)
		local OptionStore = DataStore2("Options", Player)
		local SkinsStore = DataStore2("Skins", Player)
		local SCHistoryStore = DataStore2("SCHistory", Player)
		local SingleCodeStore = DataStore2("SingleCode", Player)

		SkinsStore:BeforeInitialGet(function(serialized)
			local deserializedSkins = {}
			for i, v in pairs(serialized) do
				if v.Name == nil and v.ItemId ~= nil then
					local Data = ItemLibrary[v.ItemId]

					for j, k in pairs(Data) do
						if j ~= "Stats" then
							v[j] = k
						end
					end
				end
				deserializedSkins[i] = v
			end

			return deserializedSkins
		end)

		SkinsStore:BeforeSave(function(original)
			local compress = {}
			for i, Item in pairs(original) do
				if typeof(Item) == "table" then
					for Index, Value in pairs(Item) do
						if Index ~= "UniqueId" and Index ~= "ItemId" and Index ~= "Id" then
							Item[Index] = nil
						end
					end
				end

				compress[i] = Item
			end

			return compress
		end)

		PlayerDataStore:SetBackup(3)
		AppearanceStore:SetBackup(3)
		InboxStore:SetBackup(3)
		
		EXPVaultStore:SetBackup(3)
		SayoCreditsStore:SetBackup(3)
		OptionStore:SetBackup(3)
		SkinsStore:SetBackup(3)

		if PlayerDataStore:IsBackup() then
			local Notice = ReplicatedStorage.Assets.Interface:FindFirstChild("BackupNotice")
			if Notice == nil then return end
			FastSpawn(function()
				local NewNotice = Notice:Clone()
				NewNotice.Parent = Player:WaitForChild("PlayerGui", 3)
			end)
		end

		local EXPVault = EXPVaultStore:Get(0)
		local SayoCredits = SayoCreditsStore:Get(0)
		local Skins = SkinsStore:Get({})
		local SCHistory = SCHistoryStore:Get({})

		--ensure sayo credits, run back purchases if necessary
		if SayoCredits > 0 then
			if #SCHistory == 0 then
				table.insert(SCHistory, SayoCredits)
				SCHistoryStore:Set(SCHistory)
			else
				local creditHistory = 0
				for i, v in pairs(SCHistory) do
					if typeof(v) == "number" then
						creditHistory = creditHistory + v
					end
				end

				if creditHistory > SayoCredits then --last purchase didn't update properly, let them keep the credits (hopefully this doenst get exploited)
					SayoCreditsStore:Set(SayoCredits + GlobalMath:round((creditHistory-SayoCredits)*0.8))
				end
			end
		end

		self.CachedDS2[Player.UserId .. "_PlayerData"] = PlayerDataStore
		self.CachedDS2[Player.UserId .. "_Appearance"] = AppearanceStore
		self.CachedDS2[Player.UserId .. "_Inbox"] = InboxStore

		self.CachedDS2[Player.UserId .. "_EXPVault"] = EXPVaultStore
		self.CachedDS2[Player.UserId .. "_SayoCredits"] = SayoCreditsStore
		self.CachedDS2[Player.UserId .. "_Options"] = OptionStore
		self.CachedDS2[Player.UserId .. "_Skins"] = SkinsStore
		self.CachedDS2[Player.UserId .. "_SingleCode"] = SingleCodeStore

		local AppearanceData = JoinData["TeleportData"]["Appearance"]
		local DD 
		if self.Shared.EventData[AppearanceData.CharacterId] then
			DD = TableUtil.Copy(self.Shared.EventData[AppearanceData.CharacterId]).PlayerData
		else
			DD = TableUtil.Copy(GlobalData.DEFAULT_DATA)
			DD.Stats.Class = DefaultClass
		end

		local PlayerData = PlayerDataStore:GetTable(DD)
		PlayerData._lastHit = 0

		--ensure that a new character has not been created, if so then use new default data
		
		PlayerData.CharacterId = AppearanceData.CharacterId or CharacterId or "0"
		-- print("CID:", PlayerData.CharacterId)

		-- if PDSuccess and PlayerData.DataId ~= JoinData["TeleportData"]["PlayerData"].DataId then
		-- 	PlayerData = JoinData["TeleportData"]["PlayerData"]
		-- end
		local pBackpack = Instance.new("Folder")
		pBackpack.Name = "pBackpack"
		pBackpack.Parent = Player

		--delete these tables before saving
		-- PlayerData.LoadedUnits = {}
		
		PlayerData.Vulnerable = true

		--update inventory/equipment
		--equip starter items
		

		AppearanceCache[Player.UserId] = AppearanceData
		PlayerCache[Player.UserId] = PlayerData
		print("Loaded " .. Player.Name .. ": ", PlayerCache[Player.UserId])

		for i, v in pairs(SkinsStore:Get({})) do
			if PlayerData.Inventory[i] == nil then
				PlayerData.Inventory[i] = v
			end
		end

		local c = 0
		local HasFBlade = false
		local HasHSaber = false
		for i, v in pairs(PlayerData.Inventory) do
			c = c+1

			if typeof(v) == "table" then
				if v.ItemId == "FounderBlade" then
					HasFBlade = true
				end

				if v.ItemId == "HeroSaber" then
					HasHSaber = true
				end
			end
		end

		if PlayerData.DataId > 0 then
			if self.Services.PerkService:IsFounder(Player) and not HasFBlade then
				local NewItem = self.Services.ItemService:CreateItem("FounderBlade", Player)
				-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
			end

			if self.Services.PerkService:IsHero(Player) and not HasHSaber then
				local NewItem = self.Services.ItemService:CreateItem("HeroSaber", Player)
				-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
			end
			
			if c == 0 then
				local StarterId = "IronBlade"
				if PlayerData.Stats.Class == "Reaper" then
					StarterId = "IronScythe"
				end
				
				local NewItem = self.Services.ItemService:CreateItem(StarterId, Player)
				-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
				self:EquipSlot(Player, "PrimaryWeapon", NewItem.UniqueId)
			else
				self:EquipSlot(Player, "PrimaryWeapon", PlayerData.Equipment.PrimaryWeapon)
			end


		elseif PlayerData.DataId == 0 then
			--create default stats

			if PlayerData.Stats.Level == 1 then
				if PlayerData.Stats.Class == "BladeDancer" then
					PlayerData.Stats.STR = 12
					PlayerData.Stats.DEX = 5
					PlayerData.Stats.LCK = 4
					PlayerData.Stats.INT = 4
					
				elseif PlayerData.Stats.Class == "Reaper" then
					PlayerData.Stats.STR = 5
					PlayerData.Stats.DEX = 13
					PlayerData.Stats.LCK = 3
					PlayerData.Stats.INT = 4
				end
			end

			if not PlayerData.StarterEquipment then
				local StarterId = "IronBlade"
				if PlayerData.Stats.Class == "Reaper" then
					StarterId = "IronScythe"
				end
				local NewItem = self.Services.ItemService:CreateItem(StarterId, Player)
				PlayerData.Inventory[NewItem.UniqueId] = NewItem
				wait()
				self:EquipSlot(Player, "PrimaryWeapon", NewItem.UniqueId)
				print("Created starter item:", StarterId)
			else
				for Slot, ItemId in pairs(PlayerData.StarterEquipment) do
					local NewItem = self.Services.ItemService:CreateItem(ItemId, Player)
					PlayerData.Inventory[NewItem.UniqueId] = NewItem
					wait()
					self:EquipSlot(Player, Slot, NewItem.UniqueId)
					print("Created starter equipment:", ItemId)
				end
			end


			if self.Services.PerkService:IsFounder(Player) and not HasFBlade then
				local NewItem = self.Services.ItemService:CreateItem("FounderBlade", Player)
				-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
			end

			if self.Services.PerkService:IsHero(Player) and not HasHSaber then
				local NewItem = self.Services.ItemService:CreateItem("HeroSaber", Player)
				-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
			end

		
			if RunService:IsStudio() then
				PlayerData.Stats.Level = 30
				PlayerData.Stats.AbilityPoints = 5*(PlayerData.Stats.Level-1)
				PlayerData.Stats.SkillPoints = 3*(PlayerData.Stats.Level-1)
				PlayerData.Stats.Munny = 100000
				PlayerData.Stats.EXP = 0
	
				local TestItems = {
					"CellScythe", "HoloScythe", "DarkScythe", "EclipseScythe", "RunicScythe", "DeathsEmbrace", "SoulScythe", "EggScythe1-s"
				}
	
				-- local TestItems = {
				-- 	"SteelLongsword", "AetherTouch", "EtherLongsword", "Exosplitter", "Moonlight", "Elucidator", "Stormbreaker", "HeroSaber", "FounderBlade", "RealmKey", "GlacialSaber"
				-- }
	
				for i, v in ipairs(TestItems) do
					local NewItem = self.Services.ItemService:CreateItem(v, Player)
					-- PlayerData.Inventory[NewItem.UniqueId] = NewItem
				end
			end
		end
		

		--transfer skins to global inventory on save

		if not PlayerData.Skins then
			PlayerData.Skins = {
				PrimarySkin = "";
				SecondarySkin = "disabled";
				Head = "";
				UpperArmor = "";
				LowerArmor = "";
			}
		else
			if PlayerData.Skins.PrimarySkin then
				-- equip primary skin on rejoin :D
				self:EquipSlot(Player, "PrimarySkin", PlayerData.Skins.PrimarySkin)				
			end
		end
		

		wait(1)
		PlayerData.Stats.ATK = FormulasModule:CalculateAttack(PlayerData)
		self:FireClientEvent(UPDATE_BLOB_EVENT, Player, PlayerData)
		AppearanceCache[Player.UserId] = AppearanceData
		PlayerCache[Player.UserId] = PlayerData

		local Scales = {
			["Height"] = {0.85, 1.05};
			["Width"] = {0.65, 0.85};
			["Depth"] = {0.7, 0.85};
			["Head"] = {0.95, 1.05};
		}

		local Options = OptionStore:GetTable({
			AvatarAppearance = false;
			Immersive = false;
			Music = true;
			SFX = true;
		})

		local function SpawnCharacter()
			FastSpawn(function()
				if Player:FindFirstChild("ViewportClone") ~= nil then Player.ViewportClone:Destroy() end

				local SourceHumDesc = ServerStorage:WaitForChild("HumDesc"):FindFirstChild(Player.UserId)
				if not SourceHumDesc then
					SourceHumDesc = Instance.new("HumanoidDescription")
					SourceHumDesc.Name = tostring(Player.UserId)
					
					--scales
					SourceHumDesc.HeightScale = Scales["Height"][1] + (Scales["Height"][2]-Scales["Height"][1])*AppearanceData.Proportions["Height"]
					SourceHumDesc.WidthScale = Scales["Width"][1] + (Scales["Width"][2]-Scales["Width"][1])*AppearanceData.Proportions["Width"]
					SourceHumDesc.DepthScale = Scales["Depth"][1] + (Scales["Depth"][2]-Scales["Depth"][1])*AppearanceData.Proportions["Depth"]
					SourceHumDesc.HeadScale = Scales["Head"][1] + (Scales["Head"][2]-Scales["Head"][1])*AppearanceData.Proportions["Head"]
					
					local bodyColor = Color3.new(AppearanceData.Tone.r, AppearanceData.Tone.g, AppearanceData.Tone.b)
					SourceHumDesc.HeadColor = bodyColor
					SourceHumDesc.LeftArmColor = bodyColor
					SourceHumDesc.LeftLegColor = bodyColor
					SourceHumDesc.RightArmColor = bodyColor
					SourceHumDesc.RightLegColor = bodyColor
					SourceHumDesc.TorsoColor = bodyColor

					if AppearanceData.BodyType == "f" then
						SourceHumDesc.Torso = 48474356
					end

					SourceHumDesc.Shirt = self.Modules.AssetIds[AppearanceData.Shirt .. "-s"]
					SourceHumDesc.Pants = self.Modules.AssetIds[AppearanceData.Pants .. "-p"]
					SourceHumDesc.HairAccessory = self.Modules.AssetIds[AppearanceData.HairStyle]

					--==ARMOR EQUIP TEST
					-- SourceHumDesc.HatAccessory = self.Modules.AssetIds["GSHelmet"]

					-- local gstest = {
					-- 	"GSBody";
					-- 	"GSRightLowerArm";
					-- 	"GSLeftLowerArm";
					-- 	"GSLeftLowerLeg";
					-- 	"GSLeftUpperArm";
					-- 	"GSLeftUpperLeg";
					-- 	"GSLowerTorso";
					-- 	"GSRightLowerLeg";
					-- 	"GSRightUpperArm";
					-- 	"GSRightUpperLeg";
					-- }
					-- local str = ""
					-- for i, v in ipairs(gstest) do
					-- 	str = str .. self.Modules.AssetIds[v] .. ","
					-- end
					
					-- SourceHumDesc.WaistAccessory = string.sub(str, 1, string.len(str)-1)

					local Eq = {"Head", "UpperArmor", "LowerArmor"}
					local str = ""
					for i,v in ipairs(Eq) do
						if PlayerData.Equipment[v] ~= "" then
							local eid = PlayerData.Inventory[PlayerData.Equipment[v]].ItemId
							if self.Modules.AssetIds[eid] then
								-- check if a skin, else apply the default
								if PlayerData.Skins[v] then
									if self.Modules.AssetIds[PlayerData.Skins[v]] then
										str = str .. self.Modules.AssetIds[PlayerData.Skins[v]] .. ","
									end
								else
									str = str .. self.Modules.AssetIds[eid] .. ","
								end
							end
						end
					end
				
					SourceHumDesc.WaistAccessory = string.sub(str, 1, string.len(str)-1)

					SourceHumDesc.BackAccessory = 4113007932;
					SourceHumDesc.Parent = ServerStorage:FindFirstChild("HumDesc", true)
				end

				if not ce then
					if Options.AvatarAppearance and (PerkService:HasPerk(Player, "AvatarAppearance") or PerkService:IsFounder(Player) or PerkService:IsHero(Player)) then
						if SourceHumDesc then
							SourceHumDesc:Destroy()
						end

						SourceHumDesc = game.Players:GetHumanoidDescriptionFromUserId(Player.UserId)
						SourceHumDesc.Name = tostring(Player.UserId)
						SourceHumDesc.BackAccessory = SourceHumDesc.BackAccessory .. ",4113007932"
						SourceHumDesc.BodyTypeScale = math.clamp(SourceHumDesc.BodyTypeScale, 0.33, 0.575)
						SourceHumDesc.Parent = ServerStorage:FindFirstChild("HumDesc", true)
					end
				end

				local Spawn = workspace:FindFirstChild(PlayerData.S, true)
				if not Spawn then
					if workspace.Spawns:FindFirstChild("Default") then
						Spawn = workspace.Spawns:FindFirstChild("Default").Value
					end
				end
				print(Spawn, PlayerData.S)
				PlayerData.S = Spawn.Name
				Player.RespawnLocation = Spawn

				Player:LoadCharacterWithHumanoidDescription(SourceHumDesc)
				HumDescCache[Player] = SourceHumDesc

				wait()

				for i,v in ipairs(Player.Character:GetChildren()) do
					if v:IsA("BasePart") then
						PhysicsService:SetPartCollisionGroup(v, "Characters")
					end
				end

				local NewCharacter = Player.Character
				NewCharacter.Archivable = true
				-- NewCharacter:WaitForChild("Animate", 3):Destroy()
				-- NewCharacter:WaitForChild("Sound", 3):Destroy()
				if NewCharacter:FindFirstChild("Health", true) then NewCharacter:FindFirstChild("Health", true):Destroy() end
				for i, v in ipairs(ReplicatedStorage.CharacterAssets.Sounds:GetChildren()) do
					v:Clone().Parent = NewCharacter.PrimaryPart
				end

				for i, v in ipairs(NewCharacter.Head:GetChildren()) do
					if v:IsA("Sound") then v:Destroy() end
				end

				local Humanoid = NewCharacter:FindFirstChild("Humanoid", true)

				Humanoid.DisplayDistanceType = "None"
				Humanoid.HealthDisplayType = "AlwaysOff"
				Humanoid.NameDisplayDistance = 0

				local NewWW = ServerStorage:FindFirstChild("WeaponWeld"):Clone()
				NewWW.Parent = NewCharacter:WaitForChild("RightHand")
				local NewWWP = ServerStorage:FindFirstChild("WeaponWeldPART"):Clone()
				NewWWP.Name = "WeaponWeld"
				NewWWP.Parent = NewCharacter

				NewWW.Part0 = NewCharacter.RightHand
				NewWW.Part1 = NewWWP

				-- if game.PlaceId ~= 1269360362 and game.PlaceId ~= 3018748854 then
				-- 	local Light = Instance.new("PointLight")
				-- 	Light.Brightness = 1
				-- 	Light.Range = 12
				-- 	Light.Parent = NewCharacter:FindFirstChild("UpperTorso")
				-- end

				if ce or not (Options.AvatarAppearance and (PerkService:HasPerk(Player, "AvatarAppearance") or PerkService:IsFounder(Player) or PerkService:IsHero(Player))) then
					if NewCharacter:FindFirstChild("face", true) then NewCharacter:FindFirstChild("face", true):Destroy() end
					for i,v in ipairs(NewCharacter:GetChildren()) do
						if v:IsA("Accessory") then
							if v:FindFirstChild("HairAttachment", true) then
								local Hair = v
								local Handle = Hair.Handle
								Handle:FindFirstChildOfClass("SpecialMesh", true).VertexColor = Vector3.new(
									AppearanceData.HairColor.r,
									AppearanceData.HairColor.g,
									AppearanceData.HairColor.b
								)
							end
						end
					end
				end

				local NameTag = ReplicatedStorage.CharacterAssets:FindFirstChild("NameTag", true):Clone()
				NameTag.Parent = NewCharacter:FindFirstChild("Head")

				local Blob = PlayerCache[Player.UserId]
				if Blob.Stats == nil then
					local Timeout = 0
					repeat
						Blob = PlayerCache[Player.UserId]
						Timeout = Timeout+1
						wait(1)
					until Blob.Stats ~= nil or Timeout == 5
				end
				local ViewportClone = NewCharacter:Clone()
				ViewportClone.Name = "ViewportClone"
				ViewportClone.Parent = Player
				ViewportClone:FindFirstChild("NameTag", true):Destroy()

				NewCharacter.Parent = workspace.Characters

				--Set the health properly
				local ClassParams = self.Shared.ClassParams:Get(Blob.Stats.Class)
				self.Modules.UpdateHealth(Player, Blob, ClassParams)

				local NameTag = NewCharacter:FindFirstChild("NameTag", true)
				if NameTag ~= nil then
					NameTag.Label.Text = Player.Name
					NameTag.PlayerToHideFrom = Player
					
					if self.Services.PerkService:IsDev(Player) then
						NameTag.Label.TextColor3 = Color3.fromRGB(219, 133, 133)
					elseif self.Services.PerkService:IsFounder(Player) then
						NameTag.Label.TextColor3 = Color3.fromRGB(224, 222, 104)
					elseif self.Services.PerkService:IsHero(Player) then
						NameTag.Label.TextColor3 = Color3.fromRGB(104, 156, 224)
					end

					NameTag.Info.Text = "Level " .. tostring(Blob.Stats.Level)
				end
				
				Player.ReplicationFocus = NewCharacter.PrimaryPart
				delay(1, function()
					if NewCharacter ~= nil then
						if NewCharacter.PrimaryPart ~= nil then
							-- NewCharacter.PrimaryPart.Anchored = false
							Player.Character = NewCharacter	
							Player.Character.Humanoid.AnimationPlayed:Connect(function(track)
								local kfrm = Maid:new()
								kfrm:GiveTask(track.KeyframeReached:Connect(function(kf)
									if kf == "IFstart" then
										-- print('HENLO? OH BOI')
										PlayerCache[Player.UserId].Vulnerable = false
										kfrm:GiveTask(function() PlayerCache[Player.UserId].Vulnerable = true end)
									elseif kf == "IFend" then
										PlayerCache[Player.UserId].Vulnerable = true
									end
								end))
								track.Stopped:Connect(function()
									kfrm:DoCleaning()
								end)
							end)

							-- local Timeout = 0
							-- if not self.ReadyControllers[Player.UserId] then
							-- 	repeat
							-- 		wait(1)
							-- 		Timeout = Timeout + 1
							-- 	until self.ReadyControllers[Player.UserId] == true or Timeout == 3
							-- end

							self:FireClientEvent("CharacterAdded", Player, NewCharacter)
							self.Services.WeaponService:LoadWeapons(Player)
						else
							print('oh snap nil 2')
						end
					else
						print("oh snap nil 1")
					end
				end)
			end)
		end
		
		Player.CharacterAdded:Connect(function(character)
			self:FireEvent(PLAYER_CHARACTER_ADDED_EVENT, character)
			wait()

			-- character.Humanoid.HipHeight = character.Humanoid.HipHeight-0.185
			character.Humanoid.Died:Connect(function()
				wait(4)
				SpawnCharacter()
			end)
		end)

		SpawnCharacter()

		repeat wait() until HumDescCache[Player]
		if PlayerData.StarterEquipment then
			for Slot, ItemId in pairs(PlayerData.StarterEquipment) do
				if Slot == "Head" or Slot == "UpperArmor" or Slot == "LowerArmor" then
					-- find item
					for i, v in pairs(PlayerData.Inventory) do
						if v.ItemId == ItemId then
							print("found", ItemId)
							self:EquipSlot(Player, Slot, v.UniqueId)
						end
					end
				end
			end
		end

		self:FireEvent(PLAYER_ADDED_EVENT, Player, AppearanceCache[Player.UserId], PlayerCache[Player.UserId],
		{
			AppearanceStore = AppearanceStore;
			PlayerDataStore = PlayerDataStore;
			InboxStore = InboxStore;
			SingleCodeStore = SingleCodeStore;
		})
		self:SavePlayer(Player)
		-- FastSpawn(function()
		-- 	while true do
		-- 		wait(18)
		-- 		DataStore2.SaveAll(Player)
		-- 	end
		-- end)
	end

	Players.PlayerAdded:Connect(function(Player)
		if not RunService:IsStudio() then
			FastSpawn(function()
				StartPlayer(Player)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(Player)
		print(Player, "is leaving..")

		local Character = Player.Character or workspace.Characters:FindFirstChild(Player.Name)
		if Character then
			Character:Destroy()
		end

		if ServerStorage:WaitForChild("HumDesc"):FindFirstChild(tostring(Player.UserId)) then
			ServerStorage:WaitForChild("HumDesc"):FindFirstChild(tostring(Player.UserId)):Destroy()
		end

		self:FireEvent(PLAYER_REMOVED_EVENT, Player)
		-- self:SavePlayer(Player, PlayerCache[Player.UserId])

		AppearanceCache[Player.UserId] = nil
		PlayerCache[Player.UserId] = nil
	end)


	
	if RunService:IsStudio() then
		wait(2)
		for i, Player in pairs(Players:GetPlayers()) do
			StartPlayer(Player)
		end
	end
	
	RunService.Heartbeat:Connect(function(dt)
		for i, v in pairs(PlayerCache) do
			if v._lastHit then
				v._lastHit = math.clamp(v._lastHit-dt, 0, 999)
				-- print(i, v._lastHit)
			else
				v._lastHit = 0
			end
		end
	end)

	-- local LastSave = 0
	-- FastSpawn(function()
	-- 	while true do
	-- 		wait(15)
	-- 		for i, Player in ipairs(Players:GetPlayers()) do
	-- 			FastSpawn(function()
	-- 				self:SavePlayer(Player, PlayerCache[Player.UserId])
	-- 				-- DataStore2.SaveAll(Player)
	-- 			end)
	-- 		end
	-- 	end
	-- end)
end


function PlayerService:Init()
	self.ReadyControllers = {}
	self.PlayerCache = {}
	self.AppearanceCache = {}

	Maid = self.Shared.Maid
	TableUtil = self.Shared.TableUtil
	GlobalData = self.Shared.GlobalData
	GlobalMath = self.Shared.GlobalMath
	repr = self.Shared.repr
	TableUtil = self.Shared.TableUtil
	FormulasModule = self.Shared.FormulasModule
	FastSpawn = self.Shared.FastSpawn
	SkillCache = self.Shared.Cache:Get("SkillCache") 
	ItemLibrary = self.Shared.Cache:Get("ItemLibrary")

	PerkService = self.Services.PerkService
	RbxWebHook = self.Services.RbxWebHook

	self:RegisterEvent(PLAYER_ADDED_EVENT)
	self:RegisterEvent(PLAYER_REMOVED_EVENT)
	self:RegisterEvent(PLAYER_CHARACTER_ADDED_EVENT)
	self:RegisterEvent("IsBackup")

	self:RegisterClientEvent("UPGRADE_SKILL_EVENT")

	self:RegisterClientEvent(UPDATE_BLOB_EVENT)
	self:RegisterClientEvent(EQUIP_SLOT_EVENT)
	self:RegisterClientEvent(CLIENT_EFFECT_EVENT)
	self:RegisterClientEvent("CharacterAdded")
	self:RegisterClientEvent("ControllerLoaded")
	self:RegisterClientEvent("Fade")

	self:RegisterClientEvent("NotifyPlayer")
	self:RegisterClientEvent("SaveNotif")

	self:RegisterClientEvent("EditOption")
end


return PlayerService