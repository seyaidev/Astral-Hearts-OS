-- DataMob
-- oniich_n
-- January 28, 2019

--[[

	local dataMob = DataMob.new()


--]]

local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local TableUtil = require(ReplicatedStorage:FindFirstChild("TableUtil", true))
local FSM = require(ReplicatedStorage:FindFirstChild("FSM", true))
local AnimationPlayer = require(ReplicatedStorage:FindFirstChild("AnimationPlayer", true))
local SharedCache = require(ReplicatedStorage:FindFirstChild("Cache", true))

local PhysicsService = game:GetService("PhysicsService")

local DataMob = {}
DataMob.__index = DataMob

function DataMob.new(NewData)

	--[[
		NewData {
			RegionData {
				MobType
				MinPos
				MaxPos
				Height
			}
			MobData {
				MaxHealth = int;
				Attack = int;
				Defense = int;

				Weakness = {};
				Affinity = {};
			}
		}

	]]
	local nmData = TableUtil.Copy(NewData.MobData)
	local nrData = TableUtil.Copy(NewData.RegionData)

	local FullData = {
		Target = nil;
		Id = HttpService:GenerateGUID();
		MobData = nmData;
		RegionData = nrData;

		Health = nmData.MaxHealth;
		AggroScores = {};
		LastAttack = 0;

		Active = false;
		Dead = false;

		Moving = false;
		PointIndex = 0;
	}

	FullData.LastAttack = 0

	local BaseModel = ReplicatedStorage:FindFirstChild(FullData.RegionData.MobType .. "_Model", true)
	assert(BaseModel ~= nil, "Could not find Base Model: " .. tostring(FullData.RegionData.MobType))
	FullData.Model = BaseModel:Clone()
	FullData.Model.Parent = workspace.Mobs

	FullData.Animations = AnimationPlayer.new(FullData.Model:FindFirstChild("Humanoid"))

	local AnimationSet = SharedCache:Get("AnimationLibrary")["Mob"][FullData.RegionData.MobType]
	for name, id in pairs(AnimationSet) do
		FullData.Animations:AddAnimation(name, id)
	end

	FullData.Model:SetPrimaryPartCFrame(
		CFrame.new(
			math.random(FullData.RegionData.MinPos.X, FullData.RegionData.MaxPos.X),
			FullData.RegionData.Height+2,
			math.random(FullData.RegionData.MinPos.Z, FullData.RegionData.MaxPos.Z)
		)
	)

	local MobHUD = ReplicatedStorage:FindFirstChild("MobHUD", true):Clone()
	MobHUD.Parent = FullData.Model
	MobHUD.Adornee = FullData.Model.PrimaryPart

	local pattern = "%u+%l*"
	local NewName = ""
	for v in FullData.RegionData.MobType:gmatch(pattern) do
		NewName = NewName .. v .. " "
	end
	if string.len(NewName) > 1 then
		NewName = string.sub(NewName, 1, string.len(NewName)-1)
	end

	MobHUD:FindFirstChild("Name", true).Text = NewName
	MobHUD:FindFirstChild("HealthBar", true).Size = UDim2.new(1, 0, 1, 0)

	FullData.HUD = MobHUD

	FullData.Model.Humanoid.WalkSpeed = 8
	FullData.Speed = FullData.Model.Humanoid.WalkSpeed

	FullData.TargetGyro = Instance.new("BodyGyro")
	FullData.TargetGyro.Name = "TargetGyro"
	FullData.TargetGyro.MaxTorque = Vector3.new(0, 900000, 0)
	FullData.TargetGyro.D = 10
	FullData.TargetGyro.P = 300

	-- local cdmp = FullData.Model:GetPrimaryPartCFrame().p
	-- local ccpp = FullData.Player.Character:GetPrimaryPartCFrame().p
	-- FullData.TargetGyro.CFrame = CFrame.new(
	-- 	cdmp,
	-- 	Vector3.new(ccpp.X, cdmp.Y, ccpp.Z)
	-- )
	FullData.TargetGyro.Parent = FullData.Model.PrimaryPart

	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	FullData.Model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)


	--load boxcast attack times for the mob
	FullData.AttackFrames = {}
	local AttackTrack = FullData.Animations:GetTrack("Attack")
	for i = 1, 10 do
		local success, message = pcall(function()
			local t = AttackTrack:GetTimeOfKeyframe("Cast" .. tostring(i))
		end)
		print(i, success)
		if success then
			local ATime = AttackTrack:GetTimeOfKeyframe("Cast" .. tostring(i))
			table.insert(FullData.AttackFrames, "Cast" .. tostring(i))
		else
			-- print(message)
			break
		end
	end

	--Connect(attack stuff)
	AttackTrack.KeyframeReached:Connect(function(kf)
		print(kf)
		if TableUtil.IndexOf(FullData.AttackFrames, kf) ~= nil then
			print("Attack here!")
		end
	end)

	-- print(FullData.Id)
	for i, v in pairs(FullData.Model:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name == "Hitbox" then
				CollectionService:AddTag(v, "Targetable")
			else
				PhysicsService:SetPartCollisionGroup(v, "Mobs")
			end
			-- v.CollisionGroupId = PhysicsService:GetCollisionGroupId("Mobs")

			CollectionService:AddTag(v, "mobid:" .. tostring(FullData.Id))

			--save color
			local BaseColor = Instance.new("Color3Value")
			BaseColor.Value = v.Color
			BaseColor.Name = "BaseColor"

			BaseColor.Parent = v
		end
	end

	FullData.Model.PrimaryPart.Anchored = false

	FullData.State = FSM.create({
		initial = "safe",
		events = {
			{ name = "endanger", from = "safe", to = "danger" },
			{ name = "recover", from = "danger", to = "safe"}

		}
	})

	local self = setmetatable(FullData, DataMob)

	return self
end

function DataMob:Damage(player, amt, element)
	local Multiplier = 1
	if self.MobData.Defense >= 0 then
		Multiplier = 100/(100+self.MobData.Defense)
	else
		Multiplier = 2 - (100/(100-self.MobData.Defense))
	end

	if element ~= nil then
		for i, v in pairs(self.MobData.Weakness) do
			if v == element then
				Multiplier = Multiplier+0.2
				break
			end
		end

		for i, v in pairs(self.MobData.Affinity) do
			if v == element then
				Multiplier = Multiplier-0.2
			end
		end
	end

	local NewDamage = math.floor(amt*Multiplier)
	self.Health = self.Health-NewDamage
	-- print(self.Id, self.Health)
	--add to aggroscore
	local AS = nil
	for i, v in pairs(self.AggroScores) do
		if v.UserId == player.UserId then
			AS = i
			v.AggroScore = v.AggroScore+amt
		end
	end

	if AS == nil then
		table.insert(self.AggroScores, {
			UserId = player.UserId;
			AggroScore = amt
		})
	end
	
	-- #Update health display
	self.HUD:FindFirstChild("HealthBar", true).Size = UDim2.new(
		self.Health/self.MobData.MaxHealth,
		0, 1, 0
	)

	delay(0.2, function()
		if self.HUD == nil then return end
		local h = self.HUD:FindFirstChild("HealthBarDelay", true)
		if h == nil then return end
		h:TweenSize(
			self.HUD:FindFirstChild("HealthBar", true).Size,
			"Out",
			"Quad",
			0.7,
			true
		)
	end)

	-- #Damage Text
	spawn(function()
		if self.Model == nil then return end
		local newpos = self.Model.PrimaryPart.Position + Vector3.new(0, 4, 0)
		--create billboard gui at position
		local Holder = Instance.new("Part")
		Holder.Size = Vector3.new(1,1,1)
		Holder.Position = newpos
		Holder.Anchored = true
		Holder.CanCollide = false
		Holder.Transparency = 1
		Holder.Parent = workspace.Trash

		local Billboard = Instance.new("BillboardGui")
		Billboard.Size = UDim2.new(1, 0, 1, 0)
		Billboard.LightInfluence = 0
		Billboard.MaxDistance = 50
		Billboard.AlwaysOnTop = true
		Billboard.Parent = Holder

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.TextScaled = true
		TextLabel.BackgroundTransparency = 1
		TextLabel.Font = Enum.Font.SourceSansBold
		TextLabel.Text = "[X +]" --tostring(amt)
		TextLabel.TextColor3 = Color3.fromRGB(240, 234, 207)
		TextLabel.TextStrokeTransparency = 0
		TextLabel.TextStrokeColor3 = Color3.fromRGB(143, 142, 134)
		TextLabel.Parent = Billboard

		TweenService:Create(Holder, TweenInfo.new(2), {Position = newpos + Vector3.new(0, 3, 0)}):Play()
		TweenService:Create(TextLabel, TweenInfo.new(2), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		Debris:AddItem(Holder, 1.5)
	end)

	-- #Redness Event
	spawn(function()
		if self.Model == nil then return end
		for i, v in pairs(self.Model:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Color = Color3.new(1, v.Color.g, v.Color.b)
				TweenService:Create(v, TweenInfo.new(0.5), {Color = v.BaseColor.Value}):Play()
			end
		end
	end)

	-- #Knockback Event
	local KBrange = 8
	local ENABLE_KNOCKBACK = true
	spawn(function()
		if self.Target == nil then return end
		local CurrentCharacter = self.Target.Character
		if CurrentCharacter == nil then return end
		if self.IsAttacking then print("can't: attackin") return end

		self.Animations:StopTrack("Stagger")
		self.Animations:PlayTrack("Stagger")
		self.KNOCKBACK = true
		--clear any exisiting effect
		local oldKBG = self.Model.PrimaryPart:FindFirstChild("KnockbackGyro", true)
		if oldKBG ~= nil then oldKBG:Destroy() end

		self.Model:FindFirstChild("Humanoid", true).WalkSpeed = 0

		local BodyGyro = Instance.new("BodyGyro")
		BodyGyro.CFrame = CFrame.new(self.Model.PrimaryPart.Position, Vector3.new(
			CurrentCharacter.PrimaryPart.Position.X,
			self.Model.PrimaryPart.Position.Y,
			CurrentCharacter.PrimaryPart.Position.Z
		))
		BodyGyro.MaxTorque = Vector3.new(0, 300000, 0)
		BodyGyro.D = 1
		BodyGyro.P = 1000
		BodyGyro.Name = "KnockbackGyro"
		BodyGyro.Parent = self.Model.PrimaryPart

		delay(0.3, function()
			if self == nil then return end
			if BodyPosition ~= nil then BodyPosition:Destroy() end
			if BodyGyro ~= nil then BodyGyro:Destroy() end
			self.KNOCKBACK = false
			delay(0.2, function()
				if self == nil then return end
				if self.Model == nil then return end
				self.Model:FindFirstChild("Humanoid", true).WalkSpeed = self.Speed
			end)
		end)
	end)


	if self.Health <= 0 then
		--fire death function, basically a retreat
		-- _G.AeroServer.Services.MobService:FireEvent("REMOVE_ACTIVE_EVENT", self.Player, self.Id)
		self.Dead = true
	end
end


function DataMob:Dismantle()
	print("dismantling: " .. self.Id)
	
	local Particles = ReplicatedStorage:FindFirstChild("DeathCore", true):Clone()
	Particles.Parent = workspace.Trash
	Particles.Size = self.Model:GetExtentsSize()
	Particles.Position = self.Model:GetPrimaryPartCFrame().p

	game:GetService("Debris"):AddItem(Particles, 4)
	for i, v in pairs(Particles:GetChildren()) do
		v.Enabled = true
		delay(0.25, function()
			v.Enabled = false
		end)
	end


	self.Model:Destroy()
	for i, v in pairs(self) do
		self[i] = nil
	end


	for i, v in pairs(self) do
		self[i] = nil
	end

	self = nil
end

function DataMob:Heal(amt)
	self.Health = math.clamp(self.Health+amt, 1, self.MobData.MaxHealth)
end

function DataMob:update(dt)
	-- print(self.Moving, self.Waypoints == self.LastPoints, "HELAA")
	-- if self.Moving and not self.KNOCKBACK then
	-- 	-- if self.Waypoints == self.LastPoints then
	-- 		--get waypoints
	-- 		--move along waypoints
			
	-- 		print(self.PointIndex)
	-- 		local ThisWaypoint = self.Waypoints[self.PointIndex]
	-- 		if ThisWaypoint.Action == Enum.PathWaypointAction.Walk then
	-- 			self.Model.Humanoid:MoveTo(ThisWaypoint.Position)
	-- 		else
	-- 			--jump bois
	-- 		end
			
	-- 		local svec = Vector3.new(
	-- 			self.Model.PrimaryPart.Position.X,
	-- 			0,
	-- 			self.Model.PrimaryPart.Position.Z
	-- 		)

	-- 		local qvec = Vector3.new(
	-- 			ThisWaypoint.Position.X,
	-- 			0,
	-- 			ThisWaypoint.Position.Z
	-- 		)

	-- 		if (svec-qvec).magnitude < 1 then
	-- 			self.PointIndex = math.clamp(self.PointIndex+1, 1, #self.Waypoints)
	-- 		end
	-- 	-- else
	-- 		-- self.PointIndex = 1
	-- 		-- self.LastPoints = self.Waypoints
	-- 	-- end
	-- else
	-- 	self.PointIndex = 1
	-- 	self.Waypoints = {}
	-- end

	--run through behavior tree
	self.LastAttack = self.LastAttack+dt
		--play animations through btree

	--Run Aggro check; steal this from AH v2
	for i, v in pairs(self.AggroScores) do
		v.AggroScore = math.clamp(v.AggroScore-dt, 0, 999)
	end

	if #self.AggroScores >= 1 then
		if #self.AggroScores > 1 then
			local function AggroSort(a, b)
				if a.AggroScore < b.AggroScore then
					return true
				else
					return false
				end
			end
			
			table.sort(self.AggroScores, AggroSort)
		end
		self.Target = game.Players:GetPlayerByUserId(self.AggroScores[1].UserId)
	end

	local cdmp = self.Model:GetPrimaryPartCFrame().p
	if self.Target ~= nil then
		local ccpp = self.Target.Character:GetPrimaryPartCFrame().p
		self.TargetGyro.CFrame = CFrame.new(
			cdmp,
			Vector3.new(ccpp.X, cdmp.Y, ccpp.Z)
		)
	end
end

return DataMob