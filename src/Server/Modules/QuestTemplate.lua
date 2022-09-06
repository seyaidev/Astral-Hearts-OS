--Global Multi-Objective Quest
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local BadgeService = game:GetService("BadgeService")
local Quest = {}
Quest.__index = Quest

local Id = script.Name

--[[
[Type] = {
	[Objective] = Value;
	[Objective] = Value;
}

--]]

--[[
Objects to create.
ObjectiveInfo - StringValue
ProgressInfo - StringValue
RewardInfo - StringValue

Replayable - BoolValue
DisplayName - StringValue

]]

function Quest:new(Player, PlayerInfo, QuestId, CompleteEvent, RewardEvent) --PlayerInfo = data from DataStore; nil if receiving quest
	local qfolder = ServerStorage:FindFirstChild(QuestId, true)
	local ProInfo = HttpService:JSONDecode(qfolder:WaitForChild("ProgressInfo").Value)
	if #PlayerInfo == 0 then	--Initial Data on initial receive
		PlayerInfo = {}
		PlayerInfo[Id] = {}
		PlayerInfo[Id]["Progress"] = {}
		PlayerInfo[Id]["Progress"]["TALK"] = {}
		PlayerInfo[Id]["Progress"]["KILL"] = {}
		PlayerInfo[Id]["Progress"]["GATHER"] = {}

		for Type, TypeTable in pairs(ProInfo) do
			for Objective, Value in pairs(TypeTable) do
				PlayerInfo[Id]["Progress"][Type][Objective] = Value
			end
		end
	end

	-- setup things to track..
	local trackfolder = qfolder:FindFirstChild("Track")
	local toTrack = {}
	if trackfolder then
		for _, Type in ipairs(trackfolder:GetChildren()) do
			toTrack[Type.Name] = {}
			for i, thing in ipairs(Type:GetChildren()) do
				if thing.Value then
					toTrack[Type.Name][thing.Name] = true
				end
			end
		end
	end

	local NewQuest = {
		Id				= QuestId;
		Replayable		= qfolder.Replayable.Value;
		DisplayName	= qfolder.DisplayName.Value;
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
		Tracking = toTrack;
	}

	for Type, TypeTable in pairs(PlayerInfo[Id]["Progress"]) do
		for Objective, Value in pairs(TypeTable) do
			print(Type)
			NewQuest["Progress"][Type][Objective] = Value
		end
	end

	function NewQuest.Complete()
		local CompleteTable = {}
		for Objective, ObjectiveTable in pairs(NewQuest.Objectives) do
			for Target, TargetData in pairs(ObjectiveTable) do
				print(typeof(NewQuest.Progress[Objective][Target]), Objective, Target, NewQuest.Progress[Objective][Target])
				if typeof(NewQuest.Progress[Objective][Target]) == "number" then
					print("Completed:", (NewQuest.Progress[Objective][Target] >= TargetData))
					table.insert(CompleteTable, NewQuest.Progress[Objective][Target] >= TargetData)
					--print("Completed:", NewQuest.DisplayName)
					--event to GlobalPlayers
					print(Target, CompleteTable[Target])
				elseif typeof(NewQuest.Progress[Objective][Target]) == "boolean" then
					table.insert(CompleteTable, NewQuest.Progress[Objective][Target] == TargetData)
				end
			end
		end
		print("Quest Objectives:", #CompleteTable)
		for Target, Completed in pairs(CompleteTable) do
			if Completed == false or Completed == nil then
				print("Not complete", Target)
				return false
			else
				-- remove from tracking table
				if NewQuest.Tracking then
					for Type, Targets in pairs(NewQuest.Tracking) do
						for name, value in pairs(Targets) do
							if name == Target then
								NewQuest.Tracking[Type][name] = false;
							end
						end
					end
				end
			end
		end

		-- ServerStorage:FindFirstChild("CompleteQuest", true):Fire(Player, NewQuest.Id, NewQuest.Rewards)
		-- 			--event to Client for UI
		-- wait()
		-- for i, v in pairs(NewQuest.Rewards) do
		-- 	print(i, v)
		-- end
		if qfolder:FindFirstChild("Badge") then
			BadgeService:AwardBadge(Player.UserId, qfolder:FindFirstChild("Badge").Value)
			print("gave badge..")
		end

		CompleteEvent:Fire(Player, NewQuest.Id) --play quest complete notification
		RewardEvent:Fire(Player, NewQuest.Rewards["EXP"], NewQuest.Rewards["GOLD"])
	end

	setmetatable(NewQuest, Quest)
	return NewQuest
end

function Quest:GetObjective(state) -- state can be true or false
	local theseObjectives = {}
	for Objective, ObjTable in pairs(self.Objectives) do
		theseObjectives[Objective] = {}
		for Target, Value in pairs(ObjTable) do
			if (self.Progress[Objective][Target] == Value) == state then
				theseObjectives[Objective][Target] = {
					Current = self.Progress[Objective][Target];
					Target = Value;
				}
			end
		end
	end

	return theseObjectives
end

function Quest:Update(Info)
	for Objective, ObjTable in pairs(self.Objectives) do
		if Objective == Info.Objective then
			for Target, Value in pairs(ObjTable) do
				if Objective == "TALK" then
					if self.Progress[Objective][Target] == false and Info.Target == Target then
						self.Progress[Objective][Target] = true
						print("Updated", Id, self.Progress[Objective][Target])
						self.Complete()
						return true
					end
				elseif Objective == "KILL" or Objective == "GATHER" then
					local Quantity = Info.Quantity or 1
					if self.Progress[Objective][Target] < Value and Info.Target == Target then
						self.Progress[Objective][Target] = self.Progress[Objective][Target]+Quantity
						print("Updated", Id, self.Progress[Objective][Target])
						self.Complete()
						return true
					end
				end
			end
		end
	end

	return false
end

function Quest:Start() end
function Quest:Init() end

return Quest