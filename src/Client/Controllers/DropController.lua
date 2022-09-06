-- Drop Controller
-- oniich_n
-- October 22, 2019


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropBase = ReplicatedStorage.Assets.Particles:WaitForChild("DropBubble")

local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local DropController = {}

function DropController:Destroy(Marker)
    if self.Drops[Marker] then
        CollectionService:RemoveTag(Marker.PrimaryPart, "Targetable")
        Debris:AddItem(Marker, 2)
        self.Drops[Marker] = nil
        for i, v in ipairs(Marker:GetDescendants()) do
            if v:IsA("BasePart") then
                TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Position = v.Position + Vector3.new(0, 2, 0);
                    Transparency = 1;
                }):Play()
            elseif v:IsA("ParticleEmitter") then
                v.Enabled = false
            end
        end
    end
end

function DropController:Start()
    
    -- FastSpawn(function()
    --     while true do
    --         wait(0.1)
    --         for Marker, DropInfo in pairs(self.Drops) do
    --             if DropInfo.Timeout <= 0 then
    --                 if Marker:FindFirstAncestor("Workspace") then
    --                     self:Destroy(Marker)
    --                 end
    --                 self.Drops[Marker] = nil
    --                 continue
    --             end

    --             DropInfo.Timeout = DropInfo.Timeout-(0.1)
    --         end
    --     end
    -- end)

    local Debounce = false
    local function collectDrop(Marker)
        if Debounce then return end
            Debounce = true
            --check to make sure target is a drop
            --get drop info by target
            if self.Drops[Marker] ~= nil then
                --tell server that drop was
                local DropInfo = self.Drops[Marker]
                local Collected = self.Services.DropService:CollectDrop(DropInfo.Id)
                if Collected then
                    self:Destroy(Marker)
                end
            end
        Debounce = false
    end

    UserInputService.InputBegan:Connect(function(input)
        if self.Controllers.Targeting.TargetInstance ~= nil and input.KeyCode == Enum.KeyCode.Z then
            local Marker = self.Controllers.Targeting.TargetInstance.Parent
            collectDrop(Marker)
        end
    end)

    local LastTrigger
    game:GetService("RunService").Heartbeat:Connect(function()
        local MarkerChild = self.Controllers.Targeting.TargetInstance
        if MarkerChild ~= nil then
            if self.Drops[MarkerChild.Parent] ~= nil then
                local Marker = MarkerChild.Parent
                
                local newTrigger = self.Drops[Marker].Trigger
                if newTrigger then
                    if LastTrigger ~= newTrigger then
                        if LastTrigger ~= nil then
                            LastTrigger.Enabled = false
                        end
                        LastTrigger = newTrigger
                        

                        print("Connected drop trigger")
                    end    
                    
                    newTrigger.Enabled = true
                    if GIC.LastInput == Enum.UserInputType.Keyboard then
                        newTrigger.Button.Text = "[Z] Collect"
                    end
        
                    if GIC.LastInput == Enum.UserInputType.Touch or GIC.TouchEnabled then
                        newTrigger.Button.Text = "[Tap] Collect"
                    end
                    return
                end
            end
        end

        if LastTrigger ~= nil then
            LastTrigger.Enabled = false
        end
    end)

    DropService.DROP_SEND_CLIENT:Connect(function(DropInfo)
        --clone drop indicator
        --place drop indicator
        --add to drop queue
        local NewDrop = DropBase:Clone()
        DropInfo["TimeElapsed"] = 0
        NewDrop:SetPrimaryPartCFrame(CFrame.new(DropInfo.Position+Vector3.new(0, 1, 0)))
        NewDrop.Parent = workspace.Trash

        local CollectTrigger = ReplicatedStorage.Assets:FindFirstChild("CollectTrigger", true):Clone()
        CollectTrigger.Parent = self.Player:WaitForChild("PlayerGui")
        CollectTrigger:WaitForChild("Button").Activated:Connect(function()
            print('trigered')
            collectDrop(NewDrop)
        end)
        CollectTrigger.Adornee = NewDrop
        DropInfo.Trigger = CollectTrigger
        self.Drops[NewDrop] = DropInfo

    end)

    DropService.RemoveDrop:Connect(function(DropId)
        -- search for drop, then remove it
        for Marker, DropInfo in pairs(self.Drops) do
            if DropInfo.Id == DropId then
                self:Destroy(Marker)
                return
            end
        end
    end)
end


function DropController:Init()
    self.Drops = {}

    CharacterController = self.Controllers.Character
    DropService = self.Services.DropService
    FastSpawn = self.Shared.FastSpawn
    GIC = self.Controllers.GlobalInputController
    
    Maid = self.Shared.Maid
    self.TriggerMaid = Maid.new()
end


return DropController