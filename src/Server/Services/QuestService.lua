-- Quest Service
-- oniich_n
-- April 22, 2019

--[[
	
	Server:
		
	
		QuestService.UpdateQuest()


	Client:
		
	

--]]
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local QuestObjects = ServerStorage:WaitForChild("QuestObjects")

local DataStore2 = require(game:GetService("ServerStorage"):FindFirstChild("DataStore2", true))

local HttpService = game:GetService("HttpService")

local QuestTemplate


local QuestService = {Client = {}}
local PlayerService
local Event

local REMOVE_QUEST_CLIENT_EVENT = "RemoveQuest"
local UPDATE_QUEST_CLIENT_EVENT = "UpdateQuest"
local NEW_QUEST_CLIENT_EVENT = "NewQuest"

local QuestList = {}

function QuestService:GetCache(Player, CharacterId)
	CharacterId = CharacterId or self.Services.PlayerService:GetPartial(Player, "CharacterId")
	if self.Version then
		print("Initial QS:GetCache", self.Version)
		DataStore2.Combine(self.Version, CharacterId .. "_Q")
	end
	-- print("QS:GetCache", CharacterId)
	local PlayerQuestData = QuestList[Player.UserId]
	if not PlayerQuestData then
		local retry = 0
		repeat
			wait(1)
			local QuestBlob = DataStore2(CharacterId .. "_Q", Player):GetTable({
				
				InitData = {},
				CompletedId = {},
				InProgress = {},
				Completed = {},
				
			})

			if QuestBlob.InProgress == nil then QuestBlob.InProgress = {} end
			if QuestBlob.Completed == nil then QuestBlob.Completed = {} end

			for QuestId, Data in pairs(QuestBlob.InitData) do
				-- print(QuestId, Data)
				-- print("can find obj", QuestObjects:FindFirstChild(QuestId, true))
				if QuestObjects:FindFirstChild(QuestId, true) ~= nil then
					local qOb = QuestObjects:FindFirstChild(QuestId, true)
					local rpv = qOb:FindFirstChild("Replayable", true)
					if rpv then
						if rpv.Value or (not rpv.Value and not QuestBlob.CompletedId[QuestId]) then
							local nQuestObject = QuestTemplate:new(Player, Data, QuestId, self.cCompleteQuest, self.cRewardNotif)
							QuestBlob.InProgress[QuestId] = nQuestObject
						else
							QuestBlob.InitData[QuestId] = nil
						end
					end
				end
			end
		
			for QuestId, Data in pairs(QuestBlob.CompletedId) do
				if QuestObjects:FindFirstChild(QuestId, true) ~= nil then
					local nQuestObject = QuestTemplate:new(Player, QuestBlob.CompletedId, QuestId, self.cCompleteQuest, self.cRewardNotif)
					QuestBlob.Completed[QuestId] = nQuestObject
				end
			end
	
			QuestList[Player.UserId] = QuestBlob
			PlayerQuestData = QuestBlob
			retry = retry + 1
		until (PlayerQuestData ~= nil and PlayerQuestData == QuestList[Player.UserId]) or retry == 5
	end

	return PlayerQuestData
end

function QuestService:GenerateSaveQuest(Player)
	local QuestBlob = self:GetCache(Player)
	local NewSaveData = {
		InitData = {};
		CompletedId = {};
		GAME_VERSION = GlobalData.GAME_VERSION
	}
	for QuestId, QuestData in pairs(QuestBlob.InProgress) do
		NewSaveData.InitData[QuestId] = {}
		NewSaveData.InitData[QuestId]["Progress"] = {}
		for Objective, ObjectiveData in pairs(QuestData.Progress) do
			NewSaveData.InitData[QuestId]["Progress"][Objective] = {}
			for Target, TargetData in pairs(ObjectiveData) do
				NewSaveData.InitData[QuestId]["Progress"][Objective][Target] = TargetData
			end
		end
	end

	for QuestId, QuestData in pairs(QuestBlob.Completed) do
		NewSaveData.CompletedId[QuestId] = true
	end

	for QuestId, val in pairs(QuestBlob.CompletedId) do
		NewSaveData.CompletedId[QuestId] = true
	end

	return NewSaveData
end

function QuestService:SavePlayer(Player)
	local CharacterId = self.Services.PlayerService:GetPartial(Player, "CharacterId")
	local NSD = self:GenerateSaveQuest(Player)
	print("Saving QuestData...")
	if NSD then
		DataStore2.Combine(self.Version, CharacterId .. "_Q")
		DataStore2(CharacterId .. "_Q", Player):Set(NSD)
	-- PlayerService:SetPartial(Player, "QuestData", NSD)
		self:FireClientEvent("ForceUpdate", Player)
	end
	-- QuestStore:UpdateAsync(tostring(Player.UserId) .. "_Slot" .. tostring(PlayerQuestData._slot), function()
	-- 	return NSD
	-- end)
end

function QuestService:CompleteQuest(Player, QuestId)
	local PlayerQuestData = self:GetCache(Player)

	PlayerQuestData.Completed[QuestId] = PlayerQuestData.InProgress[QuestId]
	wait()
	PlayerQuestData.InProgress[QuestId] = nil
	self.Services.PlayerService:Reward(Player.UserId, {
		EXP = PlayerQuestData.Completed[QuestId].Rewards.EXP,
		Munny = PlayerQuestData.Completed[QuestId].Rewards.GOLD
	})
	
	self:FireClientEvent(REMOVE_QUEST_CLIENT_EVENT, Player, QuestId, true)
	QuestList[Player.UserId] = PlayerQuestData
	self:SavePlayer(Player)
end

function QuestService:UpdateQuest(Player, Request, QuestId)
	local PlayerQuestData = self:GetCache(Player)
	-- print("DEBUG QUESTSERVICE:", repr(PlayerQuestData))

	local function SendUpdate(lQuestData, lQuestId)
		local t = lQuestData:Update(Request)
		if t then
			self:FireClientEvent(UPDATE_QUEST_CLIENT_EVENT, Player, lQuestId)
			return true
		end
		return false
	end

	if QuestId ~= nil then
		if PlayerQuestData.InProgress[QuestId] then
			local t = SendUpdate(PlayerQuestData.InProgress[QuestId], QuestId)
			if t then
				self:SavePlayer(Player)
			end
		end
		return
	end

	local c = 0
	for tQuestId, tQuestData in pairs(PlayerQuestData.InProgress) do
		-- print(repr(QuestData))
		local t = SendUpdate(tQuestData, tQuestId)
		if t then
			c = c+1
		end
	end

	QuestList[Player.UserId] = PlayerQuestData
	if c > 0 then
		self:SavePlayer(Player)
	end
end

function QuestService:CheckObjective(Player, Info, QuestId)
	local PlayerQuestData = self:GetCache(Player)
	if PlayerQuestData.InProgress[QuestId] then
		local Object = PlayerQuestData.InProgress[QuestId]

		for Objective, ObjTable in pairs(Object.Objectives) do
			if Objective == Info.Objective then
				for Target, Value in pairs(ObjTable) do
					if Objective == "TALK" then
						if Object.Progress[Objective][Target] == true and Info.Target == Target then
							return true
						end
						print("Not a true target", Info.Target, Target)
					elseif Objective == "KILL" or Objective == "GATHER" then
	
						if Object.Progress[Objective][Target] == Value and Info.Target == Target then
							return true
						end
					end
				end
			end
		end
		return false
	end
end

function QuestService:ReceiveQuest(Player, QuestId, InitData)
	local PlayerData = self.Services.PlayerService:GetPlayerData(Player)
	local PlayerQuestData = self:GetCache(Player)
	local QF = ServerStorage.QuestObjects:FindFirstChild(QuestId, true)
	local Replayable = QF:FindFirstChild("Replayable")
	if PlayerQuestData.InProgress[QuestId] ~= nil then return end -- player already has this quest in progress
	if Replayable then
		if not Replayable.Value and PlayerQuestData.Completed[QuestId] then
			return
		end
	end

	--check level req
	--check quest prereqs
	local Requirements = QF:FindFirstChild("Requirements")
	if Requirements then
		local REQt = HttpService:JSONDecode(Requirements.Value)
		if REQt then
			if PlayerData.Stats.Level < REQt.LEVEL then return end

			local questReq = true
			for QuestId, val in pairs(REQt.QUEST) do
				--check if the quest exists in completed pqd
				if not PlayerQuestData.Completed[QuestId] then
					questReq = false
				end
			end

			if not questReq then return end

			local counts = {}
			for UniqueId, ItemData in pairs(PlayerData.Inventory) do
				local thisItemId = UniqueId
				local thisCount = ItemData
				if typeof(ItemData) == "table" then
					thisItemId = ItemData.ItemId
					thisCount = 1
				end

				
				if counts[thisItemId] then
					counts[thisItemId] = counts[thisItemId]+thisCount
				else
					counts[thisItemId] = thisCount
				end
			end
			-- for ItemId, Amount in pairs(REQt.ITEM) do
			-- 	if counts[ItemId] < Amount then return end
			-- end
		end
	end

	local rQuestObject = QuestTemplate:new(Player, InitData or {}, QuestId, self.cCompleteQuest, self.cRewardNotif)
	PlayerQuestData.InProgress[QuestId] = rQuestObject

	QuestList[Player.UserId] = PlayerQuestData

	self:SavePlayer(Player)
	self:FireClientEvent(NEW_QUEST_CLIENT_EVENT, Player, QuestId)
	print("Received quest:", QuestId)
end

function QuestService:GenQuest(QuestId)
	local qfolder = ServerStorage:FindFirstChild(QuestId, true)
	if not qfolder then return end
	local NewQuest = {
		Id				= QuestId;
		Replayable		= qfolder.Replayable.Value;
		DisplayName		= qfolder.DisplayName.Value;
		Desc			= qfolder.Desc.Value;
		Requirements	= HttpService:JSONDecode(qfolder:WaitForChild("Requirements").Value);
		Objectives		= HttpService:JSONDecode(qfolder:WaitForChild("ObjectiveInfo").Value);
		Progress		= {
			["KILL"] 	= {};
			["TALK"] 	= {};
			["GATHER"]	= {};
		};
		Rewards		= HttpService:JSONDecode(qfolder:WaitForChild("RewardInfo").Value);

		Completed = false;
	}

	return NewQuest
end

function QuestService.Client:GetTrackingInfo(Player, QuestId)
	-- create waypoints
	local Waypoints = {}
	-- check if objective is complete
	-- get positions of where objective is if incomplete
	-- return info

	local PlayerQuestData = self.Server:GetCache(Player)
	if not PlayerQuestData then return Waypoints end
	local QuestObject = PlayerQuestData.InProgress[QuestId]
	if QuestObject then
		local objectivesInfo = QuestObject:GetObjective(false)
		for Objective, ObjTable in pairs(objectivesInfo) do
			-- if objective == GATHER or objective == KILL then get look for mob spawns with it
			for Target, Value in pairs(ObjTable) do
				if Objective == "GATHER" or Objective == "KILL" then
					local locations = self.Server.Services.MobService:GetLocations(Player, Objective, Target)
					if #locations > 0 then
						Waypoints[Target] = locations
					end
				elseif Objective == "TALK" then
					local NPC = workspace.NPCs:FindFirstChild(Target)
					if NPC then
						Waypoints[Target] = {{NPC.PrimaryPart.Position}}
					end
				end
			end
		end
	end

	return Waypoints
end

function QuestService.Client:GenQuest(Player, QuestId)
	if QuestId then
		return self.Server:GenQuest(QuestId)
	end
end

function QuestService:HasQuestInProgress(Player, QuestId)
	local PlayerQuestData = self:GetCache(Player)
	if not PlayerQuestData then
		repeat
			wait()
			PlayerQuestData = self.Server.Services.PlayerService:GetPartial(Player, "QuestData")	
			if PlayerQuestData then QuestList[Player.UserId] = PlayerQuestData end
		until PlayerQuestData ~= nil and PlayerQuestData == QuestList[Player.UserId]
	end

	if PlayerQuestData.InProgress[QuestId] == nil then return false end

	return true
end


function QuestService:HasQuestCompleted(Player, QuestId)
	local PlayerQuestData = self:GetCache(Player)
	if not PlayerQuestData then
		repeat
			wait()
			PlayerQuestData = self.Server.Services.PlayerService:GetPartial(Player, "QuestData")	
			if PlayerQuestData then QuestList[Player.UserId] = PlayerQuestData end
		until PlayerQuestData ~= nil and PlayerQuestData == QuestList[Player.UserId]
	end

	if PlayerQuestData.InProgress[QuestId] ~= nil then return false end

	if PlayerQuestData.Completed[QuestId] == nil then return false end

	return true
end

function QuestService:HasCompleteConditions(Player, Quest)
	local PlayerQuestData = self:GetCache(Player)
	if PlayerQuestData.InProgress[QuestId] == nil then return false end

	--find complete conditions

	--for i
end

function QuestService.Client:ReturnQuestData(Player)
	local PlayerQuestData = self.Server:GetCache(Player)
	local NewTable = {
		InProgress = {};
		Completed = {};
	}
	for i, v in pairs(PlayerQuestData.InProgress) do
		NewTable.InProgress[i] = {}
		for j, k in pairs(v) do
			if typeof(k) == "table" then
				NewTable.InProgress[i][j] = {}
				for n, m in pairs(k) do
					NewTable.InProgress[i][j][n] = m
					--print(i, j, n, m)
				end
			else
				NewTable.InProgress[i][j] = k
			end
		end
	end

	for i, v in pairs(PlayerQuestData.Completed) do
		NewTable.Completed[i] = {}
		for j, k in pairs(v) do
			if typeof(k) == "table" then
				NewTable.Completed[i][j] = {}
				for n, m in pairs(k) do
					NewTable.Completed[i][j][n] = m
					--print(i, j, n, m)
				end
			else
				NewTable.Completed[i][j] = k
			end
		end
	end
 	return NewTable
end

function QuestService.Client:DropQuest(Player, QuestId)
	local PlayerQuestData = self.Server:GetCache(Player)

	if PlayerQuestData.InProgress[QuestId] ~= nil then
		PlayerQuestData.InProgress[QuestId] = nil

		QuestList[Player.UserId] = PlayerQuestData
		self.Server:SavePlayer(Player)
		wait()
		return true
	end
	return false
end

function QuestService:Start()
	-- if true then return end

	

	PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(Player, AppearanceCache, PlayerCache)
		wait(1)
		print("Combining quest data:", self.Version, AppearanceCache.CharacterId)

		DataStore2.Combine(self.Version, AppearanceCache.CharacterId .. "_Q")
		local QuestBlob = self:GetCache(Player, AppearanceCache.CharacterId)
		print("Loaded quest data:", Player.UserId)
		self:SavePlayer(Player)
	end)

	PlayerService:ConnectEvent("PLAYER_REMOVED_EVENT", function(Player)
		QuestList[Player.UserId] = nil
	end)

	self:ConnectClientEvent(REMOVE_QUEST_CLIENT_EVENT, function(Player, QuestId)
		local PlayerQuestData = self:GetCache(Player)

		print('Attempted to remove quest')
		print(PlayerQuestData)
		if PlayerQuestData.InProgress[QuestId] ~= nil then
			PlayerQuestData.InProgress[QuestId] = nil

			QuestList[Player.UserId] = PlayerQuestData
			wait()
			self:SavePlayer(Player)

			local CheckData = self:GetCache(Player)
		end
	end)
end


function QuestService:Init()
	-- if true then return end
	Event = self.Shared.Event

	self:RegisterClientEvent(NEW_QUEST_CLIENT_EVENT)
	self:RegisterClientEvent(REMOVE_QUEST_CLIENT_EVENT)
	self:RegisterClientEvent(UPDATE_QUEST_CLIENT_EVENT)
	self:RegisterClientEvent("ForceUpdate")

	self.cCompleteQuest = Event.new()
	self.cCompleteQuest:Connect(function(Player, Id)
		self:CompleteQuest(Player, Id)
	end)
	self.cRewardNotif = Event.new()
	self.cRewardNotif:Connect(function(Player, ExpReward, GoldReward)
		--
	end)

	PlayerService = self.Services.PlayerService
	QuestTemplate = self.Modules.QuestTemplate
	GlobalData = self.Shared.GlobalData

	self.Version = GlobalData.DATA_VERSION
	if game.GameId == 514087790 then
		--self.Version = GlobalData.TEST_VERSION
	end

	repr = self.Shared.repr
end


return QuestService