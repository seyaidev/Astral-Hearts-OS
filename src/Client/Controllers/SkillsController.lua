-- Skills Controller
-- oniich_n
-- June 4, 2019



local SkillsController = {}

local Keyboard
local AnimationPlayer
local AnimationLibrary

local AnimationLibrary 	
local AnimationPlayer 	
local Boxcast 			
local SkillCache 			
local Maid 				
local Resources 			
local FastSpawn 			
local TaskScheduler 		
local TargetingController
local DataBlob 			
local CharacterController

local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = replicatedStorage
local jumpTweakerApi = require(replicatedStorage:WaitForChild("JumpTweakerAPI"))
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")

function SkillsController:Start()
	self.KFMaid = Maid.new()

	local skillCode1, skillCode2, skillCode3 = Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.F

	local function LoadAnimations(Character)
		wait(1)
		self.SkillAnimations = AnimationPlayer.new(Character.Humanoid)
		for i, v in pairs(DataBlob.Blob.ActiveSkills) do
			self.SkillAnimations:AddAnimation(v, AnimationLibrary["Skill"][v])
		end
	end

	-- LoadAnimations(CharacterController.Character)

	local function MeleeCast(SkillId, SuperInfo)
		local SkillInfo = TableUtil.Copy(SkillCache:Get(SkillId))
		if SkillInfo == nil then print("WHAT HTE HOOPLA") return end
		
		if SuperInfo then
			SkillInfo.LocalInfo = SuperInfo
		end
		local LocalInfo = SkillInfo.LocalInfo

		--play animation
		--boxcast on active frame
		
		local SkillHits = {}
		local bbox = CharacterController.Character:GetExtentsSize()
		for i = 1, LocalInfo.activef do
			RunService.Stepped:wait()
			-- print("owo11!")
			local hits, pos, norm = Boxcast(
				CharacterController.Character:GetPrimaryPartCFrame(),
				CharacterController.Character:GetPrimaryPartCFrame().lookVector*LocalInfo.range,
				LocalInfo.size,
				{workspace.Mobs}
			)

			if #hits > 0 then
				local function checkHit(mobid)
					for i, v in pairs(SkillHits) do
					--	print(v, hit:FindFirstAncestorOfClass("Folder"))
						if v == mobid then
							return false
						end
					end
					return true
				end
				for i, hit in pairs(hits) do
					if hit ~= nil then
						local tags = CollectionService:GetTags(hit)
						for j, tag in pairs(tags) do
							local id = tag:match("^mobid:(.+)")
							if id then
								-- print(id)
								if checkHit(id) then
									table.insert(SkillHits, id)
									self.Controllers.StateController.CombatTimer = 0
								end
							end
						end
					end
				end
			end
		end

		-- local kbhits = {}
		for i, v in pairs(SkillHits) do
			-- table.insert(kbhits, {v, tick()})

			self.Controllers.MobController:FireEvent("DAMAGE_EVENT", v, SkillInfo)
		end
	end

	local Controls = {"E", "R", "F"}

	local function SkillCmd(SkillId, Slot)
		--put on cooldown
		--play animation
		--disable other calls
		local SkillInfo = SkillCache:Get(SkillId)
		local Blob = self.Controllers.DataBlob.Blob
		if Blob == nil then return end
		if SkillInfo == nil then return end
		if self.ActiveSkill then return end
		
		if self.Cooldowns[SkillId] == nil then self.Cooldowns[SkillId] = 0 end
		if self.Cooldowns[SkillId] > 0 then  return end

		if self.Controllers.StateController.CharacterState.cannot("cast") then return end
		if CharacterController.Character:FindFirstChild("Trail", true) == nil then return end
		if self.SkillAnimations:GetTrack(SkillId) == nil then print('skill3') return end

		if self.Controllers.WeaponController.WeaponState.current == "unequipped" then return end

		self.ActiveSkill = true
		self.Controllers.StateController.CharacterState.cast()

		-- tell server to cast skill
		self.SkillAnimations:PlayTrack(SkillId)
		if CharacterController.Character.PrimaryPart:FindFirstChild(SkillId) then
			CharacterController.Character.PrimaryPart:FindFirstChild(SkillId):Play()
		end


		local NewCooldown = SkillInfo.Stats.Cooldown
        if Blob.SkillInfo[SkillId] > 1 then
            for i = 1, Blob.SkillInfo[SkillId]-1 do
                NewCooldown = NewCooldown+SkillInfo.Levels.Cooldown[i]
            end
        end

		self.Cooldowns[SkillId] = NewCooldown
		local Display = self.Controllers.HUD.UI.SkillsContainer:FindFirstChild(Slot)
		Display:FindFirstChild("Overlay").Size = UDim2.new(1,0,1,0)
		TweenService:Create(Display:FindFirstChild("Overlay"), TweenInfo.new(NewCooldown, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 0, 0)
		}):Play()
		Display:FindFirstChild("Label").Text = tostring(NewCooldown)
		FastSpawn(function()
			for i = NewCooldown, 0, -0.1 do
				wait(0.1)
				if Display:FindFirstChild("Label") then
					if i > 1 then
						Display:FindFirstChild("Label").Text = tostring(GlobalMath:round(i))
					else
						Display:FindFirstChild("Label").Text = string.sub(tostring(i), 1, 3)
					end
				end
			end
			if Display:FindFirstChild("Label") then
				Display:FindFirstChild("Label").Text = Controls[tonumber(string.sub(Slot, 5, 5))]
			end
		end)

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

		local BodyGyro = nil
		CharacterController.Character.Humanoid.WalkSpeed = 0
		jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", false)

		BodyGyro = Instance.new("BodyGyro")
		BodyGyro.D = 10
		BodyGyro.MaxTorque = Vector3.new(0, 400000, 0)
		BodyGyro.P = 3000
		BodyGyro.CFrame = CFrame.new(NewCF.p, pos)
		BodyGyro.Parent = CharacterController.Character.PrimaryPart

		local function Cleanup()
			self.CanCancel = true
			self.ActiveSkill = false
			self.KFMaid:DoCleaning()
			if self.Controllers.StateController.CharacterState.can("cast_end") then
				self.Controllers.StateController.CharacterState.cast_end()
			end
			-- print('skill success:', SkillId)
			if BodyGyro ~= nil then
				BodyGyro:Destroy()
			end
			CharacterController.Character.Humanoid.WalkSpeed = 22
			jumpTweakerApi:SetCharacterBehavior(CharacterController.Character, "JumpingEnabled", true)
		end

		delay(self.SkillAnimations:GetTrack(SkillId).Length, Cleanup)
		
		CharacterController.Character:FindFirstChild("Trail", true).Enabled = true
		delay(self.SkillAnimations:GetTrack(SkillId).Length, function()
			CharacterController.Character:FindFirstChild("Trail", true).Enabled = false
		end)

		self.KFMaid:GiveTask(self.SkillAnimations:GetTrack(SkillId):GetMarkerReachedSignal("Cast"):Connect(function(value)
			local x, y, z = value:match("(%d+),(%d+),(%d+)")
			local SuperInfo = {
				activef = 3,
				skilltype = "attack_melee",
				size = Vector3.new(x, y, z),
				range = z,
				SkillId = "DeathSentence",
				hits = 5
			}
			FastSpawn(function()
				MeleeCast(SkillId, SuperInfo)
			end)
		end))

		self.KFMaid:GiveTask(self.SkillAnimations:GetTrack(SkillId).KeyframeReached:Connect(function(kf)
			if kf == "Cast" then
				FastSpawn(function()
					if SkillInfo.LocalInfo.skilltype == "attack_melee" then
						MeleeCast(SkillId)
						self.Controllers.Combat.TimeSinceLastAttack = 0
					end
				end)
			elseif kf == "Finish" then
				self.CanCancel = true
				self.ActiveSkill = false
				-- LocalServices._CombatStates:Change("idle", {["LocalServices"] = LocalServices})
				self.KFMaid:DoCleaning()
				print('skill success:', SkillId)
				if self.Controllers.StateController.CharacterState.can("cast_end") then
					self.Controllers.StateController.CharacterState.cast_end()
				end

				CharacterController.Character:FindFirstChild("Trail", true).Enabled = false
			end
		end))

		self.KFMaid:GiveTask(self.SkillAnimations:GetTrack(SkillId).Stopped:Connect(function(kfn)
			Cleanup()
		end))
	end

	local buttons = {}

	local function CreateButtons()
		for i, v in ipairs(buttons) do
			v:Destroy()
			buttons[i] = nil
		end

		local t = {
			["Slot1"] = {
				0.4, --sscale
				2.2, --xscale
				-1, --yscale
				SkillCmd,
				nil,
				nil,
				{DataBlob.Blob.ActiveSkills["Slot1"], "Slot1"}
			},
	
			["Slot2"] = {
				0.4, --sscale
				2.5, --xscale
				-0.5, --yscale
				SkillCmd,
				nil,
				nil,
				{DataBlob.Blob.ActiveSkills["Slot2"], "Slot2"}
			},

			["Slot3"] = {
				0.4, --sscale
				2.2, --xscale
				0, --yscale
				SkillCmd,
				nil,
				nil,
				{DataBlob.Blob.ActiveSkills["Slot3"], "Slot3"}
			}
		}
		if UserInputService.TouchEnabled and self.Controllers.HUD.UI then
			for i, v in pairs(t) do
				print(DataBlob.Blob.ActiveSkills[i])
				local c = self.Controllers.HUD.UI.SkillsContainer:FindFirstChild(i)
				if DataBlob.Blob.ActiveSkills[i] ~= "" and DataBlob.Blob.ActiveSkills[i] ~= "`" then
					--create a button at start, connect to update to check if slots are existing later on and stuff
					local m = self.Modules.MobileModule:Create(table.unpack(t[i]))
					if m then
						c.Size = m.Size
						c.Position = m.Position
						c.AnchorPoint = m.AnchorPoint
						c.Visible = true
						table.insert(buttons, m)
					else
						c.Visible = false
					end
				else
					c.Visible = false
				end
			end
		end
	end

	CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		self.Maid:DoCleaning()
		wait(0.5)
		LoadAnimations(Character)

		self.Maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
			if self.Controllers.GlobalInputController.TextBoxFocused then return end
			if input.KeyCode == skillCode1 then
				SkillCmd(DataBlob.Blob.ActiveSkills["Slot1"], "Slot1")
			elseif input.KeyCode == skillCode2 then
				SkillCmd(DataBlob.Blob.ActiveSkills["Slot2"], "Slot2")
			elseif input.KeyCode == skillCode3 then
				SkillCmd(DataBlob.Blob.ActiveSkills["Slot3"], "Slot3")
			end
		end))

		
		local CooldownDisplay = self.Controllers.HUD.UI:WaitForChild("SkillsContainer")
		for i, v in ipairs(CooldownDisplay:GetChildren()) do
			if string.sub(v.Name, 1, 4) == "Slot" then
				v.Overlay.Size = UDim2.new(1, 0, 0, 0)
				v.Label.Text = Controls[tonumber(string.sub(v.Name, 5,5))]
			end
		end

		CreateButtons()
	end)

	CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function(Character)
		self.CanCancel = true
		self.ActiveSkill = false
		self.KFMaid:DoCleaning()
		if self.Controllers.StateController.CharacterState.can("cast_end") then
			self.Controllers.StateController.CharacterState.cast_end()
		end
	end)

	self.Services.PlayerService.UpdateBlob:Connect(function(newblob)
		if self.Controllers.Character.Character then
			LoadAnimations(self.Controllers.Character.Character)
			CreateButtons()
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		--update cooldowns
		for i, v in pairs(self.Cooldowns) do
			self.Cooldowns[i] = v-dt
		end
	end)
end


function SkillsController:Init()
	self.ActiveSkill = false
	self.Cooldowns = {}

	AnimationLibrary 	= self.Shared.Cache:Get("AnimationLibrary")
	AnimationPlayer 	= self.Shared.AnimationPlayer
	Boxcast 			= self.Shared.Boxcast
	SkillCache 			= self.Shared.Cache:Get("SkillCache")
	Maid 				= self.Shared.Maid
	TableUtil			= self.Shared.TableUtil
	GlobalMath 			= self.Shared.GlobalMath
	FastSpawn 			= self.Shared.FastSpawn
	self.Maid = Maid.new()

	

	TaskScheduler 		= self.Controllers.TaskScheduler
	TargetingController = self.Controllers.Targeting
	DataBlob 			= self.Controllers.DataBlob
	CharacterController = self.Controllers.Character
end


return SkillsController