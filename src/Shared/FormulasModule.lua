-- Formulas Module
-- oniich_n
-- August 15, 2019
local repr = require(game.ReplicatedStorage:FindFirstChild("repr",true))

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local WeaponMultiplier = {
    ["Blade"] = 0.95;
    ["Scythe"] = 1.2;
};

local gPrimaryStat = {
    ["BladeDancer"] = "STR";
    ["Reaper"]      = "DEX";
};

local gSecondaryStat = {
    ["BladeDancer"] = "DEX";
    ["Reaper"]      = "LCK";
};

local FormulasModule = {}


-- local WeaponATK = {
--     ["1"] = 8;
--     ["3"] = 11;
--     ["12"] = 32;
--     ["18"] = 50;
--     ["23"] = 65;
--     ["30"] = 89;
-- }
-- for i = 1, 35 do
--     local pstat = 12+(4*(i-1))
--     local sstat = 5+(i-1)

--     local wepatk = WeaponATK[tostring(i)]
--     if not wepatk then
--         local ind = i
--         repeat
--             ind = ind-1
--             wepatk = WeaponATK[tostring(ind)]
--         until wepatk
--     end

--     local atk = (pstat/3) + (sstat/5) + (wepatk*0.8)
--     local damage = ((4.75 * pstat) + sstat)


--     print("Level", i)
--     print("WepATK:", wepatk)
--     print("ATK:", atk)
--     print("DMG:", damage)
--     print("Health:", 100+(20*(i-1)))

--     print(" ")
-- end

function FormulasModule:CalculateAttack(Blob)
    assert(Blob ~= nil, "FormulatsModule:HitDamage | Blob does not exist")
    local PrimaryWeapon = Blob.Inventory[Blob.Equipment.PrimaryWeapon]
    local PrimaryStat = Blob.Stats[gPrimaryStat[Blob.Stats.Class]]
    local SecondaryStat = Blob.Stats[gSecondaryStat[Blob.Stats.Class]]

    -- print(PrimaryStat, SecondaryStat, Blob.Stats.Class)
    -- print(PrimaryWeapon, Blob.Equipment.PrimaryWeapon, Blob.Inventory)
    -- print(PrimaryWeapon)
    -- print(PrimaryWeapon.Stats.STR)
    local WepATK = PrimaryWeapon.Stats.ATK

    return (PrimaryStat) + (SecondaryStat/4) + (WepATK)
end

local BaseA = {
    0.85, 0.8425, 0.835, 0.8275, 0.82, 0.8125, 0.805, 0.7975, 0.79, 0.7825, 0.775
}

local BaseB = {}
for i = 1, 10 do
    BaseB[i] = (100-i)/100
end

for i = 1, 20 do
    BaseB[i+10] = (90-(2*i))/100
end

function FormulasModule:CalculateDefense(Blob)
    local STR = Blob.Stats.STR
    local DEX = Blob.Stats.DEX
    local LCK = Blob.Stats.LCK
    local INT = Blob.Stats.INT

    local AddedDef = 0 -- from gear 
    local DefMult = 0 -- multiplier from outside effects

    return ((0.7 * STR) + (0.4 * (DEX + LCK)) + AddedDef) * (1 + DefMult/100)
end

function FormulasModule:CalculateMob(Mob, PlayerData)
    local LevelDiffA = math.clamp(PlayerData.Stats.Level-Mob.Stats.Level, 1, 10)
    local LevelDiffB = math.clamp(Mob.Stats.Level-PlayerData.Stats.Level, 0, 30)
    local A = BaseA[LevelDiffA]
    local B = BaseB[LevelDiffB] or 1

    local Bclamp = math.clamp(B * (self:CalculateDefense(PlayerData)), Mob.Stats.Attack*0.68, Mob.Stats.Attack*0.8)

    -- print(A, B, Bclamp)
    return (A * (Mob.Stats.Attack - Bclamp))
end



function FormulasModule:HitDamage(Blob, SkillInfo)
    -- Weapon Multiplier * ((4 * Primary Stat) + Secondary Stat) * (Attack / 100)
    assert(Blob ~= nil, "FormulatsModule:HitDamage | Blob does not exist")
    local PrimaryWeapon = Blob.Inventory[Blob.Equipment.PrimaryWeapon]
    local WPMultiplier = WeaponMultiplier[PrimaryWeapon.Subclass]
    local PrimaryStat = Blob.Stats[gPrimaryStat[Blob.Stats.Class]]
    local SecondaryStat = Blob.Stats[gSecondaryStat[Blob.Stats.Class]]

    if SkillInfo then
        -- print("Hit with skill")
        local SkillDamage = SkillInfo.Stats.BaseDamage
        if Blob.SkillInfo[SkillInfo.LocalInfo.SkillId] ~= nil then
            if Blob.SkillInfo[SkillInfo.LocalInfo.SkillId] > 1 then
                for i = 1, Blob.SkillInfo[SkillInfo.LocalInfo.SkillId]-1 do
                    SkillDamage = SkillDamage+SkillInfo.Levels.BaseDamage[i]
                end
            end
            return (SkillDamage + (self:CalculateAttack(Blob) * SkillInfo.Stats.Multiplier)) + ((2 * PrimaryStat) + (2 * SecondaryStat)) * (self:CalculateAttack(Blob)/100)
        end
    end
    return WPMultiplier * self:CalculateAttack(Blob)
end

setDefault(WeaponMultiplier, 1)
setDefault(gPrimaryStat, "STR")
setDefault(gSecondaryStat, "DEX")

return FormulasModule