-- Freeflow
-- oniich_n
-- January 22, 2019

--[[
	Evasion + other Freeflow commands OWO
	Air sliding :O
	Air attacks
	Wall dashing
--]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Freeflow = {}
local FREEFLOW_ACTION_EVENT = "FREEFLOW_ACTION_EVENT"
local jumpTweakerApi = require(ReplicatedStorage:WaitForChild("JumpTweakerAPI"))

local Distance = 25

local Counter = 0
local LastFlow = 0

local Cooldown = 0

function Freeflow:Start()
	local Player = game.Players.LocalPlayer
	local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local CurrentCharacter = CharacterController.Character
	local Humanoid

	local function Evade()
		if Cooldown > 0 then return end
		if self.Controllers.TypingController.IsTyping then return end
		if CurrentCharacter == nil then return end 	
		if CurrentCharacter.PrimaryPart == nil then return end

		if CombatController.IsAttacking then return end
		if CombatController.CanAttack == "EVADE" then return end
		if StaggerController.Techable == false then return end
		if self.Controllers.StateController.CharacterState.cannot("evade") then return end
		self.Controllers.StateController.CharacterState.evade()
		
		if Humanoid == nil then
			Humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		end

		for i, v in pairs(CurrentCharacter.PrimaryPart:GetChildren()) do
			if v:IsA("BodyPosition") or v:IsA("BodyGyro") then
				v:Destroy()
			end
		end

		Humanoid.WalkSpeed = 0
		jumpTweakerApi:SetCharacterBehavior(CurrentCharacter, "JumpingEnabled", false)

		wait()
		local direction = -CurrentCharacter.PrimaryPart.CFrame.lookVector
		if Humanoid.MoveDirection.magnitude > 0 then
			direction = Humanoid.MoveDirection
		end

		LastFlow = 0
		local Lift = 0

		Counter = Counter+1
		-- 	Lift = 30000
		-- 	Counter = 6
		-- end
		CombatController.CanAttack = "EVADE"
		-- print("Evading...")
		self:FireEvent(FREEFLOW_ACTION_EVENT, "Evade")
		local BodyPosition = Instance.new("BodyPosition")
		BodyPosition.MaxForce = Vector3.new(30000, Lift, 30000)
		BodyPosition.D = 1000
		BodyPosition.P = 7500
		BodyPosition.Position = CurrentCharacter:GetPrimaryPartCFrame().p + direction*Distance
		BodyPosition.Parent = CurrentCharacter.PrimaryPart
		wait(self.Controllers.StateController.StateAnimations:GetTrack("Evade").Length-(7/60))
	
		-- print("Evade finished")

		if BodyPosition ~= nil then BodyPosition:Destroy() end

		Humanoid.WalkSpeed = 22
		jumpTweakerApi:SetCharacterBehavior(CurrentCharacter, "JumpingEnabled", true)
		CombatController.CanAttack = true
		
		Cooldown = 3
		local CooldownDisplay = self.Controllers.HUD.UI:WaitForChild("SkillsContainer")
		local Display = CooldownDisplay:FindFirstChild("Dodge")
		Display:FindFirstChild("Overlay").Size = UDim2.new(1,0,1,0)
		TweenService:Create(Display:FindFirstChild("Overlay"), TweenInfo.new(Cooldown, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 0, 0)
		}):Play()
		Display:FindFirstChild("Label").Text = tostring(Cooldown)
		FastSpawn(function()
			for i = Cooldown, 0, -0.1 do
				wait(0.1)
				if i > 1 then
					Display:FindFirstChild("Label").Text = tostring(GlobalMath:round(i))
				else
					Display:FindFirstChild("Label").Text = string.sub(tostring(i), 1, 3)
				end
			end

			Display:FindFirstChild("Label").Text = "Evade"
		end)

		if self.Controllers.StateController.CharacterState.can("evade_end") then
			self.Controllers.StateController.CharacterState.evade_end()
		end
	end

	game:GetService("RunService").Heartbeat:Connect(function(dt)
		if Cooldown > 0 then
			Cooldown = Cooldown - dt
		end
	end)

	CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function()
		self.Maid:DoCleaning()
	end)

	local m

	CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		CurrentCharacter = Character
		Humanoid = Character:WaitForChild("Humanoid")

		self.Maid:GiveTask(game:GetService("RunService").Heartbeat:Connect(function(dt)
			LastFlow = LastFlow+dt
			if LastFlow >= 1.5 and Counter > 0 then
				Counter = 0
			end
	
			if Counter >= 5 then return end
		end))
	
		self.Maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode ~= Enum.KeyCode.LeftShift then return end
			Evade()
		end))

		
		local CooldownDisplay = self.Controllers.HUD.UI:WaitForChild("SkillsContainer")
		local Display = CooldownDisplay:FindFirstChild("Dodge")
		Display.Label.Text = "Evade"
		Display.Overlay.Size = UDim2.new(1, 0, 0, 0)

		if m then m:Destroy() end

		m = self.Modules.MobileModule:Create(0.55, 0.7, 0.11, Evade)
		if m then
			--move evade thing to here
			local c = self.Controllers.HUD.UI.SkillsContainer:FindFirstChild("Dodge")
			c.Size = m.Size
			c.Position = m.Position
			c.AnchorPoint = m.AnchorPoint
		end
		print("Activated Freeflow")
	end)
end


function Freeflow:Init()
	CombatController = self.Controllers.Combat
	CharacterController = self.Controllers.Character
	StaggerController = self.Controllers.StaggerController
	Keyboard = self.Controllers.UserInput:Get("Keyboard")
	Gamepad = self.Controllers.UserInput:Get("Gamepad")
	FastSpawn = self.Shared.FastSpawn
	GlobalMath = self.Shared.GlobalMath

	self:RegisterEvent(FREEFLOW_ACTION_EVENT)
	Maid = self.Shared.Maid
	self.Maid = Maid.new()
end


return Freeflow