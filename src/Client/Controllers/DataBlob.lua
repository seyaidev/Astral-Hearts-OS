local DataBlob = {}
DataBlob.__aeroOrder = 1

local NEW_QUEST_EVENT = "NewQuest"

function DataBlob:ForceUpdate()
    self.Blob = self.Services.PlayerService:GetPlayerData()
end

function DataBlob:Start()
    self.Services.PlayerService.UpdateBlob:Connect(function(newblob)
        self.Blob = newblob
    end)

    self.Initialized = true
    self.Blob = self.Services.PlayerService:GetPlayerData()
    self.Options = self.Services.PlayerService:GetOptions()

    self.Party = self.Services.PartyService:findParty()

    self:ConnectEvent("UpdateParty", function()
        self.Party = self.Services.PartyService:findParty()
    end)
end

function DataBlob:Init()
    self:RegisterEvent("UpdateParty")
    self.Initialized = false
    self.Blob = self.Services.PlayerService:GetPlayerData()
    self.Options = self.Services.PlayerService:GetOptions()
    if self.Blob == nil then
        local Timeout = 0
        repeat
            wait(1)
            self.Blob = self.Services.PlayerService:GetPlayerData()
            Timeout = Timeout+1
        until self.Blob ~= nil
    end

    print("Init DataBlob:", self.Blob)
end

return DataBlob