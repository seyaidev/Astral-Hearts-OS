local Inbox = {}

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
local GlobalData
local GlobalMath

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

function Inbox.Connect(InterfaceMain)
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
    repr = InterfaceMain.Shared.repr
    Transitions = InterfaceMain.Modules.Transitions

    Inbox.Maid = Maid.new()
    Inbox.DiscardMaid = Maid.new()
    Inbox.ConfirmMaid = Maid.new()
    table.insert(InterfaceMain.ActiveMaids, Inbox.Maid)
    table.insert(InterfaceMain.ActiveMaids, Inbox.DiscardMaid)
    table.insert(InterfaceMain.ActiveMaids, Inbox.ConfirmMaid)

    local function DisplayInbox(LetterInfo)
        if InterfaceMain.FullMenu == nil then return end
        if InterfaceMain.InboxTransition then return end
        InterfaceMain.InboxTransition = true

        local InboxDisplay = InterfaceMain.FullMenu:FindFirstChild("MailInfo", true)
        InboxDisplay.TitleFrame.Description.Text = LetterInfo.Title
        InboxDisplay.DescFrame.Description.Text = LetterInfo.Message

        for i,v in ipairs(InboxDisplay.Gifts:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        if LetterInfo.Gifts.Items then
            for i,v in ipairs(LetterInfo.Gifts.Items) do
                local ItemName = InterfaceMain.Shared.Cache:Get("ItemLibrary")[v].Name
                local NewStat = InterfaceMain.FullMenu.Resources.Item:Clone()
                NewStat.Text = ":: " .. ItemName
                NewStat.Parent = InboxDisplay.Gifts
            end
        end

        for i, v in pairs(LetterInfo.Gifts) do
            if i == "Munny" or i == "EXP" or i == "SayoCredits" then
                local NewStat = InterfaceMain.FullMenu.Resources.Item:Clone()
                NewStat.Text = ":: " .. tostring(v) .. " " .. i
                NewStat.Parent = InboxDisplay.Gifts
            end
        end

        if LetterInfo.ExpireDate < 1 then
            InboxDisplay.ExpireDate.Title.Text = "Never expires!"
        end

        --create preview viewport (do this last)

        --connect the stuffing

        --tween in
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

        Inbox.Maid:GiveTask(InboxDisplay:FindFirstChild("AcceptButton", true).Button.Activated:Connect(function()
            for i, v in ipairs(InboxDisplay.DiscardConfirm:GetChildren()) do
                for j, k in pairs(v:GetChildren()) do k.Visible = false end
                v.Visible = false
            end

            Inbox.ConfirmMaid:DoCleaning()
            Inbox.DiscardMaid:DoCleaning()

            InterfaceMain.Services.MailService.AcceptGifts:Fire(LetterInfo.Id)

            InterfaceMain.InboxTransition = true
            RecursiveDisplayOut(InboxDisplay)
            wait(0.5)
            InterfaceMain.InboxTransition = false
            local b = InboxDisplay.Parent:FindFirstChild(LetterInfo.Id, true)
            if b then b:Destroy() end
            InterfaceMain:FireEvent("GiftRebuild")
            -- InterfaceMain:MenuClose()
        end))

        --connect discard

        Inbox.DiscardMaid:GiveTask(InboxDisplay.DiscardButton.Button.Activated:Connect(function()
            --display confirm
            RecursiveDisplayIn(InboxDisplay.DiscardConfirm, true)


            Inbox.ConfirmMaid:GiveTask(InboxDisplay.DiscardConfirm.Cancel.Button.Activated:Connect(function()
                for i, v in ipairs(InboxDisplay.DiscardConfirm:GetChildren()) do
                    for j, k in pairs(v:GetChildren()) do k.Visible = false end
                    v.Visible = false
                end

                Inbox.ConfirmMaid:DoCleaning()
            end))

            Inbox.ConfirmMaid:GiveTask(InboxDisplay.DiscardConfirm.Confirm.Button.Activated:Connect(function()
                for i, v in ipairs(InboxDisplay.DiscardConfirm:GetChildren()) do
                    for j, k in pairs(v:GetChildren()) do k.Visible = false end
                    v.Visible = false
                end

                Inbox.ConfirmMaid:DoCleaning()
                Inbox.DiscardMaid:DoCleaning()

                InterfaceMain.Services.MailService.DiscardLetter:Fire(LetterInfo.Id)

                InterfaceMain.InboxTransition = true
                RecursiveDisplayOut(InboxDisplay)
                wait(0.5)
                InterfaceMain.InboxTransition = false
                InboxDisplay.Parent:FindFirstChild(LetterInfo.Id, true):Destroy()
            end))
        end))

        

        RecursiveDisplayIn(InboxDisplay)
        wait(0.5)
        InterfaceMain.InboxTransition = false
    end

    local function BuildInbox()
        local MailList = InterfaceMain.FullMenu:FindFirstChild("MailList", true)

        for i, v in ipairs(MailList:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        local PADDING = Vector2.new(0, 0)
        local SIZE = Vector2.new(1, 0.07)

        local ScrollingFrame = InterfaceMain.FullMenu:FindFirstChild("MailList", true)
        local UIGridLayout = ScrollingFrame.UIGridLayout

        local function ResizeFrame()
            local CellPadding, CellSize, NewCanvas = AutoGrid:Update(PADDING, SIZE, ScrollingFrame.AbsoluteSize, UIGridLayout.AbsoluteContentSize)
            UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            UIGridLayout.CellSize = UDim2.new(0, CellSize.X.Offset-5, 0, CellSize.Y.Offset-5)
    
            ScrollingFrame.CanvasSize = NewCanvas
        end

        InterfaceMain.iSFMaid = Maid.new()

        InterfaceMain.iSFMaid:GiveTask(
            UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeFrame)
        )
    
        InterfaceMain.iSFMaid:GiveTask(
            ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeFrame)
        )
        
        table.insert(InterfaceMain.ActiveMaids, InterfaceMain.iSFMaid)

        local InboxBlob = InterfaceMain.Services.MailService:GetBlob()
        -- print(repr(InboxBlob))
        if InboxBlob == nil then
            repeat
                InboxBlob = InterfaceMain.Services.MailService:GetBlob()
                wait(1)
            until InboxBlob
        end
        for LetterId, LetterInfo in pairs(InboxBlob.Available) do
            if LetterInfo then
                -- print(LetterId)
                -- print(repr(LetterInfo))
                --create button
                local NewLetterButton = InterfaceMain.FullMenu.Resources.Letter:Clone()
                NewLetterButton.Name = LetterInfo.Id
                NewLetterButton.Title.Text = LetterInfo.Name

                NewLetterButton.Parent = MailList

                local bmaid = Buttonify:Create(NewLetterButton)
                table.insert(InterfaceMain.ActiveMaids, bmaid)

                NewLetterButton.Button.Activated:Connect(function()
                    DisplayInbox(LetterInfo, InboxId)
                end)
            end
        end
    end

    local CodeBox = InterfaceMain.FullMenu:FindFirstChild("CodeBox", true)
    Inbox.Maid:GiveTask(CodeBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local process
            delay(0.05, function() CodeBox.Text = "PROCESSING" end)
            process = InterfaceMain.Services.MailService:RedeemCode(CodeBox.Text)
            repeat wait() until process ~= nil
            -- wait(0.2)
            if process == true then
                BuildInbox()
                CodeBox.Text = ""
            elseif typeof(process) == "string" then
                CodeBox.Text = process
                wait(3)
                CodeBox.Text = ""
            end
        end
    end))

    Inbox.Maid:GiveTask(InterfaceMain.Services.MailService.LetterReceived:Connect(function()
        BuildInbox()
    end))

    BuildInbox()
end

return Inbox