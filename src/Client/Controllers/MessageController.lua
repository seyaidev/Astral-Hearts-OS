-- Message Controller
-- oniich_n
-- July 16, 2019



local MessageController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--[[
    MessageInfo = {
        Id = string;
        Pages = {
            [1] = {
                Title = string;
                Image = number;
                Boxes = {
                    [1] = {
                        Subtitle = string;
                        SubtitleColor = Color3;
                        Description = string;
                    }
                }
            }
        }
    }
]]


function MessageController:ClearMessage()

end

function MessageController:Start()

    CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function()
        self.Maid:DoCleaning()
    end)

    local function DisplayMessage(MessageInfo)
        if typeof(MessageInfo) ~= "table" then print ("MessageInfo not a table") return end

        local Character = self.Player.Character

        if Character.PrimaryPart then
            self.Controllers.StateController.CharacterState.reset()
            Character.Humanoid.WalkSpeed = 0
            delay(1, function()
                Character.PrimaryPart.Anchored = true
            end)
        end


        local SourceMsg = ReplicatedStorage.Assets.Interface:FindFirstChild("Message")
        if SourceMsg == nil then return end
        local NewMessage = SourceMsg:Clone()
        NewMessage.Name = MessageInfo.Id

        local Counter = 1
        for i, PageInfo in pairs(MessageInfo.Pages) do
            local NewPage = NewMessage:WaitForChild("PageTemplate"):Clone()
            NewPage.Name = "Page" .. tostring(i)
            NewPage.Title.Text = PageInfo.Title

            NewPage.Image.Image = "rbxassetid://" .. tostring(PageInfo.Image)
            NewPage.Image.BackgroundTransparency = 1
            for j, BoxInfo in pairs(PageInfo.Boxes) do
                local NewBox = NewPage.TextFrame.TextTemplate:Clone()
                NewBox.Subtitle.Text = BoxInfo.Subtitle
                NewBox.Subtitle.TextColor3 = BoxInfo.SubtitleColor
                NewBox.Description.Text = BoxInfo.Description

                NewBox.LayoutOrder = j
                NewBox.Parent = NewPage.TextFrame
            end
            NewPage.TextFrame.TextTemplate:Destroy()

            NewPage.LayoutOrder = i
            NewPage.Visible = false
            NewPage.Parent = NewMessage
        end
        NewMessage.PageTemplate:Destroy()

        local IntroTweens = {}
        local function fIntroTween(PageNum)
            IntroTweens = {}
            
            local Page = NewMessage:FindFirstChild("Page" .. tostring(PageNum))
            Page:FindFirstChild("Page", true).Text = tostring(PageNum) .. "/" .. tostring(#MessageInfo.Pages)
            Page.BackgroundTransparency = 1
            Page.Position = UDim2.new(1, 0, 0.5, 0)
            Page:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.7, true)
            Page.Visible = true
            delay(3.5, function()
                if Page:FindFirstChild("Continue", true) == nil then return end
                Page:FindFirstChild("Continue", true).Visible = true
            end)
            for i, v in pairs(Page:GetDescendants()) do
                if v:IsA("GuiObject") then
                    local t = IntroTween(v)
                    table.insert(IntroTweens, t)
                end
            end
            
            table.sort(IntroTweens, function(a, b)
                local cpos = Vector2.new(0, 0)
                local distA = (cpos-a[1]).Magnitude
                local distB = (cpos-b[1]).Magnitude
                
                return distA < distB
            end)

            for i, v in pairs(IntroTweens) do
                FastSpawn(function()
                    v[2]:Play()
                end)
            end

            
        end

        local function OutroPage(PageNum)
            local OutroTweens = {}
        
            local Page = NewMessage:FindFirstChild("Page" .. tostring(PageNum))
            Page:TweenPosition(UDim2.new(-0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.8, true)
            for i, v in pairs(Page:GetDescendants()) do
                if v:IsA("GuiObject") then
                    local t = OutroTween(v)
                    table.insert(OutroTweens, t)
                end
            end
            
            table.sort(OutroTweens, function(a, b)
                local cpos = Vector2.new(0, 0)
                local distA = (cpos-a[1]).Magnitude
                local distB = (cpos-b[1]).Magnitude
                
                return distA < distB
            end)

            for i, v in pairs(OutroTweens) do
                v[2]:Play()
            end
            
            delay(1, function() Page.Visible = false end)
        end

        local IsTweening = false
        local function NextPage(dir)
            if IsTweening then return end
            IsTweening = true
            OutroPage(Counter)
            wait(0.2)
            if dir then
                Counter = Counter + 1
            else 
                Counter = Counter - 1
            end
            fIntroTween(Counter)
            wait(3.25)
            IsTweening = false
        end

        local function CloseFunction()
            local OutroTweens = {}

            local Page = NewMessage:FindFirstChild("Page" .. tostring(#MessageInfo.Pages))
            Page:TweenPosition(UDim2.new(-0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.8, true)
            for i, v in pairs(Page:GetDescendants()) do
                if v:IsA("GuiObject") then
                    local t = OutroTween(v)
                    table.insert(OutroTweens, t)
                end
            end
            
            table.sort(OutroTweens, function(a, b)
                local cpos = Vector2.new(0, 0)
                local distA = (cpos-a[1]).Magnitude
                local distB = (cpos-b[1]).Magnitude
                
                return distA < distB
            end)

            for i, v in pairs(OutroTweens) do
                v[2]:Play()
            end
            TweenService:Create(NewMessage.Background, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()

            wait(1)
            NewMessage:Destroy()
            -- MovementController.IsActive = true
            self.Controllers.StateController.CharacterState.reset()
            if Character.PrimaryPart then
                Character.PrimaryPart.Anchored = false
                Character.Humanoid.WalkSpeed = 22
            end
        end

        NewMessage.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        self.ActiveMessage = true
        self.Controllers.StateController.CharacterState.message()
        local ot = NewMessage.Background.BackgroundTransparency
        NewMessage.Background.BackgroundTransparency = 1
        TweenService:Create(NewMessage.Background, TweenInfo.new(0.7), {BackgroundTransparency = ot}):Play()
        wait(0.5)
        fIntroTween(1)
        wait(1.75)

        local ThisMaid = Maid.new()
        ThisMaid:GiveTask(UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if self.Player:WaitForChild("PlayerGui"):FindFirstChild("LoadingFrame") then return end
                if IsTweening then return end
                if Counter == #MessageInfo.Pages then
                    CloseFunction()
                    self.ActiveMessage = false
                    if ThisMaid ~= nil then
                        ThisMaid:DoCleaning()
                        ThisMaid = nil
                    end
                else
                    NextPage(true)
                end
            end
        end))

        print("Created new message")
    end

    local InitialSpawn = true
    CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        self.Maid:GiveTask(MessagingService.SEND_MESSAGE_CLIENT_EVENT:Connect(DisplayMessage))

        if InitialSpawn then
            MessagingService.LOADED_CLIENT:Fire()
            InitialSpawn = false
        end
        print("Loaded message")
    end)

    self:ConnectEvent("DisplayMessage", DisplayMessage)
end


function MessageController:Init()

    self:RegisterEvent("DisplayMessage")

    self.ActiveMessage = false

    IntroTween = self.Modules.IntroTween
    OutroTween = self.Modules.OutroTween

    MessagingService = self.Services.MessageService
    CharacterController = self.Controllers.Character

    FastSpawn = self.Shared.FastSpawn
    Maid = self.Shared.Maid

    self.Maid = Maid.new()
end


return MessageController