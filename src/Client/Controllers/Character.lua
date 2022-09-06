-- Character
-- oniich_n
-- January 27, 2019

--[[


--]]



local Character = {}
Character.__aeroOrder = 2
local CHARACTER_ADDED_EVENT = "CHARACTER_ADDED_EVENT"
local CHARACTER_DIED_EVENT = "CHARACTER_DIED_EVENT"
local JumpTweakerAPI = require(game.ReplicatedStorage:FindFirstChild("JumpTweakerAPI", true))

local TweenService = game:GetService("TweenService")
local StarterCharacterScripts = game.StarterPlayer.StarterCharacterScripts

function Character:Start()
	local Player = game.Players.LocalPlayer
	local ActiveCharacter = false

	local function LoadCharacter(Character)
		if ActiveCharacter then return end
		ActiveCharacter = true
		print("Character added")
		-- if Character ~= Player.Character then return end
		self.Character = Character
		JumpTweakerAPI:RegisterCharacter(Character)

		local Humanoid = Character:WaitForChild("Humanoid")
		Humanoid.Died:Connect(function()
			ActiveCharacter = false
			self:FireEvent(CHARACTER_DIED_EVENT)
		end)

		Humanoid.WalkSpeed = 22
		wait(0.5)
		

		self:FireEvent(CHARACTER_ADDED_EVENT, self.Character)
		self.Services.PlayerService.ControllerLoaded:Fire(true)
	end

	self.Services.PlayerService.CharacterAdded:Connect(function(Character)
		local AnimateScript = Character:WaitForChild("Animate", 3)
		if AnimateScript then AnimateScript:Destroy() end

		for i,v in pairs(Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks()) do
			v:Stop()
		end

		wait()
		LoadCharacter(Character)
		-- self.Services.WeaponService.LoadWeapons:Fire()
	end)

	FastSpawn(function()
		while wait(0.5) do
			self.Character = game.Players.LocalPlayer.Character
		end
	end)

	-- local Timeout = 0
	-- repeat
	-- 	wait(1)
	-- 	Timeout = Timeout + 1

	
	self.Services.PlayerService.ControllerLoaded:Fire()
	print("Started CharacterController")

	wait(2)
	if not ActiveCharacter then
		local Character = workspace.Characters:FindFirstChild(self.Player.Name)
		if Character then
			LoadCharacter(Character)
		end
	end
end


function Character:Init()
	self:RegisterEvent(CHARACTER_ADDED_EVENT)
	self:RegisterEvent(CHARACTER_DIED_EVENT)

	FastSpawn = self.Shared.FastSpawn
	self.Character = nil
end


return Character