-- // Services \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // Variables \\ --
local Remotes = ReplicatedStorage.Remotes
local Modules = ReplicatedStorage.Modules

local Chat = require(Modules.Chat)

-- // Main \\ --
Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		ReplicatedStorage.Assets.BubbleChat.BubbleChatUI:Clone().Parent = Character.Head
	end)
end)


Remotes.Chat.OnServerEvent:Connect(function(Player, Args)
	local Character = Player.Character
	if Character == nil then return end -- // Doesn't run if character doesn't exist.
	
	if Args.Reason == "StartedTyping" then
		Chat:Typing(Player, true)
	elseif Args.Reason == "StoppedTyping" then
		Chat:Typing(Player, false)	
	elseif Args.Reason == "Chatted" then
		Chat:SendMessage(Player, Args.Message)
	end
end)

