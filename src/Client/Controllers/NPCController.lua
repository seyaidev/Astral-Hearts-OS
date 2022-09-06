-- NPC Controller
-- Username
-- November 8, 2019



local NPCController = {}


function NPCController:Start()
    --collect NPCs every minute and when NPCs get added to the folder
    --load them into a table, and check with data blob to see which bubble to present
    local NPCFolder = workspace:WaitForChild("NPCs", 15)
    if NPCFolder == nil then return end

    for _, NPC in ipairs(NPCFolder:GetChildren()) do
        if NPC:IsA("Model") then

        end
    end
    
end


function NPCController:Init()
    DataBlob = self.Controllers.DataBlob
	NPCService = self.Services.NPCService
end


return NPCController