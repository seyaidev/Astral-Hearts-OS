-- Zone Service
-- oniich_n
-- August 8, 2019

local CollectionService = game:GetService("CollectionService")

local ZoneService = {Client = {}}
local Zones = {}

function ZoneService.Client:GetZones()
    if Zones == nil then
        repeat wait() print("couldn't find zone", Zones) until Zones ~= nil
    end
    return Zones
end

function ZoneService:Start()
    local RegenBois = {}
    for i, Zone in pairs(workspace.Zones:GetChildren()) do
        local Half = Vector3.new(
            Zone.Size.X/2,
            0,
            Zone.Size.Z/2
        )
        local Min = Zone.Position - Half
        local Max = Zone.Position + Half
        
        local This = {}
        This.Name = Zone.Name
        This.Min = Min
        This.Max = Max
        This.Safe = CollectionService:HasTag(Zone, "SafeZone")
        if This.Safe then
            if Zone:FindFirstChild("Spawn") then
                This.Spawn = Zone.Spawn.Value
            end
        end

        Zone:Destroy()

        table.insert(Zones, This)
        print("inserted zone")
    end

    self:ConnectClientEvent("ZoneChange", function(Player, ZoneName)
        local Zone = nil
        for i, v in ipairs(Zones) do
            if v.Name == ZoneName then
                Zone = v
                break
            end
        end
        if Zone == nil then return end
        if Zone.Safe then
            --check if Player is in combat
                if Zone.Spawn then
                    self.Services.PlayerService:SetPartial(Player, "S", Zone.Spawn.Name)
                    Player.RespawnLocation = Zone.Spawn
                    -- print(Player.RespawnLocation)
                end
                if Player.Character then
                    local pos = Player.Character.PrimaryPart.Position
                    if pos.X < Zone.Max.X+10 and pos.X > Zone.Min.X-10 and pos.Z <= Zone.Max.Z+10 and pos.Z > Zone.Min.Z-10 then
                        RegenBois[Player] = true
                        return
                    end
                end
        end

        RegenBois[Player] = false
    end)

    FastSpawn(function()
        while true do
            wait(1)
            for Player, Status in pairs(RegenBois) do
                local pdata = self.Services.PlayerService:GetPlayerData(Player)
                if pdata then
                    if pdata._lastHit <= 0 then
                        if Status then
                            local Character = Player.Character
                            if Character then
                                local Humanoid = Character:FindFirstChild("Humanoid")
                                if Humanoid then
                                    if Humanoid.Health < Humanoid.MaxHealth then
                                        Humanoid.Health = math.clamp(Humanoid.Health+(Humanoid.MaxHealth*0.05), 1, Humanoid.MaxHealth)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end


function ZoneService:Init()
    self:RegisterClientEvent("ZoneChange")

    FastSpawn = self.Shared.FastSpawn
end


return ZoneService