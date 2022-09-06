-- Anti Service
-- Username
-- November 27, 2019

local RunService = game:GetService("RunService")

local AntiService = {Client = {}}
local DataStoreService = game:GetService("DataStoreService")
local TriggerStore = DataStoreService:GetDataStore("Triggers")
local LockStore = DataStoreService:GetDataStore("Lock")
local ExploitStore = DataStoreService:GetDataStore("Exploit")

local Players = game:GetService("Players")

--checks horizontal movement

local skip = false
function AntiService:Start()
    -- if true then return end

    local Triggers = {}
    local Maids = {}

    Players.PlayerRemoving:Connect(function(Player)
        Triggers[Player] = nil
        if Maids[Player] then
            Maids[Player]:DoCleaning()
            Maids[Player] = nil
        end
    end)

    local function StartPlayer(Player)
        local HBmaid = Maid.new()
        Maids[Player] = HBmaid
        Player.CharacterAdded:Connect(function(Character)
            HBmaid:DoCleaning()
            local Humanoid = Character:WaitForChild("Humanoid")
            self.LastPosition[Player] = nil

            local AverageVelocity = {}
            Humanoid.Died:Connect(function()
                HBmaid:DoCleaning()
            end)

            HBmaid:GiveTask(RunService.Stepped:Connect(function(dt)
                if Character.PrimaryPart ~= nil then
                    local CurrentPosition = Character.PrimaryPart.Position
                    local flatPos = Vector3.new(CurrentPosition.X, 0, CurrentPosition.Z)
                    
                    local Revert = false
                    if self.LastPosition[Player] then
                        local lflatPos = Vector3.new(
                            self.LastPosition[Player].X, 0, self.LastPosition[Player].Z
                        )
                        local Distance = (flatPos-lflatPos).magnitude
                        if Distance then
                            --check if disatnce is greater than walkspeed
                            --check if distance is greater than dash speed
            
                            local Velocity = Distance/dt
                            -- print(DelayTime)
                            -- print(tostring(Player.UserId) .. " Velocity: " .. tostring(Velocity))

                            if Velocity > 5 then
                                table.insert(AverageVelocity, Velocity)
                            end

                            if #AverageVelocity > 55 or Velocity <= 5 then
                                table.remove(AverageVelocity, 1)
                            end

                            local TotalVelocity = 0
                            for i, v in ipairs(AverageVelocity) do
                                TotalVelocity = TotalVelocity + v
                            end

                            local CheckVelocity = TotalVelocity / #AverageVelocity
                            
                            -- print("CV:", CheckVelocity, #AverageVelocity)

                            if CheckVelocity > 50 then
                                    -- local s, m = pcall(function() LockStore:SetAsync(Player.UserId, true) end)
                                    -- Player:Kick("Could not sync up with Sayo Server [5]")
            
                                    if not Triggers[Player] then
                                        Triggers[Player] = 1
                                    else
                                        Triggers[Player] = Triggers[Player]+1
                                    end
            
                                    Revert = true
                                    Character.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
                                    Character:MoveTo(self.LastPosition[Player] + Vector3.new(0,2,0))
                                    print("incremented:", Triggers[Player])
    
                            end
                            -- if not Revert then self.LastVelocity[Player] = Velocity end
                            if Triggers[Player] then
                                if Triggers[Player] > 15 then
                                    -- local s, m = pcall(function() LockStore:SetAsync(Player.UserId, true) end)
                                    -- local s, m = pcall(function() LockStore:SetAsync(Player.UserId, true) end) --disable save for this player
                                    local j, k = pcall(function() ExploitStore:SetAsync(Player.UserId, Triggers[Player]) end) --prevent them from reloading into the game
                                    Player:Kick("Could not sync up with Sayo Server [4]")
                                end
                            end
                        end
                    end
                    if not Revert then self.LastPosition[Player] = CurrentPosition end
                end
            end))
        end)
    end

    Players.PlayerAdded:Connect(StartPlayer)

    if game:GetService("RunService"):IsStudio() then
        for i, v in ipairs(Players:GetPlayers()) do
            StartPlayer(v)
        end
    end
end


function AntiService:Init()
    self.LastPosition = {}
    self.LastVelocity = {}

    Maid = self.Shared.Maid
end


return AntiService