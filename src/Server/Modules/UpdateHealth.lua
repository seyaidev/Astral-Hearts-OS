-- Update Health
-- Username
-- December 29, 2019



local UpdateHealth = {}


return function(Player, Blob, ClassParams)
    --Set the health properly
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end

    local NewHealth = ClassParams.BaseHealth+((Blob.Stats.Level-1)*ClassParams.HealthGrowth)

    for i,v in pairs(Blob.Equipment) do
        local item = Blob.Inventory[i]
        if item then
            --check for health bonus
            if item.Stats then
                if item.Stats.Health then
                    BonusHealth = BonusHealth+item.Stats.Health
                end
            end
        end
    end
    Humanoid.MaxHealth = NewHealth
    Humanoid.Health = Humanoid.MaxHealth
end