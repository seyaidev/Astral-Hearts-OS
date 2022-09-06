-- Effects Controller
-- oniich_n
-- August 5, 2019



local EffectsController = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function EffectsController:Start()
    PlayerService.CLIENT_EFFECT_EVENT:Connect(function(EffectName)
        local EffectSrc = ReplicatedStorage.Assets.Particles:FindFirstChild(EffectName)
        if EffectSrc == nil then return end
        local NewEffect = EffectSrc:Clone()
        NewEffect.Parent = workspace.Trash

        if EffectName == "LevelUp" then
            if not CharacterController.Character then return end
            NewEffect:SetPrimaryPartCFrame(CharacterController.Character:GetPrimaryPartCFrame())

            local WeldConstraint = Instance.new("WeldConstraint")
            WeldConstraint.Part0 = CharacterController.Character.PrimaryPart
            WeldConstraint.Part1 = NewEffect.PrimaryPart
            WeldConstraint.Parent = NewEffect

            for i, v in ipairs(NewEffect.Core.Attachment:GetChildren()) do
                if v:IsA("ParticleEmitter") then
                    v.Enabled = true
                    delay(1.2, function()
                        v.Enabled = false
                    end)
                end
            end
            delay(0.2, function()
                NewEffect.Area.Sparkles.Enabled = true
                delay(0.2, function()
                    NewEffect.Area.Sparkles.Enabled = false
                end)
            end)

            Debris:AddItem(NewEffect, 10)
        end
    end)
end


function EffectsController:Init()
    CharacterController = self.Controllers.Character
    PlayerService = self.Services.PlayerService
end


return EffectsController