-- Mobile Module
-- Username
-- December 18, 2019

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobileModule = {}

function MobileModule:Create(sscale, xscale, yscale, callback, anchor, override, params, name)
    local Player = game.Players.LocalPlayer
    if UserInputService.TouchEnabled then
		local TouchGui = Player.PlayerGui:WaitForChild("TouchGui", 5)
		if not TouchGui then return end
        local TCF = TouchGui:WaitForChild("TouchControlFrame")
        local JumpButton = TCF:WaitForChild("JumpButton", 3)
        if TouchGui and JumpButton then
            local BaseSize = JumpButton.Size.X.Offset
            local BasePosition = JumpButton.Position
            local BaseButton = ReplicatedStorage.Assets.Interface:FindFirstChild("TouchButton")
            
			local TouchButton = BaseButton:Clone()
			-- TouchButton.Name = "TouchButton"
            TouchButton.Size = UDim2.new(
                0, BaseSize*sscale, 0, BaseSize*sscale
            )

            if not override then
                TouchButton.Position = UDim2.new(
                    1, -(BaseSize*sscale+(BaseSize*xscale)), BasePosition.Y.Scale, BasePosition.Y.Offset-(BaseSize*yscale)
                )
            else
                TouchButton.Position = override
            end

            TouchButton.Activated:Connect(function()
                if params then
                    callback(table.unpack(params))
                else
                    callback()
                end
            end)

            if anchor then TouchButton.AnchorPoint = anchor end

            if name then
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, 0, 1, 0)
                nameLabel.Text = name
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextScaled = true
                nameLabel.Active = false
                nameLabel.Font = Enum.Font.GothamSemibold
                nameLabel.TextColor3 = Color3.fromRGB(231, 227, 202)
                nameLabel.Parent = TouchButton
            end

            TouchButton.Parent = JumpButton.Parent
            return TouchButton
        end
    end

    return false
end

return MobileModule