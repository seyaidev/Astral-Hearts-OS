local Maid = require(game:GetService("ReplicatedStorage").Aero.Shared.Maid)
local TweenService = game:GetService("TweenService")
local Buttonify = {}

local colors = {}
local sizes = {}

function Buttonify:Create(frameObject)
    local Button = frameObject:WaitForChild("Button")
    local Image = frameObject:WaitForChild("Background")
    local Text = frameObject:WaitForChild("Title")

    local OGcolor = colors[frameObject] or Image.ImageColor3
    local OGsize = sizes[frameObject] or Image.Size

    colors[frameObject] = Image.ImageColor3
    sizes[frameObject] = Image.Size

    local NewMaid = Maid.new()
    NewMaid:GiveTask(
        Button.MouseEnter:Connect(function()
            -- print('entered', frameObject.Name)
            Image:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.2, true)
            TweenService:Create(Image, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 242, 198)}):Play()
            TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(53, 51, 45)}):Play()
        end)
    )

    NewMaid:GiveTask(
        Button.MouseLeave:Connect(function()
            Image:TweenSize(OGsize, "Out", "Quad", 0.2, true)
            TweenService:Create(Image, TweenInfo.new(0.2), {ImageColor3 = OGcolor}):Play()
            TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 242, 198)}):Play()
        end)
    )

    return NewMaid
end

function Buttonify:Clear(frameObject)
    local Button = frameObject:WaitForChild("Button")
    local Image = frameObject:WaitForChild("Background")
    local Text = frameObject:WaitForChild("Title")

    local OGcolor = colors[frameObject] or Image.ImageColor3
    local OGsize = sizes[frameObject] or Image.Size


    Image:TweenSize(OGsize, "Out", "Quad", 0.2, true)
    TweenService:Create(Image, TweenInfo.new(0.2), {ImageColor3 = OGcolor}):Play()
    TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 242, 198)}):Play()
end

return Buttonify