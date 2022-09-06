--/
-- Richard's 3D Gui Core. (Written by Onogork, 2018)
--	The core script for easy custom 3D GUIs!
--/
-- Guis.
local __GUIS = {};
-- local framerate = (1/48)
local Player = game.Players.LocalPlayer
local lastupdate = 0

local Maid = require(game.ReplicatedStorage:FindFirstChild("Maid", true))
local ViewportMaid = Maid.new()
ViewportMaid:GiveTask(Player.CharacterAdded:Connect(function(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	Humanoid.Died:Connect(function()
		for i, v in pairs(__GUIS) do
			v:Destroy()
		end
	end)
end))

game:GetService("RunService").Heartbeat:Connect(function(dt)
	local framerate = 1/dt
	lastupdate = lastupdate+dt
	
	if lastupdate < 1/(framerate*0.4) then return end
	
	lastupdate = 0
	for key, frame in pairs(__GUIS) do
		if frame.Frame == nil then
			_GUIS[key] = nil;
			frame:Destroy();
		elseif (frame.Destroyed == true) then
			__GUIS[key] = nil; -- Remove from table.	
		elseif frame.ActiveUpdate then--and frame.Frame.ImageTransparency < 0.8 then
			frame:Update();
		elseif not frame.ActiveUpdate and frame.InitUpdate == false then
			frame:Update();
			frame.InitUpdate = true
			if frame.Dummy then
				frame.Dummy:Destroy()
			end
		end;
	end;
end);
-- Module ¬
local Gui3D = require(script:FindFirstChild("3DGuiMaster"));
local _GuiCore = {};
-- New frame.
function _GuiCore.new(...)
	local result = Gui3D.buildFrame(...);
	table.insert(__GUIS, result);
	return result;
end;
return _GuiCore;
--/