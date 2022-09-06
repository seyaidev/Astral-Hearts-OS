local CashShop = {}

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
local MarketplaceService = game:GetService("MarketplaceService")

function CashShop.Connect(InterfaceMain)
    InterfaceMain = InterfaceMain

    UserInput = InterfaceMain.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = InterfaceMain.Controllers.Character
    ZoneController = InterfaceMain.Controllers.ZoneController

    SlideButton = InterfaceMain.Modules.SlideButton
    Buttonify = InterfaceMain.Modules.Buttonify
    AutoGrid = InterfaceMain.Modules.AutoGrid

    Gui3DCore = InterfaceMain.Shared["3DGuiCore"]
    Maid = InterfaceMain.Shared.Maid
    TableUtil = InterfaceMain.Shared.TableUtil
    WeaponManipulation = InterfaceMain.Shared.WeaponManipulation
    GlobalData = InterfaceMain.Shared.GlobalData
    GlobalMath = InterfaceMain.Shared.GlobalMath
    Transitions = InterfaceMain.Modules.Transitions
    
    CashShop.Maid = Maid.new()
    CashShop.fMaid = Maid.new()
    table.insert(InterfaceMain.ActiveMaids, CashShop.Maid)
    table.insert(InterfaceMain.ActiveMaids, CashShop.fMaid)

    local function DisplayCashShop(ItemInfo)
        if InterfaceMain.FullMenu == nil then return end
        if InterfaceMain.CashShopTransition then return end
        InterfaceMain.CashShopTransition = true

        local InfoDisplay = InterfaceMain.FullMenu:FindFirstChild("CashShopMenu", true).Info

        InterfaceMain.FullMenu:FindFirstChild("CashShopMenu", true).ImageLabel.Image = "rbxassetid://" .. tostring(ItemInfo._image or 4166019002)

        InfoDisplay:FindFirstChild("Name").Text = ItemInfo._name
        InfoDisplay:FindFirstChild("Description").Text = ItemInfo._desc
        InfoDisplay:FindFirstChild("Action").Title.Text = tostring(ItemInfo._price) .. (ItemInfo._currency and " SayoCredits" or " Robux")
    
        Transitions:TransitionDown(InfoDisplay:FindFirstChild("Name"), false)
        Transitions:TransitionUp(InfoDisplay:FindFirstChild("Name").Line, false)
        Transitions:TransitionUp(InfoDisplay:FindFirstChild("Description"), false)
        
        InfoDisplay:FindFirstChild("Action").Visible = true
        for i, v in pairs(InfoDisplay:FindFirstChild("Action"):GetChildren()) do
            Transitions:TransitionDown(v, false)
        end

        wait(0.45)
        InterfaceMain.CashShopTransition = false
    end

    local function BuildCashShop(Filter)
        if InterfaceMain.FullMenu == nil then return end
        Transitions:ClearTable(InterfaceMain.InventoryButtons)
        -- Transitions:ClearTable(InterfaceMain.ViewportClones)

        -- Desired values in scale
        local PADDING = Vector2.new(0.005, 0.005)
        local SIZE = Vector2.new(1, 0.1)
    
        local ScrollingFrame = InterfaceMain.FullMenu:FindFirstChild("CashShopMenu", true).Items.Display
        local UIGridLayout = ScrollingFrame.UIGridLayout

        local function ResizeCashShop()
            local CellPadding, CellSize, NewCanvas = AutoGrid:Update(PADDING, SIZE, ScrollingFrame.AbsoluteSize, UIGridLayout.AbsoluteContentSize)
            UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            UIGridLayout.CellSize = UDim2.new(0, CellSize.X.Offset, 0, CellSize.Y.Offset-5)
    
            ScrollingFrame.CanvasSize = NewCanvas
        end
        
        if InterfaceMain.cSFMaid then
            InterfaceMain.cSFMaid:DoCleaning()
        end
        if not InterfaceMain.cSFMaid then InterfaceMain.cSFMaid = Maid.new() end
        
        InterfaceMain.cSFMaid:GiveTask(
            UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeCashShop)
        )
    
        InterfaceMain.cSFMaid:GiveTask(
            ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeCashShop)
        )
        table.insert(InterfaceMain.ActiveMaids, InterfaceMain.cSFMaid)

        for i, v in ipairs(ScrollingFrame:GetChildren()) do
            if v:IsA("ImageButton") then
                v:Destroy()
            end
        end

        local Items = InterfaceMain.Services.DevStoreService:GetShop(Filter)
        if Items == nil then return end

        for i,ItemInfo in ipairs(Items) do
            --create image button
            --connect it to a DevStoreService for purchasing

            local InvButton = InterfaceMain.FullMenu.Resources:FindFirstChild("Skill"):Clone()
            InvButton.Name = i
            InvButton.Title.Text = ItemInfo._name
            InvButton.Parent = ScrollingFrame
            
            local ItemButton = InvButton.Button
            local sb = SlideButton:Create(InvButton)

            ItemButton.Activated:Connect(function()
                if InterfaceMain.CashShopTransition then return end
                InterfaceMain.SelectedCashShop = ItemInfo._name
                DisplayCashShop(ItemInfo)
            end)


            table.insert(InterfaceMain.InventoryButtons, InvButton)
        end

        local PurchaseFrame = InterfaceMain.FullMenu.Main.MainPanel.CashShopMenu.Info.Action
        local PurchaseButton = PurchaseFrame:FindFirstChild("Button")

        CashShop.fMaid:DoCleaning()
        CashShop.fMaid:GiveTask(PurchaseButton.Activated:Connect(function()
            --send purchase request to DevStoreService
            if InterfaceMain.SelectedCashShop == nil then return end            
            InterfaceMain.Services.DevStoreService.PromptProductPurchase:Fire(InterfaceMain.SelectedCashShop)
        end))
    end

    local ActivePanel = "Vault"
    local function ConnectButton(v)
        local Button = v:WaitForChild("Button")

        local Gradient = v.Gradient
        local Line = v.Line
        local Title = v.Title
        local Emitter = Gradient.GUIEmitter

        CashShop.Maid:GiveTask(Button.MouseEnter:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0.55, 0), "Out", "Quad", 0.3, true)
            Line:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.1, true)
            Title:TweenPosition(UDim2.new(0, 0, -0.175, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = true
        end))
        
        CashShop.Maid:GiveTask(Button.MouseLeave:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0, 0), "Out", "Quad", 0.1, true)
            if v.Name ~= ActivePanel then
                Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
            end
            Title:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = false
        end))
        
        CashShop.Maid:GiveTask(Button.MouseButton1Down:Connect(function()
            Gradient.ImageTransparency = 0.55
        end))
        
        CashShop.Maid:GiveTask(Button.MouseButton1Up:Connect(function()
            Gradient.ImageTransparency = 0.2
        end))

        CashShop.Maid:GiveTask(Button.Activated:Connect(function()
            --rebuild CashShop
            if ActivePanel == v.Name then return end
            ActivePanel = v.Name
            for j, k in ipairs(v.Parent:GetChildren()) do
                if k.Name ~= v.Name and k:IsA("Frame") then
                    k.Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
                end
            end
            BuildCashShop(v.Name)
        end))
    end

    local TopBar = InterfaceMain.FullMenu.Main.MainPanel.CashShopMenu.TopBar
    for i, v in pairs(TopBar:GetChildren()) do
        if v:IsA("Frame") then
            ConnectButton(v)
        end
    end

    wait(0.1)
    BuildCashShop("Vault")
end

return CashShop