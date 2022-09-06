-- Dummy Module
-- oniich_n
-- July 12, 2019



local DummyModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClothingModule = require(script.Parent:WaitForChild("ClothingModule"))

function DummyModule:Create(CurrentData)
    if CurrentData.BodyType == nil then return end
    local Dummy = ReplicatedStorage.CharacterAssets:WaitForChild("CharacterDummy-" .. CurrentData.BodyType):Clone()
    Dummy.Name = "CharacterDummy"
    -- Dummy.PrimaryPart.Anchored = false
    Dummy:SetPrimaryPartCFrame(workspace:FindFirstChild("NormalSpawn", true).CFrame)

    local Disc = ReplicatedStorage.CharacterAssets.Disc:Clone()
    Disc.Parent = Dummy

    local BodyColors = Dummy:FindFirstChildOfClass("BodyColors")
        
    local bodyColor = Color3.new(CurrentData.Tone.r, CurrentData.Tone.g, CurrentData.Tone.b)
    BodyColors.HeadColor3 = bodyColor
    BodyColors.LeftArmColor3 = bodyColor
    BodyColors.LeftLegColor3 = bodyColor
    BodyColors.RightArmColor3 = bodyColor
    BodyColors.RightLegColor3 = bodyColor
    BodyColors.TorsoColor3 = bodyColor

    --update proportions
    local Scales = {
        ["Height"] = {0.85, 1.05};
        ["Width"] = {0.65, 0.85};
        ["Depth"] = {0.7, 0.85};
        ["Head"] = {0.95, 1.05};
    }

    local DummyHumanoid = Dummy:FindFirstChild("Humanoid")
    
    DummyHumanoid.AutomaticScalingEnabled = false
    DummyHumanoid.BodyHeightScale.Value = Scales["Height"][1] + (Scales["Height"][2]-Scales["Height"][1])*CurrentData.Proportions["Height"]
    DummyHumanoid.BodyWidthScale.Value = Scales["Width"][1] + (Scales["Width"][2]-Scales["Width"][1])*CurrentData.Proportions["Width"]
    DummyHumanoid.BodyDepthScale.Value = Scales["Depth"][1] + (Scales["Depth"][2]-Scales["Depth"][1])*CurrentData.Proportions["Depth"]
    DummyHumanoid.HeadScale.Value = Scales["Head"][1] + (Scales["Head"][2]-Scales["Head"][1])*CurrentData.Proportions["Head"]
    DummyHumanoid.AutomaticScalingEnabled = true

    --replicate Hair accessory
    local newHair = ReplicatedStorage.CharacterAssets.Hair:FindFirstChild(CurrentData.HairStyle):Clone()
    newHair.Name = "HairStyle"
    newHair.Parent = Dummy
    newHair:FindFirstChild("Mesh", true).VertexColor = Vector3.new(
        CurrentData.HairColor.r,
        CurrentData.HairColor.g,
        CurrentData.HairColor.b
    )
    Dummy.Parent = ReplicatedStorage
    wait()
    --get asset ids for clothing from Clothing Cache
    
    Dummy.Shirt.ShirtTemplate = ClothingModule.Shirts[CurrentData.Shirt]
    Dummy.Pants.PantsTemplate = ClothingModule.Pants[CurrentData.Pants]

    for i, v in ipairs(ReplicatedStorage.CharacterAssets.Sounds:GetChildren()) do
        v:Clone().Parent = Dummy.PrimaryPart
    end
    return Dummy
end

return DummyModule