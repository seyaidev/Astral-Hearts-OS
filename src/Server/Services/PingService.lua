-- Ping Service
-- oniich_n
-- August 19, 2019


local RunService = game:GetService("RunService")

local PingService = {Client = {}}

function PingService:Start()
    local rng = Random.new(os.time())
    local lastNumbers = {}
    local Triggers = {}
    
    self:ConnectClientEvent("PingSend", function(Player, Number)
        local index = TableUtil.IndexOf(lastNumbers, Number)
        if index ~= nil then
            self.Delays[Player.UserId] = (#lastNumbers-index+1)*2
            self.LastReceived[Player.UserId] = 0
            -- print(#lastNumbers-index)

            --check position
        end
    end)

    game:GetService("Players").PlayerAdded:Connect(function(Player)
        self.LastReceived[Player.UserId] = 0
        self.Delays[Player.UserId] = 0
    end)
    
    game:GetService("Players").PlayerRemoving:Connect(function(Player)
        self.LastReceived[Player.UserId] = nil
        self.Delays[Player.UserId] = nil
    end)

    local PingStep = false
    RunService.Heartbeat:Connect(function(dt)
        if PingStep then PingStep = false return end
        PingStep = true
        local nextNumber = rng:NextNumber(-900000, 900000)
        table.insert(lastNumbers, nextNumber)
        -- print(nextNumber)
        self:FireAllClientsEvent("PingRand", nextNumber)

        if #lastNumbers >= 10000 then
            table.remove(lastNumbers, 1)
        end

        for i, v in pairs(self.LastReceived) do
            v = v+dt
            if v >= 30 then
                local Player = game.Players:GetPlayerByUserId(i)
                if Player then
                    Player:Kick("Did not respond to server for 30 seconds [2]. Please rejoin.")
                end
            end
        end
    end)
end


function PingService:Init()
    self.Delays = {} --in #of frames. to get time, divide by 60 for approximate
    self.LastReceived = {}

    self:RegisterClientEvent("PingRand")
    self:RegisterClientEvent("PingSend")

    TableUtil = self.Shared.TableUtil
end


return PingService