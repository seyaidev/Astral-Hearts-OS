-- Collision Service
-- oniich_n
-- January 28, 2019

--[[

	Server:




	Client:
		CollectionService.Client:GetGroupId(group_name)
			returns CollisionGroupId for requested group_name to be used in client replication


--]]



local CollisionService = {Client = {}}
local PhysicsService = game:GetService("PhysicsService")

function CollisionService:GetGroupId(group_name)
	return PhysicsService:GetCollisionGroupId(group_name)
end

function CollisionService.Client:GetGroupId(player, group_name)
	return PhysicsService:GetCollisionGroupId(group_name)
end

function CollisionService:Start()
	PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Characters", false)
	PhysicsService:CollisionGroupSetCollidable("Markers", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Markers", "Characters", false)

	-- PlayerService:ConnectEvent("PLAYER_CHARACTER_ADDED_EVENT", function(character)
	-- 	if character ~= nil then
	-- 		for i, v in pairs(character:GetChildren()) do
	-- 			if v:IsA("BasePart") then
	-- 				PhysicsService:SetPartCollisionGroup(v, "Characters")
	-- 				-- print("added to chars")
	-- 			end
	-- 		end
	-- 	end
	-- end)

	for _,npc in ipairs(workspace:WaitForChild("NPCs"):GetChildren()) do
		for i,v in ipairs(npc:GetChildren()) do
			if v:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(v, "Characters")
			end
		end
	end
end


function CollisionService:Init()
	PlayerService = self.Services.PlayerService

	PhysicsService:CreateCollisionGroup("Characters")
	PhysicsService:CreateCollisionGroup("Mobs")
	PhysicsService:CreateCollisionGroup("Markers")
end


return CollisionService