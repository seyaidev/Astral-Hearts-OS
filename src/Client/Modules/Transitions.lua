local Transitions = {}
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

function Transitions:ClearTable(t)
    for i, v in pairs(t) do
        if v ~= nil then
            v:Destroy()
        end
    end
end

local function GenerateTween(v, reverse)
    local Tween = nil
    local Goal = {}
    if not reverse then
        if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
            local origt = v.TextTransparency
            local origts = v.TextStrokeTransparency

            v.TextTransparency = 1
            v.TextStrokeTransparency = 1

            Goal = {
                TextTransparency = origt,
                TextStrokeTransparency = origts
            }

            Tween = TweenService:Create(v, TweenInfo.new(0.325), Goal)
        elseif v:IsA("ImageLabel") or v:IsA("ViewportFrame") then
            local origt = v.ImageTransparency

            v.ImageTransparency = 1


            Goal = {
                ImageTransparency = origt,
            }
            Tween = TweenService:Create(v, TweenInfo.new(0.325), Goal)
        elseif v:IsA("Frame") then
            local origt = v.BackgroundTransparency

            v.BackgroundTransparency = 1

            Goal = {
                BackgroundTransparency = origt,
            }
            Tween = TweenService:Create(v, TweenInfo.new(0.325), Goal)
        end
    else
        if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
            local origt = v.TextTransparency
            local origts = v.TextStrokeTransparency

            Goal = {
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }
            Tween = TweenService:Create(v, TweenInfo.new(0.325), Goal)

            delay(0.325, function()
                v.TextTransparency = origt
                v.TextStrokeTransparency = origts
            end)
        elseif v:IsA("ImageLabel") or v:IsA("ViewportFrame") then
            local origt = v.ImageTransparency

            Goal = {
                ImageTransparency = 1,
            }
            Tween = TweenService:Create(v, TweenInfo.new(0.325), Goal)

            delay(0.325, function()
                v.ImageTransparency = origt
            end)
        elseif v:IsA("Frame") then
            local origt = v.BackgroundTransparency

            Tween = TweenService:Create(v, TweenInfo.new(0.325), {
                BackgroundTransparency = 1,
            })

            delay(0.325, function()
                v.BackgroundTransparency = origt
            end)
            Goal = {
                BackgroundTransparency = origt
            }
        end
    end

    return Tween, Goal
end

function Transitions:TransitionDown(v, reverse)
    local origYoffset = v.Position.Y.Offset
    if CollectionService:HasTag(v, "TransitionDown") and not reverse then
        -- print(v.Position.X.Scale)

        v.Position = UDim2.new(
            v.Position.X.Scale,
            v.Position.X.Offset,
            v.Position.Y.Scale,
            origYoffset-25
        )

        local Tween, Goal = GenerateTween(v, reverse)

        v.Visible = true

        if Tween then Tween:Play() end
        if Goal then
            for prop, val in pairs(Goal) do
                Goal[prop] = val
            end
        end
        v:TweenPosition(
            UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset
            ), "Out", "Quad", 0.325, true
        )
    elseif CollectionService:HasTag(v, "TransitionDown") and reverse then
        
        local Tween, Goal = GenerateTween(v, reverse)
        if Tween then Tween:Play() end
        if Goal then
            for prop, val in pairs(Goal) do
                Goal[prop] = val
            end
        end

        v:TweenPosition(
            UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset-25
            ), "Out", "Quad", 0.325, true
        )

        delay(0.325, function()
            v.Visible = false
            v.Position = UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset
            )
        end)
    end
end

function Transitions:TransitionUp(v, reverse)
    local origYoffset = v.Position.Y.Offset
    if CollectionService:HasTag(v, "TransitionUp") and not reverse then

        v.Position = UDim2.new(
            v.Position.X.Scale,
            v.Position.X.Offset,
            v.Position.Y.Scale,
            origYoffset+25
        )

        local Tween, Goal = GenerateTween(v, reverse)
        v.Visible = true
        if Tween then Tween:Play() end
        if Goal then
            for prop, val in pairs(Goal) do
                Goal[prop] = val
            end
        end

        v:TweenPosition(
            UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset
            ), "Out", "Quad", 0.325, true
        )
        
    elseif CollectionService:HasTag(v, "TransitionUp") and reverse then

        local Tween, Goal = GenerateTween(v, reverse)
        if Tween then Tween:Play() end
        if Goal then
            for prop, val in pairs(Goal) do
                Goal[prop] = val
            end
        end

        v:TweenPosition(
            UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset+25
            ), "Out", "Quad", 0.325, true
        )

        delay(0.325, function()
            v.Visible = false
            v.Position = UDim2.new(
                v.Position.X.Scale,
                v.Position.X.Offset,
                v.Position.Y.Scale,
                origYoffset
            )
        end)

    end
end

function Transitions:TweenIn(v, start)
    if v == nil then return end
    if CollectionService:HasTag(v, "TransitionDown") and (not CollectionService:HasTag(v, "IgnoreTransition") and start == true) then
        if not (CollectionService:HasTag(v, "SuperIgnore") and start == false) then
            self:TransitionDown(v, false)
        end

    elseif CollectionService:HasTag(v, "TransitionUp") and (not CollectionService:HasTag(v, "IgnoreTransition") and start == true) then
        if not (CollectionService:HasTag(v, "SuperIgnore") and start == false) then
            self:TransitionUp(v, false)
        end

    elseif not (CollectionService:HasTag(v, "IgnoreTransition") and start == true) then
        if not (CollectionService:HasTag(v, "SuperIgnore") and start == false) then
            if v:IsA("GuiObject") then
                v.Visible = true
            end
        end
    end
end

function Transitions:TweenOut(v)
    if CollectionService:HasTag(v, "TransitionDown") and v:IsA("GuiObject") then
        -- print(v.Name)
        self:TransitionDown(v, true)

    elseif CollectionService:HasTag(v, "TransitionUp") and v:IsA("GuiObject") then

        self:TransitionUp(v, true)

    else
        if v:IsA("GuiObject") then
            delay(0.325, function()
                v.Visible = false
            end)
        end
    end
end

function Transitions:RecursiveDisplay(obj, dir)
    local function RecursiveDisplay(obj)
        for i, v in pairs(obj:GetChildren()) do
            if dir == "in" then
                self:TweenIn(v, true)
            elseif dir == "out" then
                self:TweenOut(v)
            end

            if #v:GetChildren() > 0 then
                delay(0.05, function()
                    RecursiveDisplay(v)
                end)
            end
        end
    end

    RecursiveDisplay(obj)
end

return Transitions