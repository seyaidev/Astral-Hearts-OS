local DialogueService = {
    Client = {};
    __aeroPreventStart = true;
    __aeroPreventInit = true;
}

--[[
    objectives
        - process requests from clients based on info within the dialogue tree
            - this should be done as a backup if the player returns false for conditions to prompts/responses
            - should process all actions (teleporting, awarding, quests etc.)
]]

function DialogueService.Client:ProcessData(player, mod)
    if mod then
        local data = require(mod)
        wait(0.1)
        return data
    end
end

--- returns whether or not the requesting player can access this node
-- @param player requesting player object
-- @param node folder in dialogue tree with node properties
function DialogueService.Client:ProcessNode(player, node, modType)
    local response = true
    
    local conditionModule = node:FindFirstChild(modType)
    if conditionModule and conditionModule:IsA("ModuleScript") then
        -- condition modules will always take the player object as its sole argument
        -- this module should be overloaded with server/client checks to make sure it access the correct tables
        
        if not self.Server.CachedModules[node] then
            self.Server.CachedModules[node] = {}
        end
        
        local thisCondition = self.Server.CachedModules[node][modType] or require(conditionModule)
        response = thisCondition(player, node)

        if not self.Server.CachedModules[node][modType] then
            self.Server.CachedModules[node][modType] = thisCondition
        end
    end
    
    return response
end

function DialogueService:Start()
    self.CachedModules = {}
end

function DialogueService:Init()
    PlayerService = self.Services.PlayerService

end

return DialogueService