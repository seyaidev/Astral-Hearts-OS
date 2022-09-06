-- ServerMob
-- oniich_n
-- January 19, 2019

--[[

	local mob = ServerMob.new()

	ServerMob:Update(UpdateDelta)

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerMob = {}
ServerMob.__index = ServerMob


function ServerMob.new(RegionData)
	local Model = ReplicatedStorage.Assets:FindFirstChild(RegionData._ServerMobType)
	assert(Model ~= nil, "Can't find mob model")

	local self = setmetatable({
		RegionData = RegionData
	}, ServerMob)

	return self
end

function ServerMob:Update(UpdateDelta)
end


return ServerMob