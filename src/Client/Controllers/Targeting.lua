-- Targeting
-- oniich_n
-- February 6, 2019

--[[


--]]



local Targeting = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local SPAWN_REGION_EVENT = "SPAWN_REGION_EVENT"

function Targeting:Start()
	--get active Mobs
	--check distance to
	--ya yEet

	self.CombatLock = false
	self.TargetInstance = nil
	self.TargetIndex = 1
	self.Locked = false

	local TargetMaid = Maid.new()
	local CurrentCharacter = CharacterController.Character
	CharacterController:ConnectEvent('CHARACTER_ADDED_EVENT', function(Character)
		TargetMaid:DoCleaning()
		CurrentCharacter = Character
		TargetUI = ReplicatedStorage.Assets.Interface:WaitForChild("TargetUI"):Clone()
		TargetUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

		local TargetValue = Instance.new("ObjectValue")
		TargetValue.Name = "Target"
		TargetValue.Parent = Character

		TargetMaid:GiveTask(UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.T or input.UserInputType == Enum.UserInputType.MouseButton3 then
				if self.TargetInstance ~= nil then
					self.Locked = not self.Locked
					local TLevent = Character:FindFirstChild("TLevent", true)
					if TLevent ~= nil then
						TLevent:Fire()
					end
				end
			end
		end))
	end)

	CombatController:ConnectEvent('ATTACK_EVENT', function()
		self.CombatLock = true
		delay(0.5, function()
			if CombatController.IsAttacking == false then
				self.CombatLock = false
			end
		end)
	end)

	self.Targetable = CollectionService:GetTagged("Targetable")

	-- FastSpawn(function()
	-- 	while wait(2) do
	-- 		self.Targetable = CollectionService:GetTagged("Targetable")

	-- 		self.IndexSort = {}
	-- 	end
	-- end)
	self:ConnectEvent(SPAWN_REGION_EVENT, function()
		self.Targetable = CollectionService:GetTagged("Targetable")
	end)

	local camera = workspace.CurrentCamera
	local LastMob = ""
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		if CurrentCharacter == nil then return end
		if CurrentCharacter.PrimaryPart == nil then return end

		--sort by distance from camera center
		if TargetUI.Adornee == nil then
			TargetUI.Enabled = false
		else
			TargetUI.Enabled = true
		end
		
		self.Targetable = CollectionService:GetTagged("Targetable")
		
		--remove any non-combat targets during combat
		if self.Controllers.StateController.CombatCheck then
			local fT = TableUtil.Filter(self.Targetable, function(item)
				if item:IsA("Instance") then
					return not CollectionService:HasTag(item, "NCTarget")
				end
			end)

			self.Targetable = fT
		end

		if #self.Targetable >= 2 then

			if not game:GetService("UserInputService").TouchEnabled then
				table.sort(self.Targetable, function(a, b)
					local scA, osA = camera:WorldToViewportPoint(a.Position)
					local scB, osB = camera:WorldToViewportPoint(b.Position)
					local v2a = Vector2.new(scA.X, scA.Y)
					local v2b = Vector2.new(scB.X, scB.Y)
					local cpos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
					local distA = (cpos-v2a).Magnitude
					local distB = (cpos-v2b).Magnitude
					-- case 1: both are offscreen. Order them by distance from center.
					if not osA and not osB then
						return distA < distB
					-- case 2: A is offscreen. B must be "closer"
					elseif not osA then
						return false
					-- case 3: B is offscreen. A must be "closer"
					elseif not osB then
						return true
					else
					-- end case: both are onscreen. Order them by distance from center.
						return distA < distB
					end
				end)
			else
				local PlayerPosition = CurrentCharacter.PrimaryPart.Position
				table.sort(self.Targetable, function(a, b)
					local distA = (PlayerPosition-a.Position).Magnitude
					local distB = (PlayerPosition-b.Position).Magnitude
					if not distA then
						return false
					elseif not distB then
						return true
					else
						return distA < distB
					end
				end)
			end
		end 
		--target = target[1]
		self.TargetIndex = 1
		if self.Locked then
			if self.TargetInstance and self.TargetInstance:FindFirstAncestor("Workspace") ~= nil then
				self.TargetIndex = TableUtil.IndexOf(self.Targetable, self.TargetInstance)
			end
		end
		if #self.Targetable > 0 then					
			self.TargetInstance = self.Targetable[self.TargetIndex]
			if self.TargetInstance ~= nil then
				local TriggerDistance = 30
				if CollectionService:HasTag(self.TargetInstance, "NPC") then TriggerDistance = 15 end
				if self.Locked then TriggerDistance = TriggerDistance*1.5 end
				if (self.Targetable[self.TargetIndex].Position-CurrentCharacter.PrimaryPart.Position).magnitude < TriggerDistance then
					self.TargetInstance = self.Targetable[self.TargetIndex]

					local TargetValue = CurrentCharacter:FindFirstChild("Target")
					if TargetValue then
						TargetValue.Value = self.TargetInstance
					end

					TargetUI.Adornee = self.TargetInstance

					local tags = CollectionService:GetTags(self.TargetInstance)
					local pattern = "^mobid:(.+)"
					for _, tag in pairs(tags) do
						-- print(tag)
						local mobid = string.match(tag, pattern)
						if mobid ~= nil then

							local Mob = MobController.Mobs[mobid]
							if Mob and LastMob ~= mobid then
								LastMob = mobid
								local pattern = "%u+%l*"
								local NewName = ""

								if Mob.ServerParams then
									for v in Mob.ServerParams.MobType:gmatch(pattern) do
										NewName = NewName .. v .. " "
									end
									
									if HUDController.UI then
										if HUDController.UI:FindFirstChild("EnemyContainer") then
											HUDController.UI.EnemyContainer.Health.HealthDisplay.Size = UDim2.new(
												math.clamp((Mob.ServerParams.Stats.Health)/Mob.ServerParams.Stats.MaxHealth, 0, 1),
												0, 1, 0
											)
											HUDController.UI.EnemyContainer.Stagger.StaggerDisplay.Size = UDim2.new(
												math.clamp((Mob.ServerParams.Stats.Stagger)/Mob.ServerParams.Stats.MaxStagger, 0, 1),
												0, 1, 0
											)
											HUDController.UI.EnemyContainer.Health.HealthDelay.Size = HUDController.UI.EnemyContainer.Health.HealthDisplay.Size

											HUDController.UI.EnemyContainer.NameDisplay.Text = NewName .. "| Level " .. tostring(Mob.ServerParams.Stats.Level)
											HUDController.UI.EnemyContainer.Visible = true
										end
									end
								end
							end
						end
					end
					return
				end
			end
		end
		LastMob = ""
		self.TargetInstance = nil
		TargetUI.Adornee = nil
		self.Locked = false
		if HUDController.UI ~= nil then
			if HUDController.UI:FindFirstChild("EnemyContainer") ~= nil then
				HUDController.UI:FindFirstChild("EnemyContainer").Visible = false
			end
		end

		local TargetValue = CurrentCharacter:FindFirstChild("Target")
		if TargetValue then
			TargetValue.Value = nil
		end
	end)
end


function Targeting:Init()
	self.TargetInstance = nil
	TargetUI = ReplicatedStorage.Assets.Interface:WaitForChild("TargetUI"):Clone()
	Resources = require(ReplicatedStorage:WaitForChild("Resources"))
	FastSpawn = self.Shared.FastSpawn
	TableUtil = self.Shared.TableUtil
	MobData = self.Shared.MobData
	Maid = self.Shared.Maid

	CombatController = self.Controllers.Combat
	MobController = self.Controllers.MobController
	CharacterController = self.Controllers.Character
	HUDController = self.Controllers.HUD

	self:RegisterEvent(SPAWN_REGION_EVENT)
end


return Targeting