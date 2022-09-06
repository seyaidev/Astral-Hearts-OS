local TweenService = game:GetService("TweenService")

return function(v)
    if v:IsA("TextLabel") or v:IsA("TextButton") then
        local OriginalText = v.TextTransparency

        if v:FindFirstChild("OriginalText") == nil then
            local ot = Instance.new("NumberValue")
            ot.Name = "OriginalText"
            ot.Value = OriginalText
            ot.Parent = v
        end
        v.TextTransparency = 1

        local Tween = TweenService:Create(v, TweenInfo.new(0.6), {TextTransparency = v:FindFirstChild("OriginalText").Value})
        local t = {v.AbsolutePosition, Tween}
        return t
    elseif v:IsA("Frame") then
        local OrignalBg = v.BackgroundTransparency
        if v:FindFirstChild("OriginalBg") == nil then
            local ot = Instance.new("NumberValue")
            ot.Name = "OriginalBg"
            ot.Value = OrignalBg
            ot.Parent = v
        end
        v.BackgroundTransparency = 1

        local Tween = TweenService:Create(v, TweenInfo.new(0.6), {BackgroundTransparency = v:FindFirstChild("OriginalBg").Value})
        local t = {v.AbsolutePosition, Tween}
        return t
    elseif v:IsA("ImageLabel") or v:IsA("ImageButton") or v:IsA("ViewportFrame") then
        local OriginalImage = v.ImageTransparency
        if v:FindFirstChild("OriginalImage") == nil then
            local ot = Instance.new("NumberValue")
            ot.Name = "OriginalImage"
            ot.Value = OriginalImage
            ot.Parent = v
        end
        v.ImageTransparency = 1


        local OriginalBg = v.BackgroundTransparency
        if v:FindFirstChild("OriginalBg") == nil then
            local ot = Instance.new("NumberValue")
            ot.Name = "OriginalBg"
            ot.Value = OriginalBg
            ot.Parent = v
        end
        v.BackgroundTransparency = 1


        local Tween = TweenService:Create(v, TweenInfo.new(0.6), {
            ImageTransparency = v:FindFirstChild("OriginalImage").Value,
            BackgroundTransparency = v:FindFirstChild("OriginalBg").Value
        })
        local t = {v.AbsolutePosition, Tween}
        return t
    end
end