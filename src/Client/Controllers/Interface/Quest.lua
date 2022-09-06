--viewport size UDim2.new(1, 0, 0.45, 0)

local Quest = {}

local InterfaceMain
local UserInput
local Keyboard
local Gamepad
local CharacterController
local ZoneController
local Buttonify
local AutoGrid
local Gui3DCore
local Maid
local TableUtil
local WeaponManipulation
local GlobalData
local GlobalMath

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

function Quest.Connect(InterfaceMain)
    InterfaceMain = InterfaceMain

    UserInput = InterfaceMain.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = InterfaceMain.Controllers.Character
    ZoneController = InterfaceMain.Controllers.ZoneController

    Buttonify = InterfaceMain.Modules.Buttonify
    AutoGrid = InterfaceMain.Modules.AutoGrid

    Gui3DCore = InterfaceMain.Shared["3DGuiCore"]
    Maid = InterfaceMain.Shared.Maid
    TableUtil = InterfaceMain.Shared.TableUtil

    GlobalData = InterfaceMain.Shared.GlobalData
    GlobalMath = InterfaceMain.Shared.GlobalMath
    Transitions = InterfaceMain.Modules.Transitions
    
    Quest.Maid = Maid.new()
    Quest.DropMaid = Maid.new()
    Quest.ConfirmMaid = Maid.new()

    table.insert(InterfaceMain.ActiveMaids, Quest.Maid)
    table.insert(InterfaceMain.ActiveMaids, Quest.DropMaid)
    table.insert(InterfaceMain.ActiveMaids, Quest.ConfirmMaid)

    local function DisplayQuest(QuestData)
        if InterfaceMain.FullMenu == nil then return end
        if InterfaceMain.QuestTransition then return end
        InterfaceMain.QuestTransition = true

        local QuestDisplay = InterfaceMain.FullMenu:FindFirstChild("QuestInfo", true)
        QuestDisplay.Title.Description.Text = QuestData.DisplayName
        QuestDisplay.DescFrame.Description.Text = QuestData.Desc

        for i,v in ipairs(QuestDisplay.Objectives:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        for ObjectiveType, ObjectiveTable in pairs(QuestData.Objectives) do
			for Target, Objective in pairs(ObjectiveTable) do

				local pattern = "%u+%l*"
				local NewName = ""
				for v in Target:gmatch(pattern) do
					NewName = NewName .. v .. " "
				end
				if string.len(NewName) > 1 then
					NewName = string.sub(NewName, 1, string.len(NewName)-1)
				end

                

                local NewObjective = InterfaceMain.FullMenu.Resources.Item:Clone()
                NewObjective.Visible = true

                if ObjectiveType == "KILL" or ObjectiveType == "GATHER" then
                    NewObjective.Text = ":: [" .. ObjectiveType .. "] " .. tostring(Objective) .. " " .. NewName .. (Objective > 1 and "s." or ".") .. " (" .. tostring(QuestData.Progress[ObjectiveType][Target]) .. "/" .. tostring(Objective) .. ")"
        
				elseif ObjectiveType == "TALK" then
					NewObjective.Text = ":: TALK to " .. NewName 
                end
                
                NewObjective.Parent = QuestDisplay.Objectives
			end
        end

        
        
        for i,v in ipairs(QuestDisplay.Rewards:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        for RewardName, Reward in pairs(QuestData.Rewards) do
            if typeof(Reward) == "number" then
                local rname = RewardName
                if RewardName == "GOLD" then
                    rname = "Munny"
                end
                local NewReward = InterfaceMain.FullMenu.Resources.Item:Clone()
                NewReward.Text = tostring(Reward) .. " " .. rname
                NewReward.Parent = QuestDisplay.Rewards
            elseif typeof(Reward) == "table" then
                for i, item in pairs(Reward) do
                    local NewReward = InterfaceMain.FullMenu.Resources.Item:Clone()
                    NewReward.Text = item
                    NewReward.Parent = QuestDisplay.Rewards
                end
            end
        end

        local function RecursiveDisplayIn(obj, confirmcheck)
            for i, v in ipairs(obj:GetChildren()) do
                if v.Name ~= "Confirm" and v.Name ~= "Cancel" and not confirmcheck then
                    if CollectionService:HasTag(v, "TransitionDown") then
                        Transitions:TransitionDown(v, false)
                    elseif CollectionService:HasTag(v, "TransitionUp") then
                        Transitions:TransitionUp(v, false)
                    end

                    if #v:GetChildren() > 0 then
                        delay(0.05, function()
                            RecursiveDisplayIn(v)
                        end)
                    end
                elseif confirmcheck then
                    if CollectionService:HasTag(v, "TransitionDown") then
                        Transitions:TransitionDown(v, false)
                    elseif CollectionService:HasTag(v, "TransitionUp") then
                        Transitions:TransitionUp(v, false)
                    end

                    if #v:GetChildren() > 0 then
                        delay(0.05, function()
                            RecursiveDisplayIn(v)
                        end)
                    end
                end
            end
        end

        local function RecursiveDisplayOut(obj)
            for i, v in ipairs(obj:GetChildren()) do
                Transitions:TweenOut(v)

                if #v:GetChildren() > 0 then
                    delay(0.05, function()
                        RecursiveDisplayOut(v)
                    end)
                end
            end
        end

        --connect drop button
        Quest.DropMaid:GiveTask(QuestDisplay.DropButton.Button.Activated:Connect(function()
            --display confirm
            RecursiveDisplayIn(QuestDisplay.DropConfirm, true)


            Quest.ConfirmMaid:GiveTask(QuestDisplay.DropConfirm.Cancel.Button.Activated:Connect(function()
                for i, v in ipairs(QuestDisplay.DropConfirm:GetChildren()) do
                    for j, k in pairs(v:GetChildren()) do k.Visible = false end
                    v.Visible = false
                end

                Quest.ConfirmMaid:DoCleaning()
            end))

            Quest.ConfirmMaid:GiveTask(QuestDisplay.DropConfirm.Confirm.Button.Activated:Connect(function()
                for i, v in ipairs(QuestDisplay.DropConfirm:GetChildren()) do
                    for j, k in pairs(v:GetChildren()) do k.Visible = false end
                    v.Visible = false
                end

                print('dropping quest', QuestData.Id)
                Quest.ConfirmMaid:DoCleaning()
                Quest.DropMaid:DoCleaning()

                InterfaceMain.Services.QuestService.RemoveQuest:Fire(QuestData.Id)
                InterfaceMain.QuestTransition = true
                RecursiveDisplayOut(QuestDisplay)
                wait(0.5)
                InterfaceMain.QuestTransition = false
            end))
        end))

        -- print('connected')
        RecursiveDisplayIn(QuestDisplay)
        wait(0.5)
        InterfaceMain.QuestTransition = false
    end

    local function BuildQuest(Filter)
        if InterfaceMain.FullMenu == nil then return end

        local QuestBlob = InterfaceMain.Controllers.QuestController.QuestBlob
        
        local QuestList = InterfaceMain.FullMenu:FindFirstChild("QuestList", true)
        for i, v in ipairs(QuestList:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        local PADDING = Vector2.new(0, 0)
        local SIZE = Vector2.new(1, 0.07)

        local ScrollingFrame = InterfaceMain.FullMenu:FindFirstChild("QuestList", true)
        local UIGridLayout = ScrollingFrame.UIGridLayout

        local function ResizeFrame()
            local CellPadding, CellSize, NewCanvas = AutoGrid:Update(PADDING, SIZE, ScrollingFrame.AbsoluteSize, UIGridLayout.AbsoluteContentSize)
            UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            UIGridLayout.CellSize = UDim2.new(0, CellSize.X.Offset-5, 0, CellSize.Y.Offset-5)
    
            ScrollingFrame.CanvasSize = NewCanvas
        end

        InterfaceMain.qSFMaid = Maid.new()

        InterfaceMain.qSFMaid:GiveTask(
            UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeFrame)
        )
    
        InterfaceMain.qSFMaid:GiveTask(
            ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeFrame)
        )
    
        table.insert(InterfaceMain.ActiveMaids, InterfaceMain.qSFMaid)

        for QuestId, QuestData in pairs(QuestBlob[Filter]) do
            local NewQuestButton = InterfaceMain.FullMenu.Resources.Quest:Clone()
            NewQuestButton.Title.Text = QuestData.DisplayName
            NewQuestButton.Parent = QuestList
            NewQuestButton.Visible = true
            Buttonify:Create(NewQuestButton)

            NewQuestButton.Button.Activated:Connect(function()
                DisplayQuest(QuestData)
            end)
        end
    end

    local ActivePanel = "InProgress"
    local function ConnectButton(v)
        local Button = v:WaitForChild("Button")

        local Gradient = v.Gradient
        local Line = v.Line
        local Title = v.Title
        local Emitter = Gradient.GUIEmitter

        Quest.Maid:GiveTask(Button.MouseEnter:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0.55, 0), "Out", "Quad", 0.3, true)
            Line:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.1, true)
            Title:TweenPosition(UDim2.new(0, 0, -0.175, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = true
        end))
        
        Quest.Maid:GiveTask(Button.MouseLeave:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0, 0), "Out", "Quad", 0.1, true)
            if v.Name ~= ActivePanel then
                Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
            end
            Title:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = false
        end))
        
        Quest.Maid:GiveTask(Button.MouseButton1Down:Connect(function()
            Gradient.ImageTransparency = 0.55
        end))
        
        Quest.Maid:GiveTask(Button.MouseButton1Up:Connect(function()
            Gradient.ImageTransparency = 0.2
        end))

        Quest.Maid:GiveTask(Button.Activated:Connect(function()
            --rebuild Quest
            ActivePanel = v.Name
            for j, k in ipairs(v.Parent:GetChildren()) do
                if k.Name ~= v.Name and k:IsA("Frame") then
                    k.Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
                end
            end
            BuildQuest(v.Name)
        end))
    end

    local TopBar = InterfaceMain.FullMenu.Main.MainPanel.QuestsMenu.TopBar
    for i, v in pairs(TopBar:GetChildren()) do
        if v:IsA("Frame") then
            ConnectButton(v)
        end
    end

    Quest.Maid:GiveTask(InterfaceMain.Services.QuestService.ForceUpdate:Connect(function(Blob)
        InterfaceMain.Controllers.QuestController.QuestBlob = InterfaceMain.Services.QuestService:ReturnQuestData()
        BuildQuest(ActivePanel)
    end))

    BuildQuest("InProgress")
    ActivePanel = "InProgress"
end

return Quest