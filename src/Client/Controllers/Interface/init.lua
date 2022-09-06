-- Interface
-- oniich_n
-- April 28, 2019

--[[
	

--]]
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Interface = {}
Interface.__aeroOrder = 6
local Mouse
local Keyboard
local Gamepad
local CharacterController

-- local Buttonify

local Gui3DCore
local Maid
local WeaponManipulation
local TableUtil


function Interface:MenuClose()
    if self.FullMenu == nil then return end
    self.transition = true
    for _, v in pairs(self.FullMenu:GetDescendants()) do
        Transitions:TweenOut(v)
    end
    
    Transitions:ClearTable(self.ActiveViewports)
    Transitions:ClearTable(self.ViewportClones)

    self.ActiveViewports = {}
    self.ViewportClones = {}

    local ButtonFrames = CollectionService:GetTagged("Buttonify")
    for i, v in ipairs(ButtonFrames) do
        local bmaid = Buttonify:Clear(v)
    end

    local Slides = CollectionService:GetTagged("SlideButton")
    for i, v in ipairs(Slides) do
        local bmaid = SlideButton:Clear(v)
    end
    
    for i, v in pairs(self.ActiveMaids) do
        v:DoCleaning()
    end
    self.ActiveMaids = {}

    for i, v in pairs(self.FullMenu:FindFirstChild("InventoryMenu", true).Items.Display:GetChildren()) do
        if v:IsA("GuiObject") then
            v:Destroy()
        end
    end

    local Blur = Lighting.Blur
    local CC = Lighting.ColorCorrection

    TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
    TweenService:Create(CC, TweenInfo.new(0.5), {
        -- TintColor = Color3.new(1, 1, 1),
        Saturation = 0.4
    }):Play()
    
    wait(0.65)
    self.FullMenu.Enabled = true               
    self.ActiveFull = false
    Blur.Enabled = false
    self.transition = false
    self.Controllers.Camera.PlayerCamera._MenuLock:Fire(true)
    self.ActiveMenu = ""
    -- self.Controllers.HUD.UI.Enabled = true
end

function Interface:HookButtons()
    if self.FullMenu == nil then return end
    
    --make all buttons pretty!
    local ButtonFrames = CollectionService:GetTagged("Buttonify")
    for i, v in ipairs(ButtonFrames) do
        local bmaid = Buttonify:Create(v)
        table.insert(self.ActiveMaids, bmaid)
    end

    local Slides = CollectionService:GetTagged("SlideButton")
    for i, v in ipairs(Slides) do
        local bmaid = SlideButton:Create(v)
        table.insert(self.ActiveMaids, bmaid)
    end

    --hook up left panel buttons!
    local MenuButtons = self.FullMenu.Main.LeftPanel.MenuStuff.Buttons:GetChildren()
    for i, Frame in pairs(MenuButtons) do
        local Button = Frame:FindFirstChild("Button")
        if Button then
            Button.Activated:Connect(function()
                if self.MainTransition or self.transition then return end
                self.MainTransition = true
                delay(0.65, function() self.MainTransition = false end)
                -- delay(0.5, function()
                if self.ActiveMenu ~= Frame.Name then
                    local OldMenu = self.FullMenu.Main.MainPanel:FindFirstChild(self.ActiveMenu .. "Menu")
                    if OldMenu then
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
            
                        RecursiveDisplayOut(OldMenu)
                        Transitions:TweenOut(OldMenu)
                    end

                    self.ActiveMenu = Frame.Name
                    local NewMenu = self.FullMenu.Main.MainPanel:FindFirstChild(self.ActiveMenu .. "Menu")
                    
                    Transitions:TweenIn(NewMenu, false)
                    local function RecursiveDisplayIn(obj)
                        for i, v in ipairs(obj:GetChildren()) do
                            Transitions:TweenIn(v, true)
        
                            if #v:GetChildren() > 0 then
                                delay(0.05, function()
                                    RecursiveDisplayIn(v)
                                end)
                            end
                        end
                    end
        
                    RecursiveDisplayIn(NewMenu)
                    local Stats = self.FullMenu.Main.MainPanel:FindFirstChild("InventoryMenu", true):FindFirstChild("Stats", true)
                    for i, v in ipairs(Stats:GetChildren()) do
                        if v:IsA("GuiObject") then
                            v:Destroy()
                        end
                    end
                end
            end)
        end
    end

    local EquipmentButtons = self.FullMenu.Main.LeftPanel.PlayerInfo.Equipment
    local SkinButtons = self.FullMenu.Main.LeftPanel.PlayerInfo.Skins
    local These = {EquipmentButtons, SkinButtons}

    local Buttons = {}
    for i, v in ipairs(These) do
        for j, Slot in ipairs(v:GetChildren()) do
            if Slot:FindFirstChild("Unequip") then
                table.insert(Buttons, Slot:FindFirstChild("Unequip"))
            end
        end
    end

    for i, v in ipairs(Buttons) do
        local Button = v:FindFirstChild("Button")
        local Active = v:FindFirstChild("Active")
        local Title = v:FindFirstChild("Title")

        Button.MouseEnter:Connect(function()
            Active:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.2, true)
            TweenService:Create(Title, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        end)

        Button.MouseLeave:Connect(function()
            Active:TweenSize(UDim2.new(0, 0, 1, 0), "Out", "Quad", 0.2, true)
            TweenService:Create(Title, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        end)

        Button.Activated:Connect(function()
            print("SEND")
            self.Services.PlayerService:UnequipSlot(v.Parent.Name)
            print("FULLSEND")
        end)
    end

    local SkinsActive = false
    local Swap = self.FullMenu.Main.LeftPanel.PlayerInfo:FindFirstChild("Swap", true)
    Swap.Button.Activated:Connect(function()
        SkinsActive = not SkinsActive
        if not SkinsActive then
            Swap.Title.Text = "Skins"
            self.FullMenu.Main.LeftPanel.PlayerInfo.Equipment.Visible = true
            self.FullMenu.Main.LeftPanel.PlayerInfo.Skins.Visible = false
        else
            Swap.Title.Text = "Equipment"
            self.FullMenu.Main.LeftPanel.PlayerInfo.Equipment.Visible = false
            self.FullMenu.Main.LeftPanel.PlayerInfo.Skins.Visible = true
        end
    end)
end

function Interface:Start()
    Keyboard = UserInput:Get("Keyboard")
    -- self.Scheduler = TaskScheduler:CreateScheduler(30)

    -- CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
    --     --create new Interface UI
    --     self.FullMenu = ReplicatedStorage.Assets.Interface:FindFirstChild("FullMenu"):Clone()
    --     self.FullMenu.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    --     wait()
    -- end)
    self.Controllers.WeaponController:ConnectEvent("ChangeEquip", function(state)
        if state and self.ActiveFull then
            self:MenuClose()
            self.Controllers.HUD.UI.Enabled = true
            StarterGui:SetCore("ChatActive", true)
        end
    end)
        
    
    CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function(Character)
        local Blur = Lighting.Blur
        local CC = Lighting.ColorCorrection
        
        TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
        TweenService:Create(CC, TweenInfo.new(0.5), {
            -- TintColor = Color3.new(1, 1, 1),
            Saturation = 0.4
        }):Play()
        
        delay(0.5, function() Blur.Enabled = true end)

        Transitions:ClearTable(self.ActiveViewports)
        Transitions:ClearTable(self.ViewportClones)

        if self.ActiveFull then
            self:MenuClose()
            StarterGui:SetCore("ChatActive", true)
        end
    end)

    local function UpdateEQDisplay(Blob)
        if self.FullMenu == nil then return end
        local PlayerInfo = self.FullMenu.Main.LeftPanel.PlayerInfo
        local EquipmentContainer = PlayerInfo:FindFirstChild("Equipment", true)
        if EquipmentContainer then
            for i, v in pairs(Blob.Equipment) do
                local label = EquipmentContainer:FindFirstChild(i)
                if label then
                    local item = Blob.Inventory[v]
                    if item then
                        label.Item.Text = item.Name
                    else
                        label.Item.Text = ""
                    end
                end
            end
        end

        local SkinsContainer = PlayerInfo:FindFirstChild("Skins", true)
        if SkinsContainer then
            for i, v in pairs(Blob.Skins) do
                local label = SkinsContainer:FindFirstChild(i)
                if label then
                    local item = Blob.Inventory[v]
                    if item then
                        label.Item.Text = item.Name
                    else
                        label.Item.Text = ""
                    end
                end
            end
        end
    end
    
    local eve, evl

    local function UpdateInfo(Blob)
        Blob = Blob or self.Controllers.DataBlob.Blob
        if not self.FullMenu then return end
        local PlayerInfo = self.FullMenu:FindFirstChild("PlayerInfo", true)
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

        if eve then eve:Disconnect() end
        if evl then evl:Disconnect() end

        eve = ExpContainer.VaultButton.MouseEnter:Connect(function()
            ExpContainer.Vault.Visible = true
        end)

        evl = ExpContainer.VaultButton.MouseLeave:Connect(function()
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

        local DistributingAll = false
        PlayerInfo.AbilityPoints.APDisplay.Text = "Ability Points: " .. tostring(Blob.Stats.AbilityPoints)
        

        local AttackBase = self.Shared.FormulasModule:CalculateAttack(self.Controllers.DataBlob.Blob)
        PlayerInfo.Stats.ATK.Value.Text = tostring(GlobalMath:round(AttackBase))

        PlayerInfo.Munny.Text = "Munny: ¥" .. tostring(Blob.Stats.Munny)
        PlayerInfo.SayoCredits.Text = "Sayo Credits: " .. tostring(self.Services.PlayerService:GetCredits())
    end

    self.Services.PlayerService.UpdateBlob:Connect(function(Blob)
        UpdateInfo(Blob)
        UpdateEQDisplay(Blob)
    end)

    local function acti()
        if self.transition or
            self.MainTransition or
            self.InventoryTransition or
            self.QuestTransition or
            self.InboxTransition or
            self.SkillTransition then return end

            if self.Controllers.WeaponController.WeaponState.current == "equipped" then
                --check for new mini HUD
                return
            end

            if not self.ActiveFull then
                self.ActiveFull = true
                self.transition = true

                if self.FullMenu then
                    self.FullMenu:Destroy()
                end

                self.FullMenu = ReplicatedStorage.Assets.Interface:FindFirstChild("FullMenu"):Clone()
                self.FullMenu.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

                self.FullMenu.Enabled = true

                local MenuButton = self.FullMenu:WaitForChild("Main"):WaitForChild("MainPanel"):FindFirstChild("MenuButton")
                MenuButton.Activated:Connect(function()
                    self:FireEvent("HUDButton")
                end)

                if GIC.LastInput == Enum.UserInputType.Keyboard then
                    MenuButton.Text = "Close Menu [M]"
                end
                if GIC.LastInput == Enum.UserInputType.Touch or GIC.TouchEnabled then
                    MenuButton.Text = "Close Menu [Tap]"
                end

                if self.Controllers.HUD.UI ~= nil then
                    self.Controllers.HUD.UI.Enabled = false
                end

                for i, v in pairs(self.FullMenu:GetDescendants()) do
                    if v:IsA("GuiObject") then
                        v.Visible = false
                    end
                end

                local Blur = Lighting.Blur
                local CC = Lighting.ColorCorrection
                Blur.Enabled = true
                TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 24}):Play()
                TweenService:Create(CC, TweenInfo.new(0.5), {
                    -- TintColor = Color3.fromRGB(220, 205, 175),
                    Saturation = -0.5
                }):Play()
                
                

                --Connect all the other pages
                self.Controllers.Camera.PlayerCamera._MenuLock:Fire(false)

                --update PlayerInfo
                UpdateInfo()
                UpdateEQDisplay(self.Controllers.DataBlob.Blob)

                local PlayerInfo = self.FullMenu:FindFirstChild("PlayerInfo", true)
                self.Maid:GiveTask(PlayerInfo.AbilityPoints.AutoAssign.Button.Activated:Connect(function()
                    if DistributingAll then return end
                    DistributingAll = true
        
                    local t = self.Services.PlayerService:AutoDistributeAP()
                    if t then
                        Blob = self.Controllers.DataBlob.Blob
                        PlayerInfo.Stats.STR.Value.Text = tostring(GlobalMath:round(Blob.Stats.STR))
                        PlayerInfo.Stats.DEX.Value.Text = tostring(GlobalMath:round(Blob.Stats.DEX))
                        PlayerInfo.Stats.LCK.Value.Text = tostring(GlobalMath:round(Blob.Stats.LCK))
                        PlayerInfo.Stats.INT.Value.Text = tostring(GlobalMath:round(Blob.Stats.INT))
        
                        local AttackBase = self.Shared.FormulasModule:CalculateAttack(self.Controllers.DataBlob.Blob)
                        PlayerInfo.Stats.ATK.Value.Text = tostring(GlobalMath:round(AttackBase))
                        PlayerInfo.AbilityPoints.APDisplay.Text = "Ability Points: 0"
                    end
                    wait()
                    DistributingAll = false
                end))
        
                local DistributingSingle = false
                for i, v in pairs(PlayerInfo.Stats:GetChildren()) do
                    if v:FindFirstChild("AssignPoint", true) ~= nil then
                        self.Maid:GiveTask(v:FindFirstChild("AssignPoint", true).Button.Activated:Connect(function()
                            if DistributingSingle then return end
                            DistributingSingle = true
                            local t = self.Services.PlayerService:DistributeAPToStat(v.Name)
                            if t then
                                Blob = self.Controllers.DataBlob.Blob
                                v.Value.Text = tostring(GlobalMath:round(Blob.Stats[v.Name]))
                                PlayerInfo.AbilityPoints.APDisplay.Text = "Ability Points: " .. tostring(Blob.Stats.AbilityPoints)
                            end
                            DistributingSingle = false
                        end))
                    end
                end

                InventoryPage.Connect(Interface)
                QuestPage.Connect(Interface)
                SkillPage.Connect(Interface)
                InboxPage.Connect(Interface)
                CashShopPage.Connect(Interface)
                OptionPage.Connect(Interface)
                
                local function RecursiveDisplay(obj)
                    for i, v in pairs(obj:GetChildren()) do
                        Transitions:TweenIn(v, true)

                        if #v:GetChildren() > 0 then
                            delay(0.05, function()
                                RecursiveDisplay(v)
                            end)
                        end
                    end
                end

                RecursiveDisplay(self.FullMenu)

                self:HookButtons()
                StarterGui:SetCore("ChatActive", false)
                wait(0.65)
                self.transition = false
                -- CharacterController.Character.PrimaryPart.Anchored = true
            else
                self:MenuClose()
                if self.Controllers.DataBlob.Options then
                    print(self.Controllers.DataBlob.Options["Immersive"])
                    if not self.Controllers.DataBlob.Options["Immersive"] then
                        self.Controllers.HUD.UI.Enabled = true
                    end
                end
                StarterGui:SetCore("ChatActive", true)
                -- CharacterController.Character.PrimaryPart.Anchored = false
            end
    end

    Keyboard.KeyDown:Connect(function(KeyCode)
        if (KeyCode == Enum.KeyCode.M or KeyCode == Enum.KeyCode.Tab) then
            acti()
        end
    end)

    self:ConnectEvent("HUDButton", function()
        acti()
    end)
    -- self.Modules.MobileModule:Create(0.4, 0, 0, acti, Vector2.new(0.5,0), UDim2.new(0.5, 0, 0, -37))
end


function Interface:Init()

    self:RegisterEvent("GiftRebuild")
    self:RegisterEvent("HUDButton")

    self.ActiveFull = false

    self.transition = false
    self.InventoryTransition = false
    self.QuestTransition = false
    self.SkillTransition = false
    self.MainTransition = false
    self.InboxTransition = false

    self.EquippingSkill = false
    
    self.ActiveViewports = {}
    self.ViewportClones = {}
    self.ActiveMaids = {}
    self.InventoryButtons = {}

    self.ActiveMenu = ""
    self.SelectedInventory = ""

    InventoryPage = require(script.Inventory)
    QuestPage = require(script.Quest)
    SkillPage = require(script.Skill)
    InboxPage = require(script.Inbox)
    CashShopPage = require(script.CashShop)
    OptionPage = require(script.Option)


    UserInput = self.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = self.Controllers.Character
    ZoneController = self.Controllers.ZoneController
    TaskScheduler = self.Controllers.TaskScheduler
    GIC = self.Controllers.GlobalInputController

    Buttonify = self.Modules.Buttonify
    SlideButton = self.Modules.SlideButton
    AutoGrid = self.Modules.AutoGrid
    Transitions = self.Modules.Transitions

    Gui3DCore = self.Shared["3DGuiCore"]
    Maid = self.Shared.Maid
    TableUtil = self.Shared.TableUtil
    WeaponManipulation = self.Shared.WeaponManipulation
    GlobalData = self.Shared.GlobalData
    GlobalMath = self.Shared.GlobalMath
    repr = self.Shared.repr

    self.Maid = Maid.new()
    table.insert(self.ActiveMaids, self.Maid)
end


return Interface