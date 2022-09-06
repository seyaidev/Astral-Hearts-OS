local Camera = {}

local Player = game.Players.LocalPlayer
local CameraObject
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Mouse
local Keyboard
function Camera:Start()
	self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		self.PlayerCamera = CameraObject:new(Character, self)
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end)

	self.Controllers.Character:ConnectEvent("CHARACTER_DIED_EVENT", function()
		self.PlayerCamera:Dismantle()
		self.PlayerCamera = nil
	end)

	UserInputService.InputChanged:Connect(function(input)
		if self.Controllers.Interface.ActiveFull then return end
		if self.PlayerCamera then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.MouseWheel or input.UserInputType == Enum.UserInputType.Touch then
				self.PlayerCamera:MouseUpdate({
					Position = input.Position,
					Delta = input.Delta,
					Type = input.UserInputType
				})
			end
		end
	end)

	

	local MenuLockEvent = Instance.new("BindableEvent")
	MenuLockEvent.Name = "MenuLock"
	MenuLockEvent.Parent = game.Players.LocalPlayer
	MenuLockEvent.Event:Connect(function(state)
		self.PlayerCamera._MenuLock:Fire(state)
	end)

	local Sdown = false

	UserInputService.InputBegan:Connect(function(input)
		local keyCode = input.KeyCode
		if self.PlayerCamera == nil then return end
		if keyCode == Enum.KeyCode.LeftAlt or keyCode == Enum.KeyCode.LeftControl then
			self.PlayerCamera._MenuLock:Fire(not self.PlayerCamera._MouseLock)
		elseif keyCode == Enum.KeyCode.S and not Sdown then
			Sdown = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.S and Sdown then
			Sdown = false
		end
	end)
	RunService:BindToRenderStep("On Camera", Enum.RenderPriority.Camera.Value - 1, function(delta)
	-- RunService.RenderStepped:Connect(function(delta)
		if self.PlayerCamera == nil then return end
		if workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end

		if Sdown then
			self.PlayerCamera._deltaTick = 1.2
		end

		if self.PlayerCamera then
			self.PlayerCamera:update(delta)
		end
		-- print(workspace.CurrentCamera.Focus)
	end)
end

function Camera:Init()
	CameraObject = self.Modules.CameraObject
	Mouse = self.Controllers.UserInput:Get("Mouse")
	Keyboard = self.Controllers.UserInput:Get("Keyboard")
end

return Camera