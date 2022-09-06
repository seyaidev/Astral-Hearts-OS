-- Merchant Controller
-- oniich_n
-- September 16, 2019
local Player = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MerchantController = {}
local TweenService = game:GetService("TweenService")
local Lighting = game.Lighting
local CollectionService = game:GetService("CollectionService")

function MerchantController:Start()
    local ShopBase = ReplicatedStorage.Assets.Interface:FindFirstChild("Shop")
    local ShopResources = ShopBase:FindFirstChild("Resources")
    
    local ShopMaid = Maid.new()
    MerchantService.StartShop:Connect(function(MerchantInfo)
        if self.Shopping then return end
        self.Shopping = true
        
        --unlock mouse
        self.Controllers.Camera.PlayerCamera._MenuLock:Fire(false)
        
        --build shop
        local NewShop = ShopBase:Clone()
        local Main = NewShop:WaitForChild("Main")
        local PlayerInfo = NewShop:WaitForChild("PlayerInfo")

        local ItemDisplay = Main:FindFirstChild("Info")

        local Blob = self.Controllers.DataBlob.Blob
        PlayerInfo:FindFirstChild("Name").Text = game.Players.LocalPlayer.Name
        PlayerInfo:FindFirstChild("Level").Text = "Lv. " .. tostring(Blob.Stats.Level)
        
        local pattern = "%u+%l*"
        local NewName = ""
        for v in Blob.Stats.Class:gmatch(pattern) do
            NewName = NewName .. v .. " "
        end
        if string.len(NewName) > 1 then
            NewName = string.sub(NewName, 1, string.len(NewName)-1)
        end
        
        PlayerInfo:FindFirstChild("Class").Text = NewName
        local ExpContainer = PlayerInfo:FindFirstChild("ExpContainer")
        ExpContainer.Display.Size = UDim2.new(Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level], 0, 1, 0)
        ExpContainer.Value.Text = tostring(Blob.Stats.EXP)
        if Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level] > 0.8 then
            ExpContainer.Value.TextColor3 = Color3.fromRGB(53, 51, 45)
            ExpContainer.Value.AnchorPoint = Vector2.new(1, 0)
        else
            ExpContainer.Value.TextColor3 = Color3.fromRGB(240, 234, 207)
            ExpContainer.Value.AnchorPoint = Vector2.new(0, 0)
        end

        ExpContainer.VaultButton.MouseEnter:Connect(function()
            ExpContainer.Vault.Visible = true
        end)

        ExpContainer.VaultButton.MouseLeave:Connect(function()
            ExpContainer.Vault.Visible = false
        end)

        ExpContainer.Vault.Text = "EXP Vault: " .. tostring(self.Services.PlayerService:GetVault())

        if Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level] > 0.2 then
            ExpContainer.EXPText.TextColor3 = Color3.fromRGB(53, 51, 45)
        else
            ExpContainer.EXPText.TextColor3 = Color3.fromRGB(240, 234, 207)
        end

        ExpContainer.Value.Position = UDim2.new(math.clamp(Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level], 0.2, 1),
        0, 0, 0)

        PlayerInfo.Stats.STR.Value.Text = tostring(GlobalMath:round(Blob.Stats.STR))
        PlayerInfo.Stats.DEX.Value.Text = tostring(GlobalMath:round(Blob.Stats.DEX))
        PlayerInfo.Stats.LCK.Value.Text = tostring(GlobalMath:round(Blob.Stats.LCK))
        PlayerInfo.Stats.INT.Value.Text = tostring(GlobalMath:round(Blob.Stats.INT))

        local AttackBase = self.Shared.FormulasModule:CalculateAttack(self.Controllers.DataBlob.Blob)
        PlayerInfo.Stats.ATK.Value.Text = tostring(GlobalMath:round(AttackBase))

        PlayerInfo.Munny.Text = "Munny: ¥" .. tostring(Blob.Stats.Munny)
        PlayerInfo.SayoCredits.Text = "Sayo Credits: " .. tostring(self.Services.PlayerService:GetCredits())

        local EquipmentContainer = PlayerInfo:FindFirstChild("Equipment", true)
        if EquipmentContainer then
            for i, v in pairs(self.Controllers.DataBlob.Blob.Equipment) do
                local label = EquipmentContainer:FindFirstChild(i)
                if label then
                    local item = self.Controllers.DataBlob.Blob.Inventory[v]
                    if item then
                        label.Item.Text = item.Name
                    end
                end
            end
        end

        Main.ShopTitle.Text = MerchantInfo.Name
        Main.ShopDesc.Text = MerchantInfo.Description
        
        local CloseButton = Main:FindFirstChild("Close", true)
        local PBMaid = Buttonify:Create(ItemDisplay.Purchase)
        local CBMaid = SlideButton:Create(CloseButton)

        local Blur = Lighting.Blur
        local CC = Lighting.ColorCorrection

        local ItemFrame
        CloseButton.Button.Activated:Connect(function()
            if ItemFrame then ItemFrame:Destroy() end
            NewShop:Destroy()
            self.Shopping = false
            self.Controllers.HUD.UI.Enabled = true

            TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
            TweenService:Create(CC, TweenInfo.new(0.5), {
                -- TintColor = Color3.fromRGB(246, 255, 255),
                Saturation = 0.4
            }):Play()
            self.Controllers.Camera.PlayerCamera._MenuLock:Fire(true)
            ShopMaid:DoCleaning()
        end)

        --create all wares
        for WareId, WareInfo in pairs(MerchantInfo.Wares) do
            local ItemButton = ShopResources.ItemButton:Clone()
            local ItemInfo = ItemLibrary[WareInfo.ItemId]
            ItemButton.WareName.Text = ItemInfo.Name
             
    
            local function Click()
                ShopMaid:DoCleaning()
                --display inventory
                ItemDisplay.ItemTitle.Text = ItemInfo.Name
                ItemDisplay.ItemDesc.Text = ItemInfo.Description

                for i,v in ipairs(ItemDisplay.Stats:GetChildren()) do
                    if v:IsA("GuiObject") then
                        v:Destroy()
                    end
                end
                
                if ItemInfo.Stats ~= nil then
                    for i, v in pairs(ItemInfo.Stats) do
                        local NewStat = NewShop.Resources:FindFirstChild("Stat"):Clone()
                        NewStat.Text = i .. ": " .. tostring(v)
                        NewStat.Parent = ItemDisplay.Stats
                        NewStat.Visible = true
                    end
                end

                if ItemInfo.LevelReq then
                    local NewStat = NewShop.Resources:FindFirstChild("Stat"):Clone()
                    NewStat.Text = "Level needed: " .. tostring(ItemInfo.LevelReq)
                    NewStat.Parent = ItemDisplay.Stats
                    NewStat.Visible = true
                end
                ItemDisplay.Stats.Visible = true
                
                if MerchantInfo.Currency == "SayoCredits" then
                    ItemDisplay.Purchase.Title.Text = "Price: " .. tostring(WareInfo.Price) .. "$C"
                else
                    ItemDisplay.Purchase.Title.Text = "Price: ¥" .. tostring(WareInfo.Price)
                end

                if ItemViewport ~= nil then
                    ItemViewport:Destroy()
                end

                if Main:FindFirstChild("ItemViewport", true) then
                    Main:FindFirstChild("ItemViewport", true):Destroy()
                end

                local Base = ReplicatedStorage.Assets:FindFirstChild(WareInfo.ItemId, true)
                if Base then
                    local rhb = ReplicatedStorage.Assets:FindFirstChild("pmodel")
                    local rhbc = rhb:Clone()
                    rhbc.Parent = workspace.Trash
                
                    local rh = rhbc:FindFirstChild("Prop")
        
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
                    local center = self.Shared.BoundingBox(rhbc)--, CFrame.Angles(math.rad(-60), math.rad(90), 0))
                    local _, size = rhbc:GetBoundingBox()
                    local sizeX, sizeY, sizeZ = math.abs(size.X), math.abs(size.Y), math.abs(size.Z)
                    
                    local Camera = Instance.new("Camera")
                    local h = (sizeY / math.tan(math.rad(Camera.FieldOfView / 2) * 2)) + (sizeZ / 2)
                    Camera.CFrame = CFrame.new(center.p-Vector3.new(0,0,h+1), center.p)
                    
                    wait()
                    
                    ItemViewport.CurrentCamera = Camera
                    Camera.Parent = ItemViewport
                    rhbc.Parent = ItemViewport
        
                    ItemViewport.Size = UDim2.new(1, 0, 1, 0)
                    ItemViewport.AnchorPoint = Vector2.new(0, 0)
                    ItemViewport.Position = UDim2.new(0, 0, 0.02, 0)
                    ItemViewport.ZIndex = 2
                    ItemViewport.Name = "ItemViewport"
                    ItemViewport.BackgroundTransparency = 1
                    CollectionService:AddTag(ItemViewport, "TransitionDown")
                    ItemViewport.Parent = Main:FindFirstChild("ViewportHolder", true)
                    -- table.insert(self.ActiveViewports, ItemViewport)
        
                    ShopMaid:GiveTask(game:GetService("RunService").Heartbeat:Connect(function(dt)
                        print(ItemViewport)
                        if ItemViewport ~= nil then
                            rhbc:SetPrimaryPartCFrame(rhbc:GetPrimaryPartCFrame() * CFrame.Angles(0, 0, math.rad(1)))
                        end
                    end))
                end

                ShopMaid:GiveTask(ItemDisplay.Purchase.Button.Activated:Connect(function()
                    local check = MerchantService:PurchaseRequest(MerchantInfo.Id, WareId)
                    if check then 
                        self.Controllers.NotificationController:FireEvent("Notify", {
                            Text = "Purchased: " .. ItemInfo.Name;
                            Time = 2;
                        })
                        print("Bought item!")
                        return
                    else
                        if MerchantInfo.Currency == "SayoCredits" then
                            -- local Difference = 
                        end
                    end --display some sort of UH OH instead
                    --display purchase confirmation
                end))

                ItemDisplay.Visible = true
            end

            ItemButton.Button.Activated:Connect(Click)
            ItemButton.Button.MouseEnter:Connect(function()
                TweenService:Create(ItemButton.Background, TweenInfo.new(0.25), {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundColor3 = Color3.fromRGB(255, 246, 217)
                }):Play()
                TweenService:Create(ItemButton.WareName, TweenInfo.new(0.25), {
                    TextColor3 = Color3.fromRGB(53, 51, 45)
                }):Play()
                -- ItemButton.Background:TweenSize(UDim2.new(1,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
            end)
            ItemButton.Button.MouseLeave:Connect(function()
                TweenService:Create(ItemButton.Background, TweenInfo.new(0.25), {
                    Size = UDim2.new(0.95,0,1,0),
                    BackgroundColor3 = Color3.fromRGB(53, 51, 45)
                }):Play()
                TweenService:Create(ItemButton.WareName, TweenInfo.new(0.25), {
                    TextColor3 = Color3.fromRGB(255, 246, 217)
                }):Play()
            end)

            ItemButton.Parent = Main:WaitForChild("ItemList")
        end

        
        Blur.Enabled = true
        TweenService:Create(Blur, TweenInfo.new(1), {Size = 24}):Play()
        TweenService:Create(CC, TweenInfo.new(1), {
            -- TintColor = Color3.fromRGB(220, 205, 175),
            Saturation = -0.5
        }):Play()
        wait(1)
        NewShop.Parent = Player:WaitForChild("PlayerGui")
        Transitions:RecursiveDisplay(Main, "in")
        self.Controllers.Camera.PlayerCamera._MenuLock:Fire(false)
        self.Controllers.HUD.UI.Enabled = false
    end)
end


function MerchantController:Init()
    self.Shopping = false
    Transitions = self.Modules.Transitions
    Buttonify = self.Modules.Buttonify
    SlideButton = self.Modules.SlideButton

    Maid = self.Shared.Maid
    ItemLibrary = self.Shared.Cache:Get("ItemLibrary")
    MerchantService = self.Services.MerchantService
    Gui3DCore = self.Shared["3DGuiCore"]
    GlobalData = self.Shared.GlobalData
    GlobalMath = self.Shared.GlobalMath
    Attachments = self.Shared.Attachments
end


return MerchantController