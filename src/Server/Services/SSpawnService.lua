local SSpawnService = {}

function SSpawnService:SpawnRegion(SRegion)
    local RegionParams = self.SRegions[SRegion]
    local trueQuantity = RegionParams.MaxLimit
    RegionParams.SpawnTime = math.huge
    self.Services.MobService:SingleSpawn(RegionParams, trueQuantity)
end

function SSpawnService:Start()
    -- collect boss regions
    self.SRegions = {}
    self.CanSpawn = {}

    local SRegions = workspace:WaitForChild("SRegions", 3)
    if not SRegions then return end
    for _, RegionPart in ipairs(workspace:WaitForChild("SRegions"):GetChildren()) do
        local NewRegion = self.Services.MobService:GenerateRegion(RegionPart)
        self.SRegions[NewRegion.Id] = NewRegion
    end

    self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(Player)
        self.CanSpawn[Player] = {}
    end)

    self:ConnectClientEvent("SpawnRegion", function(Player, SRegion)
        if self.CanSpawn[Player] then
            if not self.CanSpawn[Player][SRegion] then
                self:SpawnRegion(SRegion)
                print("Spawning " .. SRegion .. "...")
            end
        end
    end)
end

function SSpawnService:Init()
    self:RegisterClientEvent("SpawnRegion")
end

return SSpawnService