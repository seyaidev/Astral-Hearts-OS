local Skill = {}

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

function Skill.Connect(InterfaceMain)
    InterfaceMain = InterfaceMain

    UserInput = InterfaceMain.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = InterfaceMain.Controllers.Character
    ZoneController = InterfaceMain.Controllers.ZoneController

    Buttonify = InterfaceMain.Modules.Buttonify
    SlideButton = InterfaceMain.Modules.SlideButton
    AutoGrid = InterfaceMain.Modules.AutoGrid

    Gui3DCore = InterfaceMain.Shared["3DGuiCore"]
    Maid = InterfaceMain.Shared.Maid
    TableUtil = InterfaceMain.Shared.TableUtil
    WeaponManipulation = InterfaceMain.Shared.WeaponManipulation
    GlobalData = InterfaceMain.Shared.GlobalData
    GlobalMath = InterfaceMain.Shared.GlobalMath
    Transitions = InterfaceMain.Modules.Transitions

    Skill.Maid = Maid.new()
    Skill.ButtonMaid = Maid.new()

    table.insert(InterfaceMain.ActiveMaids, Skill.Maid)
    table.insert(InterfaceMain.ActiveMaids, Skill.ButtonMaid)

    local SkillCache = InterfaceMain.Shared.Cache:Get("SkillCache")

    local function DisplaySkill(SkillInfo, SkillId, Blob)
        if InterfaceMain.FullMenu == nil then return end
        if InterfaceMain.SkillTransition then return end
        InterfaceMain.SkillTransition = true
        local Blob = InterfaceMain.Controllers.DataBlob.Blob
        
        local SkillDisplay = InterfaceMain.FullMenu:FindFirstChild("SkillDisplay", true)
        SkillDisplay.TitleFrame.Description.Text = SkillInfo.Name
        SkillDisplay.DescFrame.Description.Text = SkillInfo.Description
        SkillDisplay.Cost.Text = "Cost: " .. tostring(SkillInfo.UpgradeCost) .. " Skill Point" .. (SkillInfo.UpgradeCost > 1 and "s" or "")

        if Blob.SkillInfo[SkillId] == nil then
            SkillDisplay:FindFirstChild("UpgradeButton", true).Title.Text = "Learn"
        else
            SkillDisplay:FindFirstChild("UpgradeButton", true).Title.Text = "Upgrade"
        end

        for i,v in ipairs(SkillDisplay.Stats:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        for i, v in pairs(SkillInfo.Stats) do
            local NewStat = InterfaceMain.FullMenu.Resources.Stat:Clone()
            local Value = v
            if Blob.SkillInfo[SkillId] ~= nil then
                if Blob.SkillInfo[SkillId] > 1 then
                    if SkillInfo.Levels[i] then
                        for j = 1, Blob.SkillInfo[SkillId]-1 do
                            Value = Value+SkillInfo.Levels[i][j]
                        end
                    end
                end
            end
            NewStat.Text = tostring(Value) .. " " .. i
            NewStat.Parent = SkillDisplay.Stats
        end

        --create preview viewport (do this last)

        --connect the stuffing
        InterfaceMain.EquippingSkill = false
        
        Skill.ButtonMaid:DoCleaning()
        Skill.ButtonMaid:GiveTask(SkillDisplay:FindFirstChild("Slot1Button", true).Button.Activated:Connect(function()
            if InterfaceMain.EquippingSkill then return end
            InterfaceMain.EquippingSkill = true
            print("equipping", SkillInfo.LocalInfo.SkillId)

            InterfaceMain.Services.PlayerService.EQUIP_SLOT_EVENT:Fire("Slot1", SkillInfo.LocalInfo.SkillId)
            InterfaceMain.EquippingSkill = false
        end))

        Skill.ButtonMaid:GiveTask(SkillDisplay:FindFirstChild("Slot2Button", true).Button.Activated:Connect(function()
            if InterfaceMain.EquippingSkill then return end
            InterfaceMain.EquippingSkill = true
            print("equipping", SkillInfo.LocalInfo.SkillId)
            
            InterfaceMain.Services.PlayerService.EQUIP_SLOT_EVENT:Fire("Slot2", SkillInfo.LocalInfo.SkillId)
            InterfaceMain.EquippingSkill = false
        end))

        Skill.ButtonMaid:GiveTask(SkillDisplay:FindFirstChild("Slot3Button", true).Button.Activated:Connect(function()
            if InterfaceMain.EquippingSkill then return end
            InterfaceMain.EquippingSkill = true
            print("equipping", SkillInfo.LocalInfo.SkillId)

            InterfaceMain.Services.PlayerService.EQUIP_SLOT_EVENT:Fire("Slot3", SkillInfo.LocalInfo.SkillId)
            InterfaceMain.EquippingSkill = false
        end))

            --connect upgrade button
        
            --connect preview button

        --tween in
        local function RecursiveDisplayIn(obj)
            for i, v in ipairs(obj:GetChildren()) do
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

        RecursiveDisplayIn(SkillDisplay)
        wait(0.5)

        if Blob.SkillInfo[SkillId] == SkillInfo.Max then
            SkillDisplay:FindFirstChild("UpgradeButton", true).Visible = false
        else
            SkillDisplay:FindFirstChild("UpgradeButton", true).Visible = true
        end

        Skill.ButtonMaid:GiveTask(SkillDisplay:FindFirstChild("UpgradeButton", true).Button.Activated:Connect(function()
            if InterfaceMain.Upgrading then return end
            InterfaceMain.Upgrading = true
            print("upgrading", SkillInfo.LocalInfo.SkillId)
            local Skilled = InterfaceMain.Services.PlayerService:UpgradeSkill(SkillInfo.LocalInfo.SkillId)
            print("skilled", Skilled)
            if Skilled then
                SkillDisplay:FindFirstChild("UpgradeButton", true).Title.Text = "Upgrade"
                
                if Skilled == SkillInfo.Max then
                    SkillDisplay:FindFirstChild("UpgradeButton", true).Visible = false
                end
                if Skilled == SkillInfo.Max then
                    SkillDisplay:FindFirstChild("UpgradeButton", true).Visible = false
                else
                    SkillDisplay:FindFirstChild("UpgradeButton", true).Visible = true
                end

                for i,v in ipairs(SkillDisplay.Stats:GetChildren()) do
                    if v:IsA("GuiObject") then
                        v:Destroy()
                    end
                end
        
                for i, v in pairs(SkillInfo.Stats) do
                    local NewStat = InterfaceMain.FullMenu.Resources.Stat:Clone()
                    local Value = v
                    if SkillInfo.Levels[i] then
                        for j = 1, Skilled-1 do
                            Value = Value+SkillInfo.Levels[i][j]
                        end
                    end
                    NewStat.Text = tostring(Value) .. " " .. i
                    NewStat.Parent = SkillDisplay.Stats
                end
            end
            InterfaceMain.Upgrading = false
        end))
        InterfaceMain.SkillTransition = false
    end

    local function BuildSkill(Filter)
        local Blob = InterfaceMain.Controllers.DataBlob.Blob
        local Class = Blob.Stats.Class

        local SkillTrees = InterfaceMain.Shared.ClassParams:Get(Class).SkillTrees
        local FilteredTree = SkillTrees[Filter]
        
        InterfaceMain.FullMenu:FindFirstChild("SkillPoints", true).Text = "Skill Points: " .. tostring(Blob.Stats.SkillPoints)

        local SkillList = InterfaceMain.FullMenu:FindFirstChild("SkillList", true)

        for i, v in ipairs(SkillList:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        local PADDING = Vector2.new(0, 0)
        local SIZE = Vector2.new(1, 0.15)

        local ScrollingFrame = InterfaceMain.FullMenu:FindFirstChild("SkillList", true)
        local UIGridLayout = ScrollingFrame.UIGridLayout

        local function ResizeFrame()
            local CellPadding, CellSize, NewCanvas = AutoGrid:Update(PADDING, SIZE, ScrollingFrame.AbsoluteSize, UIGridLayout.AbsoluteContentSize)
            UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            UIGridLayout.CellSize = UDim2.new(0, CellSize.X.Offset-5, 0, CellSize.Y.Offset-5)
    
            ScrollingFrame.CanvasSize = NewCanvas
        end

        InterfaceMain.sSFMaid = Maid.new()

        InterfaceMain.sSFMaid:GiveTask(
            UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeFrame)
        )
    
        InterfaceMain.sSFMaid:GiveTask(
            ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeFrame)
        )
        
        table.insert(InterfaceMain.ActiveMaids, InterfaceMain.sSFMaid)

        for _, SkillId in ipairs(FilteredTree) do
            local SkillInfo = SkillCache:Get(SkillId)
            if SkillInfo then
                --create button
                local NewSkillButton = InterfaceMain.FullMenu.Resources.Skill:Clone()
                NewSkillButton.Title.Text = SkillInfo.Name
                if Blob.SkillInfo[SkillId] then
                    NewSkillButton.Subtext.Text = "Lv. " .. tostring(Blob.SkillInfo[SkillId])
                else
                    NewSkillButton.Subtext.Text = "Unlearned"
                end

                NewSkillButton.Parent = SkillList

                local bmaid = SlideButton:Create(NewSkillButton)
                table.insert(InterfaceMain.ActiveMaids, bmaid)

                NewSkillButton.Button.Activated:Connect(function()
                    DisplaySkill(SkillInfo, SkillId, Blob)
                end)
            end
        end
    end

    local Blob = InterfaceMain.Controllers.DataBlob.Blob
    local ClassPromotion = Blob.Stats.ClassPromotion

    local ActivePanel = "1"
    local function ConnectButton(v, valid)
        local Button = v:WaitForChild("Button")

        local Gradient = v.Gradient
        local Line = v.Line
        local Title = v.Title
        local Emitter = Gradient.GUIEmitter

        if not valid then
            Title.TextTransparency = 0.8
            Line.BackgroundTransparency = 0.8
            Line.Size = UDim2.new(0, 0, 0, 2)
            return
        end
        
        Title.TextTransparency = 0
        Line.BackgroundTransparency = 0

        Skill.Maid:GiveTask(Button.MouseEnter:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0.55, 0), "Out", "Quad", 0.3, true)
            Line:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.1, true)
            Title:TweenPosition(UDim2.new(0, 0, -0.175, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = true
        end))
        
        Skill.Maid:GiveTask(Button.MouseLeave:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0, 0), "Out", "Quad", 0.1, true)
            if v.Name ~= ActivePanel then
                Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
            end
            Title:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = false
        end))
        
        Skill.Maid:GiveTask(Button.MouseButton1Down:Connect(function()
            Gradient.ImageTransparency = 0.55
        end))
        
        Skill.Maid:GiveTask(Button.MouseButton1Up:Connect(function()
            Gradient.ImageTransparency = 0.2
        end))

        Skill.Maid:GiveTask(Button.Activated:Connect(function()
            --rebuild Skill
            ActivePanel = v.Name
            for j, k in ipairs(v.Parent:GetChildren()) do
                if k.Name ~= v.Name and k:IsA("Frame") then
                    k.Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
                end
            end
            BuildSkill(tonumber(v.Name))
        end))
    end

    local TopBar = InterfaceMain.FullMenu.Main.MainPanel.SkillsMenu.TopBar
    for i, v in pairs(TopBar:GetChildren()) do
        if v:IsA("Frame") then
            if tonumber(v.Name) > ClassPromotion then
                v.Visible = false
                ConnectButton(v, false)
            else
                v.Visible = true
                ConnectButton(v, true)
            end
        end
    end

    Skill.Maid:GiveTask(InterfaceMain.Services.PlayerService.UpdateBlob:Connect(function(newblob)
        for i, SkillId in pairs(newblob.ActiveSkills) do
            local SkillInfo = SkillCache:Get(SkillId)
            local Slot = InterfaceMain.FullMenu.Main.MainPanel.SkillsMenu.EquippedSkills:FindFirstChild(i)
            if SkillInfo then
                if Slot then
                    Slot.SkillName.Text = SkillInfo.Name
                end
            else
                if Slot then
                    Slot.SkillName.Text = ""
                end
            end

            BuildSkill(tonumber(ActivePanel))
        end
    end))
    
    for i, v in ipairs(InterfaceMain.FullMenu.Main.MainPanel.SkillsMenu.EquippedSkills:GetChildren()) do
        if v:IsA("GuiObject") then
            Skill.Maid:GiveTask(v:FindFirstChild("Button", true).Activated:Connect(function()
                InterfaceMain.Services.PlayerService.EQUIP_SLOT_EVENT:Fire(v.Name, "")
            end))
        end
    end

    BuildSkill(1)
end

return Skill