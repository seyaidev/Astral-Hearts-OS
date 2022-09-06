-- Stagger Controller
-- oniich_n
-- June 9, 2019

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StaggerController = {}
local jumpTweakerApi = require(ReplicatedStorage:WaitForChild("JumpTweakerAPI"))

local CharacterController
local CombatController
local MovementController

function StaggerController:Start()
    self.Maid = Maid.new()
    self.Services.MobService.Stagger:Connect(function()
        for i, v in pairs(CharacterController.Character.PrimaryPart:GetChildren()) do
			if v:IsA("BodyMover") then
				v:Destroy()
			end
		end

		if CharacterController.Character.Humanoid ~= nil then
			CharacterController.Character.Humanoid.WalkSpeed = 0
		end

		local raycast = Ray.new(CharacterController.Character:GetPrimaryPartCFrame().p, -CharacterController.Character:GetPrimaryPartCFrame().lookVector*3) --replace 15 with class parameters
		local hit, pos = workspace:FindPartOnRayWithIgnoreList(raycast, {
			CharacterController.Character,
			workspace.Trash,
			workspace.Markers, workspace.Mobs
		})

		local BodyPosition = nil
		BodyPosition = Instance.new("BodyPosition")
		BodyPosition.MaxForce = Vector3.new(30000,0,30000)
		BodyPosition.Position = pos
		BodyPosition.Parent = CharacterController.Character.PrimaryPart
        jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", false)

		Debris:AddItem(BodyPosition, MovementController.CurrentPlayer:GetTrack("Stagger").Length)
		--play stagger animations
		CombatController.CombatAnimations:StopAllTracks()
		MovementController.CurrentPlayer:StopAllTracks()
		MovementController.HM.stagger()
		MovementController.CurrentPlayer:PlayTrack("Stagger")
		self._AnimTrack = MovementController.CurrentPlayer:GetTrack("Stagger")

		--wait until animation has ended before returning to idle
		self.Maid:GiveTask(MovementController.CurrentPlayer:GetTrack("Stagger").Stopped:Connect(function()
			-- print("has bpos:", BodyPosition)
			if CharacterController.Character.Humanoid ~= nil then
				-- print("HELLO")
                jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)
				CharacterController.Character.Humanoid.WalkSpeed = 22
			end
			if BodyPosition ~= nil then BodyPosition:Destroy() end
			MovementController.HM.stop()
			self.Techable = "not in state"
			self.Maid:DoCleaning()
			-- LocalServices._CombatStates:Change("idle", {["LocalServices"] = LocalServices})
			-- if BodyGyro ~= nil then BodyGyro:Destroy() end
		end))
    end)

	self.Services.MobService.Flyback:Connect(function(Multiplier, FBVector)
		self.Techable = false
        for i, v in pairs(CharacterController.Character.PrimaryPart:GetChildren()) do
			if v:IsA("BodyMover") then
				v:Destroy()
			end
		end

		if CharacterController.Character.Humanoid ~= nil then
			jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", false)
			CharacterController.Character.Humanoid.WalkSpeed = 0
		end

		local raycast = Ray.new(CharacterController.Character:GetPrimaryPartCFrame().p, FBVector*Multiplier*17) --replace 15 with class parameters
		local hit, pos = workspace:FindPartOnRayWithIgnoreList(raycast, {
			CharacterController.Character,
			workspace.Trash,
			workspace.Markers, workspace.Mobs
		})

		local BodyPosition = nil
		local BodyGyro = nil
		BodyPosition = Instance.new("BodyPosition")
		BodyPosition.MaxForce = Vector3.new(30000,0,30000)
		BodyPosition.Position = pos
		BodyPosition.Parent = CharacterController.Character.PrimaryPart
		Debris:AddItem(BodyPosition, MovementController.CurrentPlayer:GetTrack("Flyback").Length)

		BodyGyro = Instance.new("BodyGyro")
		BodyGyro.D = 10
		BodyGyro.MaxTorque = Vector3.new(0, 400000, 0)local raycast = Ray.new(CharacterController.Character:GetPrimaryPartCFrame().p, FBVector*Multiplier*17) --replace 15 with class parameters
		local hit, pos = workspace:FindPartOnRayWithIgnoreList(raycast, {
			CharacterController.Character,
			workspace.Trash,
			workspace.Markers, workspace.Mobs
		})
		BodyGyro.P = 3000
		BodyGyro.CFrame = CFrame.new(CharacterController.Character:GetPrimaryPartCFrame().p, CharacterController.Character:GetPrimaryPartCFrame().p-FBVector*2)
		BodyGyro.Parent = CharacterController.Character.PrimaryPart
		Debris:AddItem(BodyGyro, MovementController.CurrentPlayer:GetTrack("Flyback").Length)

		CombatController.CombatAnimations:StopAllTracks()
		MovementController.CurrentPlayer:StopAllTracks()
		MovementController.HM.flyback()
		MovementController.CurrentPlayer:PlayTrack("Flyback")
		self._AnimTrack = MovementController.CurrentPlayer:GetTrack("Flyback")
		--wait for tech time
		self.Maid:GiveTask(function()
			if BodyPosition ~= nil then BodyPosition:Destroy() end
			if BodyGyro ~= nil then BodyGyro:Destroy() end
		end)
		self.Maid:GiveTask(MovementController.CurrentPlayer:GetTrack("Flyback").KeyframeReached:Connect(function(kf)
			if kf == "TechStart" then
				self.Techable = true
				--spawn tech particles
				local TechCore = ReplicatedStorage:FindFirstChild("TechCore", true):Clone()
				TechCore.Position = CharacterController.Character.LowerTorso.Position
				TechCore.Parent = workspace.Trash
				for i, v in pairs(TechCore:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = true
						delay(0.05, function()
							v.Enabled = false
						end)
					end
				end

				Debris:AddItem(TechCore, 1)
			elseif kf == "TechEnd" then
				self.Techable = false
			end
		end))

		self.Maid:GiveTask(MovementController.CurrentPlayer:GetTrack("Flyback").Stopped:Connect(function()
			-- LocalServices._CombatStates:Change("idle", {["LocalServices"] = LocalServices})
			if CharacterController.Character.Humanoid ~= nil then
			jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)
            CharacterController.Character.Humanoid.WalkSpeed = 22--LocalServices._Stances.Current:GetSpeed()
			end
			if BodyPosition ~= nil then BodyPosition:Destroy() end
			if BodyGyro ~= nil then BodyGyro:Destroy() end
			MovementController.HM.stop()
			self.Techable = "not in state"
			self.Maid:DoCleaning()
		end))
    end)
end


function StaggerController:Init()
	self.InStagger = false
	self.Techable = "not in state"
    
    self:RegisterEvent("Stagger")
    self:RegisterEvent("Flyback")

    CharacterController = self.Controllers.Character
    CombatController = self.Controllers.Combat

    Maid = self.Shared.Maid
end


return StaggerController