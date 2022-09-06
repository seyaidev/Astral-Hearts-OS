if not workspace:FindFirstChild("AnimationLoad") then
    local alm = Instance.new("Model")
    alm.Name = "AnimationLoad"

    local p = Instance.new("Part")
    p.Anchored = true
    p.Transparency = 1
    p.CanCollide = false
    p.Parent = alm

    local ac = Instance.new("AnimationController")
    ac.Parent = alm

    alm.Parent = workspace
end