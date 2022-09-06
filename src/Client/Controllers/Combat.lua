-- Combat
-- oniich_n
-- December 29, 2018

--[[


--]]


local Player = game.Players.LocalPlayer
local Combat = {}
local ATTACK_EVENT = "ATTACK_EVENT"
--define input objects
local Mouse
local Keyboard
local AnimationPlayer
local AnimationLibrary

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorage = replicatedStorage
local jumpTweakerApi = require(replicatedStorage:WaitForChild("JumpTweakerAPI"))

function Combat:ReloadAniamtions(AnimationTable)
	self.CombatAnimations:ClearAllTracks()
	for i, v in pairs(AnimationTable) do
		self.CombatAnimations:AddAnimation(i, v)
	end
end

function Combat:Start()
	-- wait for input to exist
	repeat
		Mouse = self.Controllers.UserInput:Get("Mouse")
		Keyboard = self.Controllers.UserInput:Get("Keyboard")
		Gamepad = self.Controllers.UserInput:Get("Gamepad")
		CharacterController = self.Controllers.Character
		wait()
	until Mouse ~= nil and Keyboard ~= nil and CharacterController ~= nil


	self.TimeSinceLastAttack = 0
	local AttackCounter = 1
	local ClassParams = self.Shared.ClassParams:Get(self.Controllers.DataBlob.Blob.Stats.Class)

	local function CAST(SIZE)
		local hits, pos, norm = Boxcast(
			CharacterController.Character:GetPrimaryPartCFrame(),
			CharacterController.Character:GetPrimaryPartCFrame().lookVector*7,
			SIZE or Vector3.new(7, 6, 2),
			{workspace.Mobs},
			false
		)
		-- print(#hits)
		if #hits > 0 then
			--place into total hits after parsing and stuff
			--format [hit] = {mobid, already_hit_bool}
			
			for i, v in pairs(hits) do
				-- print(v)
				local tags = CollectionService:GetTags(v)
				local pattern = "^mobid:(.+)"
				for _, tag in pairs(tags) do
					-- print(tag)
					local mobid = string.match(tag, pattern)
					if mobid ~= nil then
						if self.ParsedAttacks[mobid] == nil then
							self.ParsedAttacks[mobid] = "queued"
							-- print(#self.ParsedAttacks, mobid)
							self.Controllers.StateController.CombatTimer = 0
							
							break
						end
					end
				end
			end
		end
	end

	--core attack function
	local function Attack()
		--play animation
		--track active frames with KeyframeReached, sets bool to be used in Heartbeat
		--play effects based on keyframes
		-- print(self.CanAttack)

		if typeof(self.CanAttack) ~= "boolean" then return end
		if not self.CanAttack then return end
		if self.IsAttacking then return end
		if self.Controllers.StateController.CharacterState.cannot("attack") then return end
		if self.Controllers.WeaponController.WeaponState.current == "unequipped" then return end
		self.IsAttacking = true
		self.Controllers.StateController.CharacterState.attack()		

		-- print(AttackCounter) --do attack animation and stuff

		self:FireEvent(ATTACK_EVENT)

		local NewCF = CharacterController.Character:GetPrimaryPartCFrame()

		local AttackRay
		if TargetingController.TargetInstance ~= nil then
			--TargetingController.Target should be BasePart::Hitbox
			AttackRay = Ray.new(NewCF.p, CFrame.new(
				NewCF.p, TargetingController.TargetInstance.Position
			).lookVector*10)
		else
			AttackRay = Ray.new(NewCF.p, NewCF.lookVector*10)
		end

		local hit, pos = workspace:FindPartOnRayWithWhitelist(AttackRay, {workspace.Mobs})

		local BodyPosition = nil
		local BodyGyro = nil
		CharacterController.Character.Humanoid.WalkSpeed = 0
		jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", false)
		if (CharacterController.Character:GetPrimaryPartCFrame().p-pos).Magnitude > 4.5 then
			BodyPosition = Instance.new("BodyPosition")
			BodyPosition.MaxForce = Vector3.new(30000,0,30000)
			BodyPosition.Position = pos
			BodyPosition.Parent = CharacterController.Character.PrimaryPart
		end

		BodyGyro = Instance.new("BodyGyro")
		BodyGyro.D = 10
		BodyGyro.MaxTorque = Vector3.new(0, 400000, 0)
		BodyGyro.P = 3000
		BodyGyro.CFrame = CFrame.new(NewCF.p, pos)
		BodyGyro.Parent = CharacterController.Character.PrimaryPart

		CharacterController.Character:FindFirstChild("Trail", true).Enabled = true
		self.CombatAnimations:PlayTrack(tostring(AttackCounter))
		local Sound = CharacterController.Character:FindFirstChild("Attack" .. tostring(AttackCounter), true)
		if Sound then
			Sound:Play()
		end

		self.KFMaid:GiveTask(self.CombatAnimations:GetTrack(tostring(AttackCounter)):GetMarkerReachedSignal("Cast"):Connect(function(value)
			local x, y, z = value:match("(%d+),(%d+),(%d+)")

			self.ParsedAttacks = {}
			CAST(Vector3.new(x, y, z))
		end))

		-- self.KFMaid:GiveTask(self.CombatAnimations:GetTrack(tostring(AttackCounter)).KeyframeReached:Connect(function(kf_name)

		-- 	if kf_name == "Cast" then
		-- 		self.ParsedAttacks = {}
		-- 		CAST()	
		-- 	end

		-- 	if CharacterController.Character:FindFirstChild("Trail", true) == nil then return end
		-- 	if kf_name == "Activate" then
		-- 		CharacterController.Character:FindFirstChild("Trail", true).Enabled = true
		-- 		self.ActiveFrames = true
		-- 	elseif kf_name == "Deactivate" then
		-- 		if CharacterController.Character:FindFirstChild("Trail", true) then
		-- 			CharacterController.Character:FindFirstChild("Trail", true).Enabled = false
		-- 			self.ActiveFrames = false
		-- 			self.ParsedAttacks = {}
		-- 		end
		-- 	end
		-- end))

		local Length = self.CombatAnimations:GetTrack(tostring(AttackCounter)).Length --or 0.2
		delay(Length-(5/60), function()
			if self.Controllers.StateController.CharacterState.can("attack_end") then
				self.Controllers.StateController.CharacterState.attack_end()
			end
			if CharacterController.Character:FindFirstChild("Trail", true) == nil then return end
			CharacterController.Character:FindFirstChild("Trail", true).Enabled = false
		end)

		wait(Length-(5/60))
		if BodyGyro then BodyGyro:Destroy() end
		if BodyPosition then BodyPosition:Destroy() end

		CharacterController.Character.Humanoid.WalkSpeed = 22

		AttackCounter = AttackCounter+1
		self.IsAttacking = false
		self.TimeSinceLastAttack = 0
		self.KFMaid:DoCleaning()

		if AttackCounter > ClassParams.MaxAttacks then --change to max attacks based on class
			AttackCounter = 1
			self.CanAttack = false

			jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)

			delay(0.35, function()
				self.CanAttack = true

			end)
		end
	end

	local Packets = {}
	-- FastSpawn(function()
	-- 	while wait(1/10) do
	-- 		self.Services.LegacyMobHook.MobQueue:Fire(Packets)
	-- 		Packets = {}
	-- 	end
	-- end)

	--cleanup tasks on death
	CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function()
		self.CanAttack = true
		self.Maid:DoCleaning()
	end)

	--character added maid tasks

	
	local a
	CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		wait(1)
		local Humanoid = Character:WaitForChild("Humanoid")
		self.CombatAnimations = AnimationPlayer.new(Humanoid)

		local Blob = self.Controllers.DataBlob.Blob
		local EquippedInfo = Blob.Inventory[Blob.Equipment["PrimaryWeapon"]]

		local Pool = AnimationLibrary["Weapon"][EquippedInfo.Subclass][EquippedInfo.Id]
		for i, v in pairs(Pool) do --eventually pull from playerinfo
			self.CombatAnimations:AddAnimation(i, v)
		end

		self.CanAttack = true
		self.IsAttacking = false

		repeat
			wait()
		until CharacterController.Character ~= nil
		-- print(CharacterController.Character)
		
		--give tasks to maid
		self.Maid:GiveTask(Mouse.LeftDown:Connect(function()
			if self.Controllers.Camera.PlayerCamera._MouseLock then
				Attack()
			end
		end))

		if a then a:Destroy() end
		a = self.Modules.MobileModule:Create(0.7, 1.5, -0.1, Attack, Vector2.new(), nil, nil, "Attack")


		self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
			for mobid, already_hit_trigger in pairs(self.ParsedAttacks) do
				-- print(mobid, already_hit_trigger)
				if already_hit_trigger == "queued" then
					self.ParsedAttacks[mobid] = true
					--process attack to Aero.Services once/second
	
					table.insert(Packets, {mobid, tick()})
	
					self.Controllers.MobController:FireEvent("DAMAGE_EVENT", mobid)
					-- print("Attacked:", mobid)
				end
			end
	
			if not self.IsAttacking then
				self.TimeSinceLastAttack = self.TimeSinceLastAttack+dt
				if self.TimeSinceLastAttack > 0.65 and AttackCounter > 1 and typeof(self.CanAttack) == "boolean" then
					-- print("Resetting counter...")
					self.TimeSinceLastAttack = 0
					AttackCounter = 1
					self.CanAttack = false
	
					jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)
	
					delay(0.2, function() self.CanAttack = true end)
				end
	
				if self.TimeSinceLastAttack > 2 and not self.Controllers.SkillsController.ActiveSkill then
					if self.ActiveWeapon then
						AttackCounter = 1
						self.CanAttack = true
						jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)

						delay(0.35, function()
							self.CanAttack = true
						end)
					end
						
					-- self.WeaponParent.Transparency = 1
					-- for i, v in pairs(self.WeaponParent:GetDescendants()) do
					-- 	if v:IsA("BasePart") then
					-- 		v.Transparency = 1
					-- 	end
					-- end
				end
			else
				--if active frames then do the thing
				if self.ActiveFrames then
					CAST()
				end
			end
		end))

		print("Activated combat")
	end)
end


function Combat:Init()
	self.CombatAnimations = nil
	self.ParsedAttacks = {}
	self.PackagedAttacks = {}

	AnimationLibrary = self.Shared.Cache:Get("AnimationLibrary")
	AnimationPlayer = self.Shared.AnimationPlayer
	Boxcast = self.Shared.Boxcast
	WeaponManipulation = self.Shared.WeaponManipulation
	
	Maid = self.Shared.Maid
	self.KFMaid = Maid.new()
	self.Maid = Maid.new()

	FastSpawn = self.Shared.FastSpawn

	TaskScheduler = self.Controllers.TaskScheduler
	TargetingController = self.Controllers.Targeting
	self:RegisterEvent(ATTACK_EVENT)
end


return Combat