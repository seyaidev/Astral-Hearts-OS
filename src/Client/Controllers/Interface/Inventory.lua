local Inventory = {}

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
local Attachments = require(ReplicatedStorage:FindFirstChild("Attachments", true))

function Inventory.Connect(InterfaceMain)
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
    
    Inventory.Maid = Maid.new()
    Inventory.CharacterMaid = Maid.new()
    Inventory.ItemMaid = Maid.new()
    table.insert(InterfaceMain.ActiveMaids, Inventory.Maid)
    table.insert(InterfaceMain.ActiveMaids, Inventory.CharacterMaid)
    table.insert(InterfaceMain.ActiveMaids, Inventory.ItemMaid)

    local ItemViewport
    local function DisplayInventory(UniqueId)
        if InterfaceMain.FullMenu == nil then return end
        if InterfaceMain.InventoryTransition then return end

        Inventory.ItemMaid:DoCleaning()
        
        InterfaceMain.InventoryTransition = true
        local InfoDisplay = InterfaceMain.FullMenu:FindFirstChild("InventoryMenu", true).Info        
        local Blob = InterfaceMain.Controllers.DataBlob.Blob
    
        local ItemInfo = Blob.Inventory[UniqueId]
        if typeof(ItemInfo) == "table" then
            if ItemInfo.ItemId == nil then
                print('DAMN')
                return
            end
            InfoDisplay:FindFirstChild("Action").Title.Text = "Equip"
        end
        if typeof(ItemInfo) == "number" then
            ItemInfo = InterfaceMain.Shared.Cache:Get("ItemLibrary")[UniqueId]
            if ItemInfo == nil then print('DAMN2') return end
            InfoDisplay:FindFirstChild("Action").Title.Text = "Use"
        end
    
        
        InfoDisplay:FindFirstChild("Name").Text = ItemInfo["Name"]
        InfoDisplay:FindFirstChild("Description").Text = ItemInfo["Description"]
    
        Transitions:TransitionDown(InfoDisplay:FindFirstChild("Name"), false)
        Transitions:TransitionUp(InfoDisplay:FindFirstChild("Name").Line, false)
        Transitions:TransitionUp(InfoDisplay:FindFirstChild("Description"), false)
        
        for i,v in ipairs(InfoDisplay.Stats:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end
        
        if ItemInfo.Subclass then
            -- get class from subclass
            local ClassStat = InterfaceMain.FullMenu.Resources:FindFirstChild("Stat"):Clone()
            ClassStat.Text = "Class: " .. GlobalData.SubclassToClass[ItemInfo.Subclass]
            ClassStat.LayoutOrder = -1
            ClassStat.Parent = InfoDisplay.Stats
            ClassStat.Visible = true
        end

        if ItemInfo.Stats ~= nil then
            for i, v in pairs(ItemInfo.Stats) do
                local NewStat = InterfaceMain.FullMenu.Resources:FindFirstChild("Stat"):Clone()
                NewStat.Text = i .. ": " .. tostring(v)
                NewStat.Parent = InfoDisplay.Stats
                NewStat.Visible = true
            end
        end

        if ItemInfo.LevelReq then
            local NewStat = InterfaceMain.FullMenu.Resources:FindFirstChild("Stat"):Clone()
            NewStat.Text = "Level needed: " .. tostring(ItemInfo.LevelReq)
            NewStat.Parent = InfoDisplay.Stats
            NewStat.Visible = true
        end
        InfoDisplay.Stats.Visible = true

        InfoDisplay:FindFirstChild("Action").Visible = true
        InfoDisplay:FindFirstChild("Delete").Visible = true
    
        for i, v in pairs(InfoDisplay:FindFirstChild("Action"):GetChildren()) do
            Transitions:TransitionDown(v, false)
        end
    
        for i, v in pairs(InfoDisplay:FindFirstChild("Delete"):GetChildren()) do
            Transitions:TransitionDown(v, false)    
        end
    

        if ItemViewport ~= nil then
            ItemViewport:Destroy()
        end

        if InterfaceMain.FullMenu:FindFirstChild("ItemViewport", true) then
            InterfaceMain.FullMenu:FindFirstChild("ItemViewport", true):Destroy()
        end

        local Base = ReplicatedStorage.Assets:FindFirstChild(ItemInfo.ItemId or ItemInfo.Id, true)
        -- print(Base)
        if Base then
            local rhb = ReplicatedStorage.Assets:FindFirstChild("pmodel")
            local rhbc = rhb:Clone()
            rhbc.Parent = workspace.Trash
        
            local rh = rhbc:FindFirstChild("Prop")

            local rotation = CFrame.Angles(0, 0, math.rad(1))

            if ItemInfo.Type ~= "Weapon" and ItemInfo.Type ~= "Skin" then
                rh.Orientation = Vector3.new(0,0,0)
                rotation = CFrame.Angles(0, math.rad(1), 0)
            end

            local toCF = Attachments:getAttachmentWorldCFrame(rh:FindFirstChild("Attachment", true))

            local NewWeapon = Base:Clone()
            NewWeapon.Name = "ViewportWeapon"
            local OrigAtt = Base:FindFirstChild("HandleAttachment", true)
            if Base:FindFirstChild("discAttachment", true) then
                OrigAtt = Base:FindFirstChild("discAttachment", true)
            end
            local ThisAtt = NewWeapon:FindFirstChild("HandleAttachment", true)
            if NewWeapon:FindFirstChild("discAttachment", true) then
                ThisAtt = NewWeapon:FindFirstChild("discAttachment", true)
            end
            -- local NewAcc = Instance.new("Accessory")
            
            Attachments:setAttachmentWorldCFrame(ThisAtt, toCF)
            local sign = 1
            local offsetCF = CFrame.new()
            if CollectionService:HasTag(OrigAtt, "Equip Inverse") then
                sign = -1
            end

            offsetCF = CFrame.new(OrigAtt.Position.X*sign, OrigAtt.Position.Y*sign, OrigAtt.Position.Z*sign)
            local angleCF = CFrame.Angles(math.rad(OrigAtt.Orientation.X), math.rad(OrigAtt.Orientation.Y), math.rad(OrigAtt.Orientation.Z))
            if OrigAtt:FindFirstChild("Rotation") ~= nil then
                local ext = OrigAtt:FindFirstChild("Rotation")
                angleCF = CFrame.Angles(math.rad(ext.Value.X), math.rad(ext.Value.Y), math.rad(ext.Value.Z))
            end
            NewWeapon.CFrame = (NewWeapon.CFrame * (ThisAtt.CFrame)* angleCF) * offsetCF

            NewWeapon.Parent = rh.Parent
            NewWeapon.Anchored = true

            if game.Players.LocalPlayer:FindFirstChild("InventoryProp") then
                game.Players.LocalPlayer:FindFirstChild("InventoryProp"):Destroy()
            end
            -- rhbc.Parent = game.Players.LocalPlayer
            rhbc.Name = "InventoryProp"


            local ItemViewport = Instance.new("ViewportFrame")
            local center = InterfaceMain.Shared.BoundingBox(rhbc)--, CFrame.Angles(math.rad(-60), math.rad(90), 0))
            local _, size = rhbc:GetBoundingBox()
            local sizeX, sizeY, sizeZ = math.abs(size.X), math.abs(size.Y), math.abs(size.Z)
            
            local Camera = Instance.new("Camera")
            local h = (sizeY / math.tan(math.rad(Camera.FieldOfView / 2) * 2)) + (sizeZ / 2)
            Camera.CFrame = CFrame.new(center.p-Vector3.new(0,0,h+1), center.p)
            
            wait()
            
            ItemViewport.CurrentCamera = Camera
            Camera.Parent = ItemViewport
            rhbc.Parent = ItemViewport

            ItemViewport.Size = UDim2.new(0.275, 0, 0.45, 0)
            ItemViewport.AnchorPoint = Vector2.new(0, 0)
            ItemViewport.Position = UDim2.new(0, 0, 0.02, 0)
            ItemViewport.ZIndex = 2
            ItemViewport.Name = "ItemViewport"
            ItemViewport.BackgroundTransparency = 1
            CollectionService:AddTag(ItemViewport, "TransitionDown")
            ItemViewport.Parent = InterfaceMain.FullMenu:FindFirstChild("InventoryMenu", true)
            table.insert(InterfaceMain.ActiveViewports, ItemViewport)

            Inventory.ItemMaid:GiveTask(game:GetService("RunService").Heartbeat:Connect(function(dt)
                if ItemViewport ~= nil then
                    rhbc:SetPrimaryPartCFrame(rhbc:GetPrimaryPartCFrame() * rotation)
                end
            end))
        end

        wait(0.45)
        InterfaceMain.InventoryTransition = false
    end
    
    
    local function BuildInventory(Filter)
        -- print("BuildingInventory?")
        if InterfaceMain.FullMenu == nil then return end
        Inventory.CharacterMaid:DoCleaning()
        Inventory.ItemMaid:DoCleaning()

        Transitions:ClearTable(InterfaceMain.ActiveViewports)
        Transitions:ClearTable(InterfaceMain.ViewportClones)
        Transitions:ClearTable(InterfaceMain.InventoryButtons)

        -- InventoryViewport()
    
        -- Desired values in scale
        local PADDING = Vector2.new(0.005, 0.005)
        local SIZE = Vector2.new(1, 0.1)
    
        local ScrollingFrame = InterfaceMain.FullMenu:FindFirstChild("InventoryMenu", true).Items.Display
        local UIGridLayout = ScrollingFrame.UIGridLayout
    
        local function ResizeInventory()
            local CellPadding, CellSize, NewCanvas = AutoGrid:Update(PADDING, SIZE, ScrollingFrame.AbsoluteSize, UIGridLayout.AbsoluteContentSize)
            UIGridLayout.CellPadding = UDim2.new(0, 5, 0, 2)
            UIGridLayout.CellSize = UDim2.new(0, CellSize.X.Offset, 0, CellSize.Y.Offset-5)
    
            ScrollingFrame.CanvasSize = NewCanvas
        end
        InterfaceMain.SFMaid = Maid.new()
        InterfaceMain.SFMaid:GiveTask(
            UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeInventory)
        )
    
        InterfaceMain.SFMaid:GiveTask(
            ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeInventory)
        )
    
        table.insert(InterfaceMain.ActiveMaids, InterfaceMain.SFMaid)
    
        local FilteredInventory = TableUtil.Filter(InterfaceMain.Controllers.DataBlob.Blob.Inventory, function(item, index)
            if typeof(item) == "number" then
                if item > 0 then
                    local info = InterfaceMain.Shared.Cache:Get("ItemLibrary")[index]
                    return info.Type == Filter
                else
                    return false
                end
            end

            return item.Type == Filter
        end)

        for i, v in pairs(FilteredInventory) do
            -- InterfaceMain.Scheduler:QueueTask(function()
                -- print(v.ItemId)
                local BaseItemId = i
                if typeof(v) == "table" then
                    BaseItemId = v["ItemId"]
                end
                local ItemBase = ReplicatedStorage.Assets:FindFirstChild(BaseItemId, true)
                -- print(BaseItemId, ItemBase)
                if ItemBase then
                    local ItemInfo = InterfaceMain.Shared.Cache:Get("ItemLibrary")[BaseItemId]
                        -- local ItemClone = ItemBase:Clone()
                        -- local ViewportInfo = ItemClone.ViewportInfo
                        -- local ItemModel = Instance.new("Model")
                        -- ItemClone.Parent = ItemModel
                        -- ItemModel.PrimaryPart = ItemClone
                    local InvButton = InterfaceMain.FullMenu.Resources:FindFirstChild("Skill"):Clone()
                    InvButton.Name = i
                    InvButton.Title.Text = ItemInfo.Name
                    InvButton.Parent = ScrollingFrame
                
                    local Button = InvButton.Button
                    local sb = SlideButton:Create(InvButton)
        
                    Button.Activated:Connect(function()
                        if InterfaceMain.InventoryTransition then return end
                        local thisUnique = BaseItemId
                        if typeof(v) == "table" then
                            thisUnique = v.UniqueId
                        end
                        DisplayInventory(thisUnique)
                        InterfaceMain.SelectedInventory = thisUnique
                    end)
        
                        -- table.insert(InterfaceMain.ActiveViewports, CustomFrame)
                        -- table.insert(InterfaceMain.ViewportClones, ItemModel)
                    table.insert(InterfaceMain.InventoryButtons, InvButton)
                end
            -- end)
        end
    
        --hook inventory equipment buttons
        local ActionFrame = InterfaceMain.FullMenu.Main.MainPanel.InventoryMenu.Info.Action
        local ActionButton = ActionFrame:FindFirstChild("Button")
    
        local db = false
        Inventory.CharacterMaid:GiveTask(ActionButton.Activated:Connect(function()
            if db then return end
            db = not db

            if InterfaceMain.Controllers.DataBlob.Blob.Inventory[InterfaceMain.SelectedInventory] ~= nil then
                if typeof(InterfaceMain.Controllers.DataBlob.Blob.Inventory[InterfaceMain.SelectedInventory]) == "table" then
                    local ItemData = InterfaceMain.Controllers.DataBlob.Blob.Inventory[InterfaceMain.SelectedInventory]
                    local ItemType = ItemData.Type
                    if ItemType == "Gear" then
                        if game.Players.LocalPlayer.Character == nil then return end
                        local t = InterfaceMain.Services.PlayerService:EquipSlot(ItemData.Default, InterfaceMain.SelectedInventory)

                    elseif ItemType == "Weapon" or ItemType == "Skin" then
                        if game.Players.LocalPlayer.Character == nil then return end
                        local t = InterfaceMain.Services.PlayerService:EquipSlot("Primary" .. ItemType, InterfaceMain.SelectedInventory)
                        if not t then db = false return end
                        --viewport display...
                        --wtf
                        local DW = game.Players.LocalPlayer.Character:FindFirstChild("DiscWeapon", true)
                        if DW then
                            DW:Destroy()
                        end
                        wait()

                        InterfaceMain.Services.WeaponService.LoadWeapons:Fire()

                        delay(0.2, function()
                            local EquipmentContainer = InterfaceMain.FullMenu.Main.LeftPanel:FindFirstChild("Equipment", true)
                            if EquipmentContainer then
                                for i, v in pairs(InterfaceMain.Controllers.DataBlob.Blob.Equipment) do
                                    local label = EquipmentContainer:FindFirstChild(i)
                                    if label then
                                        local item = InterfaceMain.Controllers.DataBlob.Blob.Inventory[v]
                                        if item then
                                            label.Item.Text = item.Name
                                        end
                                    end
                                end
                            end
                        end)
                    end
                elseif typeof(InterfaceMain.Controllers.DataBlob.Blob.Inventory[InterfaceMain.SelectedInventory]) == "number" then
                    --assume its a misc item
                    local ItemInfo = InterfaceMain.Shared.Cache:Get("ItemLibrary")[InterfaceMain.SelectedInventory]
                    if ItemInfo == nil then return end
                    if ItemInfo.Type == "Use" then
                        -- print("CONSUMING ITEM")
                        local Consumed = InterfaceMain.Services.ItemService:ConsumeItem(InterfaceMain.SelectedInventory)
                        wait(0.1)
                        if Consumed then
                            InterfaceMain.Controllers.NotificationController:FireEvent("Notify", {
                                Text = "Used item: " .. ItemInfo.Name;
                                Time = 2;
                            })
                        end
                    end
                end
            end
            wait(1)
            db = not db
        end))
    end
    
    local ActivePanel = ""
    local function ConnectButton(v)
        local Button = v:WaitForChild("Button")

        local Gradient = v.Gradient
        local Line = v.Line
        local Title = v.Title
        local Emitter = Gradient.GUIEmitter

        Inventory.Maid:GiveTask(Button.MouseEnter:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0.55, 0), "Out", "Quad", 0.3, true)
            Line:TweenSize(UDim2.new(1, 0, 0, 2), "Out", "Quad", 0.1, true)
            Title:TweenPosition(UDim2.new(0, 0, -0.175, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = true
        end))
        
        Inventory.Maid:GiveTask(Button.MouseLeave:Connect(function()
            Gradient:TweenSize(UDim2.new(0.9, 0, 0, 0), "Out", "Quad", 0.1, true)
            if v.Name ~= ActivePanel then
                Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
            end
            Title:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.2, true)
            
            Emitter.Value = false
        end))
        
        Inventory.Maid:GiveTask(Button.MouseButton1Down:Connect(function()
            Gradient.ImageTransparency = 0.55
        end))
        
        Inventory.Maid:GiveTask(Button.MouseButton1Up:Connect(function()
            Gradient.ImageTransparency = 0.2
        end))

        Inventory.Maid:GiveTask(Button.Activated:Connect(function()
            --rebuild inventory
            if ActivePanel == v.Name then return end
            ActivePanel = v.Name
            for j, k in ipairs(v.Parent:GetChildren()) do
                if k.Name ~= v.Name and k:IsA("Frame") then
                    k.Line:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Quad", 0.3, true)
                end
            end
            BuildInventory(v.Name)
        end))
    end

    local TopBar = InterfaceMain.FullMenu.Main.MainPanel.InventoryMenu.TopBar
    for i, v in pairs(TopBar:GetChildren()) do
        if v:IsA("Frame") then
            ConnectButton(v)
        end
    end

    Inventory.Maid:GiveTask(InterfaceMain.Services.PlayerService.UpdateBlob:Connect(function(Blob)
        BuildInventory(ActivePanel)
    end))

    InterfaceMain:ConnectEvent("GiftRebuild", function()
        BuildInventory("Weapon")
    end)
end

return Inventory