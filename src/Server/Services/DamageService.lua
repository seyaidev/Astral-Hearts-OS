-- Damage Service
-- oniich_n
-- January 19, 2019

--[[

	Server:

		DamageService:CollectDamage()
		DamageService:CalculateMax()

		DamageService.PlayerDamage()


	Client:



--]]



local DamageService = {Client = {}}
local PlayerService

function DamageService:ClearMob(MobId)
	for i, v in pairs(self.Info) do
		self.Info[i][MobId] = nil
	end
end

local cutoffTime = 0
local lastT = {}
function DamageService:CollectDamage(Player, Damage, t, MobId, Skill)
	t = tick()
	local ThisPlayer = self.Info[Player.UserId]

	if ThisPlayer == nil then
		self.Info[Player.UserId] = {
			MaxDPS = 0;
			CanDamage = true;
			Skills = {};
		}
		ThisPlayer = self.Info[Player.UserId]
	end

	if ThisPlayer[MobId] == nil then
		ThisPlayer[MobId] = {
			CollectedDamage = 0;
			CollectedTime = 0;
			LastTick = 0;
		}
	end

	if Skill then
		if ThisPlayer.Skills[Skill.LocalInfo.SkillId] then
			print("on cooldown")
			return
		else
			delay(2, function() -- change this to get cast time eventually
				self.Info[Player.UserId].Skills[Skill.LocalInfo.SkillId] = true
				delay(Skill.Stats.Cooldown, function()
					self.Info[Player.UserId].Skills[Skill.LocalInfo.SkillId] = false
				end)
			end)
		end
	end

	local l_tick = ThisPlayer[MobId].LastTick or 0

	local ThisTime = t-l_tick

	local function IncrementTriggers()
		self.Trigger[Player.UserId] = self.Trigger[Player.UserId]+1
		if self.Trigger[Player.UserId] > 25 then
			print("Player kicked for potential damage exploiting...")
			Player:Kick("Fell out of sync: SayoError 303")
		end
	end

	ThisPlayer[MobId].CollectedDamage = ThisPlayer[MobId].CollectedDamage+Damage
	ThisPlayer[MobId].CollectedTime = ThisPlayer[MobId].CollectedTime+ThisTime
	ThisPlayer[MobId].LastTick = t

	ThisPlayer[MobId].CurrentDPS = ThisPlayer[MobId].CollectedDamage/ThisPlayer[MobId].CollectedTime

	local timehold = 0.3
	if Skill then
		timehold = 0.1
	end

	if ThisTime < timehold then
		print("attack speed too high")
		IncrementTriggers()
		return false 
	end

	if ThisPlayer[MobId].CurrentDPS > ThisPlayer.MaxDPS then
		print("dps too high")
		IncrementTriggers()
		return false
	end
	return true
end

function DamageService:CalculateMax(Player)
	--calculate max damage if all spells were cast back to back + full combo
		--get time to deal all this damage
		--divide total damage by this time; dps

	--get player data
		--use data to get all possible attacks
		--combine total length of all attack animations played in succession
		--combine total damage
		--divide damage by time
		--increase by 10% for buffer
	if Player == nil or Player.UserId == nil then return end
	local ThisPlayer = self.Info[Player.UserId]

	local PlayerData = PlayerService:GetPlayerData(Player)
	if PlayerData == nil then return end

	local Character = PlayerService:GetCharacter(Player)
	if Character == nil then return end
	local AttackAnimations = {}

	--get basic combo
	local ItemData = self.Shared.Cache:Get("")

	local EquippedPrimary = PlayerData.Inventory[PlayerData.Equipment.PrimaryWeapon]
	local Combo = self.Shared.Cache:Get("AnimationLibrary")["Weapon"][EquippedPrimary.Subclass].Default

	local ap = AnimationPlayer.new(workspace:WaitForChild("AnimationLoad").AnimationController)
	for i, v in pairs(Combo) do
		ap:AddAnimation(i, v)
	end

	local TotalLength = 0
	local TotalDamage = 0

	for i, v in pairs(ap:GetTracks()) do
		TotalLength = TotalLength+v.Length

		local Multiplier = 1

		for i = 1, 10 do
			local success, t = pcall(function()
				v:GetTimeOfKeyframe("MultiHit" .. tostring(i))
			end)
			if success then
				Multiplier = i
			end
		end

		-- print("Multiplier", Multiplier)
		TotalDamage = TotalDamage+(self.Shared.FormulasModule:HitDamage(PlayerData)*Multiplier)
	end

	--get skills
		--add animations to ap

	local ActiveSkills = PlayerData.ActiveSkills
	for Slot, SkillId in pairs(ActiveSkills) do
		local SkillInfo = SkillCache:Get(SkillId)
		if SkillInfo then
			local Anim = self.Shared.Cache:Get("AnimationLibrary")["Skill"][SkillId]
			local track = ap:AddAnimation(SkillId, Anim)

			TotalLength = track.Length*0.7
			TotalDamage = TotalDamage+(self.Shared.FormulasModule:HitDamage(PlayerData, SkillInfo)*SkillInfo.LocalInfo.hits)
		end
	end

	ThisPlayer.MaxDPS = (TotalDamage/TotalLength)*1.3
	-- print("MaxDPS:", ThisPlayer.MaxDPS)
	ap:ClearAllTracks()
	ap:Destroy()
end


function DamageService:Start()
	self:ConnectEvent("PlayerDamage", function(Player, Damage)
		self:CollectDamage(Player, Damage)
	end)
	
	self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(player)
		self.Info[player.UserId] = {
			MaxDPS = 0;
			CanDamage = true;
			Skills = {};
		}

		self.Trigger[player.UserId] = 0
	end)


	while true do
		for i, v in pairs(self.Info) do
			for j, k in pairs(v) do
				if typeof(k) == "table" then
					k.CollectedDamage = 0
					k.CollectedTime = 0
					k.CurrentDPS = 0
				end
			end
		
			self:CalculateMax(game.Players:GetPlayerByUserId(i))
			for i, v in pairs(self.Trigger) do
				self.Trigger[i] = math.clamp(self.Trigger[i]-1, 0, 100)
			end
		end
		wait(2)
	end
end


function DamageService:Init()
	self.Info = {}
	self.Trigger = {}
	PlayerService = self.Services.PlayerService
	AnimationPlayer = self.Shared.AnimationPlayer
	FormulasModule = self.Shared.FormulasModule
	SkillCache = self.Shared.Cache:Get("SkillCache")

	self:RegisterEvent("Cast")
	self:RegisterEvent("PlayerDamage")
	
end


return DamageService