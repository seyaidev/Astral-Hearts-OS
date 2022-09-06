--edit the function below to return true when you want this response/prompt to be valid
--player is the player speaking to the dialogue, and dialogueFolder is the object containing the dialogue data
local QuestEvent = nil
local Prereqs = {"CecilStart1"}
local QuestId = "JeraltIntro"


--Priority 3 prompt
return function(player, dialogueFolder)
	while (not _G.AeroServer) do wait() end
	local aeroServer = _G.AeroServer
	local QuestService = aeroServer.Services.QuestService
	
	if QuestEvent then
		if QuestService:HasQuestInProgress(player, QuestId) then
			QuestService:UpdateQuest(player, {
				Objective = nil;
				Target = nil;
			})
		end
	end
    
    if #Prereqs > 0 then
        for i,v in ipairs(Prereqs) do
            if not QuestService:HasQuestCompleted(player, QuestId) then
                return false
            end
        end
    end
	
	return QuestService:HasQuestInProgress(player, QuestId) == true and QuestService:HasQuestCompleted(player, QuestId) == false
end

-- TALKING EVENT

--edit the below function to execute code when this response is chosen OR this prompt is shown
--player is the player speaking to the dialogue, and dialogueFolder is the object containing the dialogue data
local QuestEvent = "CecilStart1"
return function(player, dialogueFolder)
	while (not _G.AeroServer) do wait() end
	local aeroServer = _G.AeroServer
	local QuestService = aeroServer.Services.QuestService
	
	if QuestEvent then
		if QuestService:HasQuestInProgress(player, QuestEvent) then
			QuestService:UpdateQuest(player, {
				Objective = "TALK";
				Target = "Jeralt";
			})
		end
	end
end

--ACCEPT QUEST

--edit the function below to return true when you want this response/prompt to be valid
--player is the player speaking to the dialogue, and dialogueFolder is the object containing the dialogue data
local QuestId = "JeraltIntro"

return function(player, dialogueFolder)
	while (not _G.AeroServer) do wait() end
	local aeroServer = _G.AeroServer
	local QuestService = aeroServer.Services.QuestService
	
	QuestService:ReceiveQuest(player, QuestId)
end

-- DISPLAY QUEST DATA

local RunService = game:GetService("RunService")
local QuestData = {}
if not RunService:IsClient() and RunService:IsServer() then
	while (not _G.AeroServer) do wait() end
	local aeroServer = _G.AeroServer
	local QuestService = aeroServer.Services.QuestService
	QuestData = QuestService:GenQuest("JeraltIntro")
end

return {
	Quest = QuestData;	
}