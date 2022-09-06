-- Legacy Mob Hook
-- oniich_n
-- April 9, 2019

--[[
	
	Server:
		
	
		LegacyMobHook.MobDamage()
		LegacyMobHook.MobSpecial()
		LegacyMobHook.RemoveMob()


	Client:
		
		LegacyMobHook:GetMobGroup()
	
		LegacyMobHook.MobUpdate()
		LegacyMobHook.MobQueue()

--]]



local LegacyMobHook = {Client = {}}


local MOB_DAMAGE_EVENT = "MobDamage"
local MOB_SPECIAL_EVENT = "MobSpecial"
local REMOVE_MOB_EVENT = "RemoveMob"
local DISCONNECT_PLAYER_EVENT = "DisconnectPlayer"


local MOB_UPDATE_CLIENT_EVENT = "MobUpdate"
local MOB_QUEUE_CLIENT_EVENT = "MobQueue"
local MOB_SPECIAL_QUEUE_CLIENT_EVENT = "MobSpecialQueue"
local MOB_INTERRUPT_CLIENT_EVENT = "MobInterrupt"
local MOB_DESTROY_CLIENT_EVENT = "MobDestroy"
local MOB_ACTION_CLIENT_EVENT = "MobAction"
local MOB_EFFECT_CLIENT_EVENT = "MobEffect"
local DAMAGE_IND_CLIENT_EVENT = "ClientDamageIndicator"

local FLYBACK_CLIENT_EVENT = "Flyback"
local STAGGER_CLIENT_EVENT = "Stagger"

function LegacyMobHook.Client:GetMobGroup(player)
	return game:GetService("PhysicsService"):GetCollisionGroupId("Mobs")
end


function LegacyMobHook:Start()
	self:ConnectClientEvent(MOB_QUEUE_CLIENT_EVENT, function(player, packet)
		local PlayerData = self.Services.PlayerService:GetPlayerData(player)

		for i, info in pairs(packet) do
			local MobId = info[1]
			local t = info[2]

			-- local Damage = PlayerData[PlayerData.ClassStat] --calculate damage (add multipliers or whatever)
			self.Services.DamageService:CollectDamage(player, 25, t)

			if self.Services.DamageService.Info[player.UserId].CanDamage then
				wait()
				self:FireEvent("MobDamage", player, MobId)
			end
		end
	end)
end


function LegacyMobHook:Init()
	
	self:RegisterEvent(MOB_DAMAGE_EVENT)
	self:RegisterEvent(MOB_SPECIAL_EVENT)
	self:RegisterEvent(REMOVE_MOB_EVENT)
	self:RegisterEvent(DISCONNECT_PLAYER_EVENT)
	
	self:RegisterClientEvent(MOB_UPDATE_CLIENT_EVENT)
    self:RegisterClientEvent(MOB_QUEUE_CLIENT_EVENT)
    self:RegisterClientEvent(MOB_SPECIAL_QUEUE_CLIENT_EVENT)
	self:RegisterClientEvent(MOB_INTERRUPT_CLIENT_EVENT)
	self:RegisterClientEvent(MOB_DESTROY_CLIENT_EVENT)
	self:RegisterClientEvent(MOB_ACTION_CLIENT_EVENT)
	self:RegisterClientEvent(MOB_EFFECT_CLIENT_EVENT)
	self:RegisterClientEvent(DAMAGE_IND_CLIENT_EVENT)

	self:RegisterClientEvent(FLYBACK_CLIENT_EVENT)
	self:RegisterClientEvent(STAGGER_CLIENT_EVENT)
end


return LegacyMobHook