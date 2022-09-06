local NPCService = {Client = {}}

function NPCService.Client:ProcessNPC(Player, NPC)
    if self.Server.LoadedNPCs[NPC] == nil then return end
    local ThisNPC = self.Server.LoadedNPCs[NPC]

    local QuestService = self.Server.Services.QuestService
    
    for i, QuestId in ipairs(ThisNPC) do
        local Completed = QuestService:HasQuestCompleted(Player, QuestId)
        local InProgress = QuestService:HasQuestInProgress(Player, QuestId)

        if not Completed and not InProgress then
            return "NewQuest"
        elseif not Completed and InProgress then
            return "InProgress"
        end
    end

    return "Done"
end

function NPCService:Start()
    local NPCFolder = workspace:WaitForChild("NPCs")
    for i, NPC in ipairs(NPCFolder:GetChildren()) do
        if NPC:IsA("Model") then
            if NPC:FindFirstChild("QuestObjects") then
                local QuestIds = {}
                for i,v in ipairs(NPC:FindFirstChild("QuestObjects"):GetChildren()) do
                    if v:IsA("StringValue") then
                        table.insert(QuestIds, v.Value)
                    end
                end

                self.LoadedNPCs[NPC] = QuestIds
            end
        end
    end
end

function NPCService:Init()
    self.LoadedNPCs = {}
end

return NPCService