local Maid = require(game:GetService("ReplicatedStorage").Aero.Shared.Maid)
local TweenService = game:GetService("TweenService")
local SlideButton = {}

function SlideButton:Create(frameObject)
    local Button = frameObject:WaitForChild("Button")
    local Inactive = frameObject:WaitForChild("Inactive")
    local Active = frameObject:WaitForChild("Active")
    local Text = frameObject:WaitForChild("Title")
    local Subtext = frameObject:FindFirstChild("Subtext")
    
    local OGtt = Text.TextTransparency
    
    local OGstt
    if Subtext then
        OGstt = Text.TextTransparency
    end

    local NewMaid = Maid.new()
    NewMaid:GiveTask(
        Button.MouseEnter:Connect(function()
            -- print('entered', frameObject.Name)
            Active:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.2, true)
            Inactive:TweenSize(UDim2.new(0, 0, 1, 0), "Out", "Quad", 0.2, true)
            TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 242, 198), TextTransparency = 0}):Play()
            if Subtext then
                TweenService:Create(Subtext, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 242, 198), TextTransparency = 0}):Play()
            end
        end)
    )

    NewMaid:GiveTask(
        Button.MouseLeave:Connect(function()
            Inactive:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.2, true)
            Active:TweenSize(UDim2.new(0, 0, 1, 0), "Out", "Quad", 0.2, true)
            TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(53, 51, 45), TextTransparency = OGtt}):Play()
            if Subtext then
                TweenService:Create(Subtext, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(53, 51, 45), TextTransparency = OGstt}):Play()
            end
        end)
    )

    return NewMaid
end

function SlideButton:Clear(frameObject)
    local Button = frameObject:WaitForChild("Button")
    local Inactive = frameObject:WaitForChild("Inactive")
    local Active = frameObject:WaitForChild("Active")
    local Text = frameObject:WaitForChild("Title")

    Inactive:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.2, true)
    Active:TweenSize(UDim2.new(0, 0, 1, 0), "Out", "Quad", 0.2, true)
    TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(53, 51, 45)}):Play()
end

return SlideButton