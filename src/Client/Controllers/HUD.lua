-- HUD
-- oniich_n
-- February 10, 2019

--[[


--]]
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = ReplicatedStorage.Assets.Interface:WaitForChild("HUD")
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HUD = {}
HUD.__aeroOrder = 10

function HUD:Connect(Humanoid)
	if self.UI == nil then return end

	local PlayerContainer = self.UI.PlayerContainer
	PlayerContainer.Health.HealthDisplay.Size = UDim2.new(
		Humanoid.Health/Humanoid.MaxHealth, 0, 1, 0
	)

	self.Maid:GiveTask(
		Humanoid.HealthChanged:Connect(function()
			PlayerContainer.Health.HealthDisplay.Size = UDim2.new(
			 	Humanoid.Health/Humanoid.MaxHealth, 0, 1, 0
			)
			delay(0.5, function()
				PlayerContainer.Health.HealthDelay:TweenSize(
					UDim2.new(
				 		Humanoid.Health/Humanoid.MaxHealth, 0, 1, 0
					), "Out", "Quint", 0.7, true
				)
			end)
		end)
	)

	self.Maid:GiveTask(
		self.Services.PlayerService.UpdateBlob:Connect(function(Blob)
			self.UI.PlayerContainer:FindFirstChild("LevelDisplay", true).Text = "Level: " .. tostring(Blob.Stats.Level)
			self.UI.PlayerContainer:FindFirstChild("EXPText", true).Text = "EXP: " .. tostring(Blob.Stats.EXP)
			self.UI.PlayerContainer:FindFirstChild("EXPBar", true).Size = UDim2.new(Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level], 0, 1, 0)
		end)
	)

	local isIdle = true
	self.Maid:GiveTask(
		Humanoid.Running:Connect(function(speed)
			isIdle = speed < 1
		end)
	)

	local idleTime = 0
	local menuPrompt = false
	self.Maid:GiveTask(
		RunService.Heartbeat:Connect(function(dt)
			if isIdle then
				idleTime = idleTime + dt
				if idleTime > 1 and not menuPrompt then
					menuPrompt = true
					TweenService:Create(self.UI.MenuButton, TweenInfo.new(0.5), {
						TextTransparency = 0,
						TextStrokeTransparency = 0.5,
						Position = UDim2.new(0.5, 0, 1, 0)
					}):Play()				
				end
			else
				idleTime = 0
				menuPrompt = false
				TweenService:Create(self.UI.MenuButton, TweenInfo.new(0.5), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
					Position = UDim2.new(0.5, 0, 1.1, 0)
				}):Play()
			end
		end)
	)
	
end

function HUD:DisplayQuest(QuestId)
	if self.UI.Parent ~= game.Players.LocalPlayer.PlayerGui then return end
	local QuestData = self.Controllers.QuestController.QuestBlob
	print('oh snap, new quest?')
	if QuestData == nil then print("couldnt find questdata") return end

	--play quest received effect		
	-- print(QuestData)
	local QuestObject = QuestData.InProgress[QuestId]
	-- print(repr(QuestObject))
	local qHUD = ReplicatedStorage.Assets.Interface.qHUDTemplate:Clone()
	qHUD.Title.Text = QuestObject.DisplayName
	local index = 1
	for ObjectiveType, ObjectiveTable in pairs(QuestObject.Objectives) do
		for Target, Objective in pairs(ObjectiveTable) do

			local pattern = "%u+%l*"
			local NewName = ""
			for v in Target:gmatch(pattern) do
				NewName = NewName .. v .. " "
			end
			if string.len(NewName) > 1 then
				NewName = string.sub(NewName, 1, string.len(NewName)-1)
			end

			if ObjectiveType == "KILL" or ObjectiveType == "GATHER" then
				qHUD.ObjectiveList:FindFirstChild(tostring(index)).Text = "- " .. ObjectiveType .. " " .. tostring(Objective) .. " " .. NewName .. (Objective > 1 and "s." or ".") .. " (" .. tostring(QuestObject.Progress[ObjectiveType][Target]) .. "/" .. tostring(Objective) .. ")"
			elseif ObjectiveType == "TALK" then
				qHUD.ObjectiveList:FindFirstChild(tostring(index)).Text = "- TALK to " .. NewName 
			end
			index = index+1
		end
	end

	qHUD.Name = QuestId
	qHUD.Parent = self.UI:FindFirstChild("QuestList", true)
end

function HUD:Start()
	-- self.UI = UI:Clone()
	-- self.UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	-- self:Connect(self.Controllers.Character.Character:WaitForChild("Humanoid"))

	-- QuestService.NewQuest:Connect(function(QuestId)
	-- 	wait()
	-- 	self:DisplayQuest(QuestId)
	-- end)

	self.Controllers.QuestController:ConnectEvent("UpdateQuest", function(QuestId)
		local QuestData = self.Controllers.QuestController.QuestBlob
		print('oh snap, new quest?')
		if QuestData == nil then print("couldnt find questdata") return end

		--play quest received effect		
		-- print(QuestData)
		local QuestObject = QuestData.InProgress[QuestId]
		local QuestList = self.UI:FindFirstChild("QuestList", true)
		if QuestList == nil then return end
		if QuestList:FindFirstChild(QuestId) == nil then return end
		local qHUD = QuestList:FindFirstChild(QuestId)

		if QuestObject == nil then
			--completed quest/quest removed from in progress
			qHUD:Destroy()
			return
		end

		local index = 1
		for ObjectiveType, ObjectiveTable in pairs(QuestObject.Objectives) do
			for Target, Objective in pairs(ObjectiveTable) do

				local pattern = "%u+%l*"
				local NewName = ""
				for v in Target:gmatch(pattern) do
					NewName = NewName .. v .. " "
				end
				if string.len(NewName) > 1 then
					NewName = string.sub(NewName, 1, string.len(NewName)-1)
				end

				if ObjectiveType == "KILL" or ObjectiveType == "GATHER" then
					qHUD.ObjectiveList:FindFirstChild(tostring(index)).Text = "- " .. ObjectiveType .. " " .. tostring(Objective) .. " " .. NewName .. (Objective > 1 and "s." or ".") .. " (" .. tostring(QuestObject.Progress[ObjectiveType][Target]) .. "/" .. tostring(Objective) .. ")"
				elseif ObjectiveType == "TALK" then
					if not QuestObject.Progress[ObjectiveType][Target] then
						qHUD.ObjectiveList:FindFirstChild(tostring(index)).Text = "- TALK to " .. NewName
					end
				end

				if Objective == QuestObject.Progress[ObjectiveType][Target] then
					print("finished objective")
				end
				index = index+1
			end
		end
	end)

	self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		

		local Blob = DataBlob.Blob
		local PlayerGui = self.Player:WaitForChild("PlayerGui", 5)
		if not PlayerGui then PlayerGui = self.Player:WaitForChild("PlayerGui", 3) end
		if PlayerGui:FindFirstChild("LoadingFrame") then
			print("Loaded HUD, now starting...")
			delay(2, function()
				self:FireEvent("RemoveLoading")
			end)
			-- local j = PlayerGui:FindFirstChild("LoadingScreen")
			-- for i, v in ipairs(j:GetDescendants()) do
			-- 	if v:IsA("Frame") then
			-- 		TweenService:Create(v, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
			-- 	elseif v:IsA("ImageLabel") then
			-- 		TweenService:Create(v, TweenInfo.new(1), {ImageTransparency = 1}):Play()
			-- 	elseif v:IsA("TextLabel") then
			-- 		TweenService:Create(v, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			-- 	end
			-- end
			-- wait(1.1)
			-- j:Destroy()
		end

		self.UI = UI:Clone()
		self.UI.Parent = PlayerGui
		self:Connect(Character:WaitForChild("Humanoid"))

		self.UI:WaitForChild("MenuButton", 3).Activated:Connect(function()
			self.Controllers.Interface:FireEvent("HUDButton")
		end)

		--Connect level display
		self.UI.PlayerContainer:FindFirstChild("LevelDisplay", true).Text = "Level: " .. tostring(Blob.Stats.Level)
		self.UI.PlayerContainer:FindFirstChild("EXPText", true).Text = "EXP: " .. tostring(Blob.Stats.EXP)
		self.UI.PlayerContainer:FindFirstChild("EXPBar", true).Size = UDim2.new(Blob.Stats.EXP/GlobalData.Levels[Blob.Stats.Level], 0, 1, 0)

		--Setup quests
		for QuestId, QuestData in pairs(self.Controllers.QuestController.QuestBlob.InProgress) do
			self:DisplayQuest(QuestId)
		end

		if UserInputService.TouchEnabled then
			--delete the list layout in skills container to move freely
			local SkillsContainer = self.UI.SkillsContainer
			SkillsContainer:WaitForChild("UIGridLayout"):Destroy()
			SkillsContainer.Size = UDim2.new(1, 0, 1, 0)
			SkillsContainer.AnchorPoint = Vector2.new(0, 0)
			SkillsContainer.Position = UDim2.new(0, 0, 0, 0)
		end

		Character:WaitForChild("Humanoid").Died:Connect(function()
			self.Maid:DoCleaning()
		end)
	end)
end


function HUD:Init()
	self:RegisterEvent("RemoveLoading")
	self.Maid = self.Shared.Maid.new()
	
	repr = self.Shared.repr

	DataBlob = self.Controllers.DataBlob
	GlobalData = self.Shared.GlobalData
	QuestService = self.Services.QuestService
	PlayerService = self.Services.PlayerService
end

return HUD