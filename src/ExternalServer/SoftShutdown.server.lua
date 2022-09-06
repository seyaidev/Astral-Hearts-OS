--[[
	SoftShutdown 1.2
	Author: Merely
	
	This system lets you shut down servers without losing a bunch of players.
	When game.OnClose is called, the script teleports everyone in the server
	into a reserved server.
	
	When the reserved servers start up, they wait a few seconds, and then
	send everyone back into the main place.
	
	I added wait() in a couple of places because if you don't, everyone will spawn into
	their own servers with only 1 player.
--]]

local TargetPlaceId = 1090923299

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

if (game.VIPServerId ~= "" and game.VIPServerOwnerId == 0 and game.PlaceId ~= TargetPlaceId) then
	-- this is a reserved server without a VIP server owner
	local m = Instance.new("Message")
	m.Text = "This is a temporary lobby. Returning to the title menu in a moment."
	m.Parent = workspace
	
	local waitTime = 5

	Players.PlayerAdded:connect(function(player)
		wait(waitTime)
		waitTime = waitTime / 2
		TeleportService:Teleport(TargetPlaceId, player)
	end)
	
	for _,player in pairs(Players:GetPlayers()) do
		TeleportService:Teleport(TargetPlaceId, player)
		wait(waitTime)
		waitTime = waitTime / 2
	end
else
	game:BindToClose(function()
		if (#Players:GetPlayers() == 0) then
			return
		end
		
		if (game:GetService("RunService"):IsStudio()) then
			return
		end
		
		local m = Instance.new("Message")
		m.Text = "Rebooting servers for update. Attempting to auto-reconnect or you can manually rejoin."
		m.Parent = workspace

		local reservedServerCode = TeleportService:ReserveServer(TargetPlaceId)
		
		for _,player in pairs(Players:GetPlayers()) do
			TeleportService:TeleportToPrivateServer(TargetPlaceId, reservedServerCode, { player })
		end
		Players.PlayerAdded:connect(function(player)
			TeleportService:TeleportToPrivateServer(TargetPlaceId, reservedServerCode, { player })
		end)
	
		while (#Players:GetPlayers() > 0) do
			wait(1)
		end	
		
		-- done
	end)
end
