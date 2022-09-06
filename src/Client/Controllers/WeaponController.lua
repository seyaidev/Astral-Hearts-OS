-- Weapon Controller
-- Username
-- September 7, 2019


local Conte
local WeaponController = {}
WeaponController.__aeroOrder = 3
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function WeaponController:Start()
    local Player = game.Players.LocalPlayer
    self.WeaponState = FSM.create({
        initial = "unequipped";
        events = {
            {name = "equip", to = "equipped", from = "unequipped"},
            {name = "unequip", to = "unequipped", from = "equipped"},
            {name = "died", to = "unequipped", from = "*"}
        },

        callbacks = {
            on_enter_equipped = function()
                WeaponManipulation:Equip(Player)
                self.Services.WeaponService.EquipWeapon:Fire()
                self:FireEvent("ChangeEquip", true)
                self.Controllers.ZoneController:FireEvent("DangerZone")

                if self.Controllers.HUD.UI ~= nil then
                    local MenuButton = self.Controllers.HUD.UI:WaitForChild("MenuButton", 2)
                    if MenuButton then
                        MenuButton.Text = "Sheathe weapon first"
                    end
                end
            end,
            on_enter_unequipped = function()
                WeaponManipulation:Unequip(Player)
                WeaponManipulation:SetupDisc(Player)

                self.Services.WeaponService.UnequipWeapon:Fire()
                self:FireEvent("ChangeEquip", false)

                if self.Controllers.HUD.UI ~= nil then
                    local MenuButton = self.Controllers.HUD.UI:WaitForChild("MenuButton", 2)
                    if MenuButton then
                        if GIC.LastInput == Enum.UserInputType.Keyboard then
                            MenuButton.Text = "Open menu [M]"
                        end
            
                        if GIC.LastInput == Enum.UserInputType.Touch or GIC.TouchEnabled then
                            MenuButton.Text = "Open menu [Tap]"
                        end
                    end
                end
            end
        }
    })
    
    local Cooldown = false

    --sheet = "rbxasset://textures/ui/Input/TouchControlsSheetV2.png"

    MobileModule:Create(0.325, 0.05, 1, function()
        if Cooldown then return end
        Cooldown = true

        if self.WeaponState.can("equip") then
            self.WeaponState.equip()
        else
            self.WeaponState.unequip()
        end

        wait(1.5)
        Cooldown = false
    end, Vector2.new(1, 1), UDim2.new(0.975, 0, 0.725, 0), nil, "Equip")

    local WeaponMaid = Maid.new()
    self.Controllers.Character:ConnectEvent("CHARACTER_DIED_EVENT", function()
        self.WeaponState.died()
    end)

    self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function()
        WeaponMaid:DoCleaning()
        
        WeaponMaid:GiveTask(UserInputService.InputBegan:Connect(function(input)
            if Cooldown then return end
            if input.KeyCode == Enum.KeyCode.Q then
                Cooldown = true
                if self.WeaponState.can("equip") then
                    self.WeaponState.equip()
                else
                    self.WeaponState.unequip()
                end

                wait(1.5)
                Cooldown = false
            end
        end))
    end)
end


function WeaponController:Init()
    self:RegisterEvent("ChangeEquip")
    
    GIC = self.Controllers.GlobalInputController

    Maid = self.Shared.Maid
    WeaponManipulation = self.Shared.WeaponManipulation
    FSM = self.Shared.FSM
    MobileModule = self.Modules.MobileModule
end


return WeaponController