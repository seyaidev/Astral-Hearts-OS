-- Client Mob
-- oniich_n
-- January 28, 2019

--[[

	local clientMob = ClientMob.new()

	ClientMob:Damage()
	ClientMob:update()

--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TableUtil = require(ReplicatedStorage:FindFirstChild("TableUtil", true))
local FSM = require(ReplicatedStorage:FindFirstChild("FSM", true))
local AnimationPlayer = require(ReplicatedStorage:FindFirstChild("AnimationPlayer", true))
local SharedCache = require(ReplicatedStorage:FindFirstChild("Cache", true))

local ClientMob = {}
ClientMob.__index = ClientMob

function ClientMob.new(FullData, CSGId)
	local ClientData = TableUtil.Copy(FullData)
	ClientData.Player = game.Players.LocalPlayer
	ClientData.LastAttack = 0


	ClientData.Animations = AnimationPlayer.new(ClientData.Model:FindFirstChild("Humanoid"))
	
	local AnimationSet = SharedCache:Get("AnimationLibrary")["Mob"][FullData.RegionData.MobType]
	for name, id in pairs(AnimationSet) do
		ClientData.Animations:AddAnimation(name, id)
	end

	local self = setmetatable(ClientData, ClientMob)
	
	return self
end

function ClientMob:Damage(amt, element)
	--reduce health and all that good stuff here!
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
end

function ClientMob:Die()
	-- print("ohp")
	-- local Particles = ReplicatedStorage:FindFirstChild("DeathCore", true):Clone()
	-- Particles.Parent = workspace.Trash
	-- Particles.Size = self.Model:GetExtentsSize()
	-- Particles.Position = self.Model:GetPrimaryPartCFrame().p

	-- game:GetService("Debris"):AddItem(Particles, 4)
	-- for i, v in pairs(Particles:GetChildren()) do
	-- 	v.Enabled = true
	-- 	delay(0.25, function()
	-- 		v.Enabled = false
	-- 	end)
	-- end


	-- self.Model:Destroy()
	-- for i, v in pairs(self) do
	-- 	self[i] = nil
	-- end
end

function ClientMob:update(dt)
	--run through behavior tree
	self.LastAttack = self.LastAttack+dt
		--play animations through btree

	local cdmp = self.Model:GetPrimaryPartCFrame().p
	local ccpp = self.Player.Character:GetPrimaryPartCFrame().p
	self.TargetGyro.CFrame = CFrame.new(
		cdmp,
		Vector3.new(ccpp.X, cdmp.Y, ccpp.Z)
	)
end


--behavior tree actions


return ClientMob