-- Notification Controller
-- Username
-- October 23, 2019

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local NotificationController = {}

--[[
        {
            Text = "Completed quest: " .. QuestData.DisplayName;
            Time = 4;
        }

--]]

function NotificationController:Start()
    local NotifStack = ReplicatedStorage.Assets:FindFirstChild("NotificationStack", true)
    self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        self.NotificationStack = NotifStack:Clone()
        self.NotificationStack.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end)


    local function CreateNotif(Info)
        -- print(repr(Info))
        if self.NotificationStack == nil then return end
        local NotifSource = self.NotificationStack.Resources:FindFirstChild("Notification"):Clone()
        if NotifSource == nil then return end
        local Notif = NotifSource:Clone()
        Notif.Visible = true
        local Label = Notif:FindFirstChild("Label", true)
        Label.Text = Info.Text
        
        local origb = Label.BackgroundTransparency
        Label.TextStrokeTransparency = 1
        Label.TextTransparency = 1
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 0, -1, 0)

        Notif.Parent = self.NotificationStack:FindFirstChild("Main")
        TweenService:Create(Label, TweenInfo.new(0.75, Enum.EasingStyle.Back), {
            TextStrokeTransparency = 0.5;
            TextTransparency = 0;
            BackgroundTransparency = origb;
            Position = UDim2.new(0,0,0,0);
        }):Play()
        delay(Info.Time, function()
            TweenService:Create(Label, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                TextStrokeTransparency = 1;
                TextTransparency = 1;
                BackgroundTransparency = 1;
                Position = UDim2.new(0,0,1,0);
            }):Play()
        end)

        Debris:AddItem(Notif, Info.Time+1)
    end

    self:ConnectEvent("Notify", CreateNotif)
    self.Services.PlayerService.NotifyPlayer:Connect(CreateNotif)
end


function NotificationController:Init()
    self:RegisterEvent("Notify")
    repr = self.Shared.repr
end


return NotificationController