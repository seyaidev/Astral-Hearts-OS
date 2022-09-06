-- Weapon Service
-- Username
-- September 7, 2019



local WeaponService = {Client = {}}
WeaponService.__aeroOrder = 2
local LastEquip = {}

local WeaponManipulation


function WeaponService:LoadWeapons(Player)
    if Player.Character == nil then return end
    WeaponManipulation:LoadWeapons(Player)
    wait()
    WeaponManipulation:Unequip(Player)
    WeaponManipulation:SetupDisc(Player)
end

function WeaponService:Equip(Player)
    WeaponManipulation:Equip(Player)
end

function WeaponService:Unequip(Player)
    WeaponManipulation:Unequip(Player)
    WeaponManipulation:SetupDisc(Player)
end

function WeaponService:Start()

    self:ConnectClientEvent("LoadWeapons", function(Player)
        self:LoadWeapons(Player)
    end)

    self:ConnectClientEvent("EquipWeapon", function(Player)
        if LastEquip[Player.UserId] == nil then
            LastEquip[Player.UserId] = 0
        end
        -- print("eq1")
        if LastEquip[Player.UserId] > 0 then return end
        -- print("eq2")
        self.State[Player] = true
        self:Equip(Player)
    end)

    self:ConnectClientEvent("UnequipWeapon", function(Player)
        self.State[Player] = false
        self:Unequip(Player)
    end)

    game:GetService("RunService").Heartbeat:Connect(function(dt)
        for i, v in pairs(LastEquip) do
            LastEquip[i] = math.clamp(v-dt, 0, 4)
        end
    end)
end


function WeaponService:Init()
    self.State = {}
    WeaponManipulation = self.Shared.WeaponManipulation

	self:RegisterClientEvent("LoadWeapons")
	self:RegisterClientEvent("EquipWeapon")
	self:RegisterClientEvent("UnequipWeapon")
	-- self:RegisterClientEvent("AttachDisc")
end


return WeaponService