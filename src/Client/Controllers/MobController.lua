-- Mob Controller
-- oniich_n
-- August 12, 2019

math.randomseed(os.time())

local MobController = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CastIndicator = ReplicatedStorage.Assets.Interface:WaitForChild("CastIndicator")
local RadialIndicator = ReplicatedStorage.Assets.Interface:WaitForChild("RadialIndicator", 1)

local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Player = game.Players.LocalPlayer

---create a new mob based on parameters received from a package, then inserts it into the controllers self.Mobs
-- @param FullParams table of parameters received from package
function MobController:ReplicateMob(FullParams)
    RunService.Stepped:Wait()
    assert(FullParams ~= nil, "MobController:ReplicateMob | FullParams does not exist")
    assert(typeof(FullParams) == "table", "MobController:RepliateMob | FullParams is not a table")
    -- assert(typeof(self.Mobs[FullParams.Id]) == "string", "MobController:ReplicateMob | Mob already exists")
    
    if self.Mobs[FullParams.Id] ~= nil then
        if self.Mobs[FullParams.Id].Model ~= nil then
            return
        end
    end

    local CGID = self.Services.CollisionService:GetGroupId("Mobs")

    local NewMob = {
        ServerParams = TableUtil.Copy(FullParams)
    }

    local SerialMobType = MobData.Serial[FullParams.MobType]
    NewMob.ServerParams.MobType = SerialMobType

    assert(AnimationLibrary["Mob"][SerialMobType] ~= nil, "MobController:ReplicateMob | Could not find mob animations")

    --create model
    -- if workspace.Mobs:FindFirstChild(FullParams.Id) ~= nil then
    --     workspace.Mobs:FindFirstChild(FullParams.Id):Destroy()
    -- end

    NewMob.Model = workspace.Mobs:FindFirstChild(FullParams.Id)
    if not NewMob.Model then return end
    NewMob.Model:SetPrimaryPartCFrame(CFrame.new(FullParams.Position.X, FullParams.Position.Y, FullParams.Position.Z))

    local folderOfParts = NewMob.Model:GetDescendants()
    if NewMob.Model:FindFirstChild("Visual") then
        folderOfParts = NewMob.Model:FindFirstChild("Visual"):GetDescendants()
    end

    for i, v in ipairs(folderOfParts) do
        local otrans = v:FindFirstChild("OriginalTransparency")
        if otrans then
            v.Transparency = otrans.Value
        end
    end

    NewMob.Animations = AnimationPlayer.new(NewMob.Model:FindFirstChild("AnimationController", true))
    for Name, Id in pairs(AnimationLibrary["Mob"][SerialMobType]) do
        NewMob.Animations:AddAnimation(Name, Id)
    end

    delay(math.random(1, 2) + (math.random(20, 100)/100), function()
        NewMob.Animations:PlayTrack("Idle")
    end)

    --position and physics stuff
    NewMob.DeltaTime = 0
    NewMob.LastPosition = Vector3.new(
        NewMob.ServerParams.Position.X,
        NewMob.ServerParams.Position.Y,
        NewMob.ServerParams.Position.Z
    )

    setmetatable(NewMob, MobController)
    self.Mobs[FullParams.Id] = NewMob
end

---stops animation and replication of a mob
function MobController:PauseMob(MobId)
    if self.Mobs[MobId] then
        self.Mobs[MobId].Animations:StopAllTracks()
        self.Mobs[MobId] = nil
    end
end

---destroy a mob and remove it from the controller's self.Mobs, usually as a result of death
-- @param MobId internal mob identifier
function MobController:DestructMob(MobId)
    local Mob = self.Mobs[MobId]
    if Mob == nil then return end
    -- assert(Mob ~= nil, "MobController:DestructMob | Could not find mob")
    assert(typeof(Mob) == "table", "MobController:DestructMob | Not a table")

    if Mob.Model then
        Mob.Model.Parent = workspace.Trash
        Mob.Model.PrimaryPart.CanCollide = false
        CollectionService:RemoveTag(Mob.Model.PrimaryPart, "Targetable")

        local ToAnimate = Mob.Model
        if Mob.Model:FindFirstChild("Visual") ~= nil then
            ToAnimate = Mob.Model.Visual
            for i, v in pairs(Mob.Model:GetChildren()) do
                if v.Name ~= "Visual" then v:Destroy() end
            end
        end
        for i, v in pairs(ToAnimate:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Anchored = true
                v.Material = Enum.Material.Neon
                TweenService:Create(v, TweenInfo.new(0.3+(math.random(20,80)/100), Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Color = Color3.new(0, 0, 0),
                    Position = v.Position + Vector3.new(0,3,0),
                    Transparency = 1
                }):Play()
            end
        end
        game:GetService("Debris"):AddItem(Mob.Model, 2)
    end

	self.Mobs[MobId] = nil
end

---create a numbered display of damage above the targets head
--@param MobId internal mob identifier
--@param Text text to display, usually a number or short word
--@param isPlayer if the damage indicator is displayed on the player 
function MobController:DamageIndicator(MobId, Text, isPlayer)
    if game.Players.LocalPlayer.Character == nil then return end

    local SrcPos = game.Players.LocalPlayer.Character.PrimaryPart
    if self.Mobs[MobId] ~= nil and not isPlayer then
        SrcPos = self.Mobs[MobId].Model.PrimaryPart
    elseif MobId == nil and not isPlayer then
        return 
    end

    local SourceIndicator = ReplicatedStorage.Assets.Interface:FindFirstChild("DamageIndicator")
    if SourceIndicator == nil then return end
    local NewIndicator = SourceIndicator:FindFirstChild("BillboardGui"):Clone()
    
    local SourceHolder = NewIndicator:FindFirstChild("NumberHolder", true)
    if SourceHolder == nil then return end

    local i = 1
    local tweens = {}

    
    for num in string.gmatch(Text, "(%w)") do -- 'w' represents the individual letter returned
        local NewHolder = SourceHolder:Clone()
        NewHolder.Number.Text = num
        NewHolder.Number.TextTransparency = 1
        NewHolder.Number.TextStrokeTransparency = 1

        if not isPlayer then
            NewHolder.Number.TextColor3 = Color3.fromRGB(255, 193, 193)
        else
            NewHolder.Number.TextColor3 = Color3.fromRGB(165, 75, 75)
        end

        if Text == "MISS" then
            NewHolder.Number.TextColor3 = Color3.fromRGB(255, 248, 194)
            NewHolder.Number.TextStrokeColor3 = Color3.fromRGB(121, 111, 87)
        end

        NewHolder.Number.Position = UDim2.new(0, 0, 0.5, 0)
        NewHolder.Parent = NewIndicator:FindFirstChild("Main", true)
        NewHolder.LayoutOrder = i
        i = i + 1

        local TI = TweenInfo.new(
            0.5,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out,
            0,
            true,
            math.random(1,10)/100
        )
        
        local t = TweenService:Create(NewHolder.Number, TI, {
            TextTransparency = 0;
            TextStrokeTransparency = 0.2;
            Rotation = 0;
            Position = UDim2.new(0,0,0,0)
        })
        table.insert(tweens, t)
    end
    SourceHolder:Destroy()

    NewIndicator.StudsOffset = Vector3.new(
        math.random(-2, 2) + (math.random(0, 100)/100),
        (math.random(0, 100)/100),
        math.random(-2, 2) + (math.random(0, 100)/100)
    )
    TweenService:Create(NewIndicator, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        StudsOffset = NewIndicator.StudsOffset + Vector3.new(0, 1, 0)
    }):Play()
    NewIndicator.Parent = SrcPos

    for i, v in pairs(tweens) do
        v:Play()
        wait()
    end

    Debris:AddItem(NewIndicator, 2)
end

function MobController:IndicateRadial()

end


---attack within a radius around an offset from the mob's position, based on the look vector
--@param MobId internal mob identifier
--@param radius how far around to check for targets
--@param offset Vector3 from the position on world axis
function MobController:RadialAttack(Mob, radius, offset)
    if typeof(Mob) ~= "table" then
        Mob = self.Mobs[Mob]
    end

    if not Mob then return end
    if not offset then offset = Vector3.new() end
    local worldOffset = CFrame.new(offset)
    
    local offsetCF = Mob.ServerParams._CFrame * worldOffset

    -- check around this point
    local Character = self.Player.Character
    if not Character then return end
    if (Character.PrimaryPart.Position-offsetCF.p).Magnitude <= radius then
        print("hit by radial")
    end
end

--- start method used in AeroGameFramework, sets up runtime loops and connects events
function MobController:Start()
    local MobMaid = Maid.new()

    -- local DestructionScheduler = TaskScheduler:CreateScheduler(30)
    CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function()
        MobMaid:DoCleaning()

        for i, v in pairs(self.Mobs) do
            if typeof(v) == "table" then
                self:PauseMob(i)
            end
        end

        self.Mobs = {}

        MobMaid:GiveTask(
            self:ConnectEvent("DAMAGE_EVENT", function(mobid, Skill)
                if self.Mobs[mobid] == nil then return end
                -- assert(self.Mobs[mobid] ~= nil, "MobController.DAMAGE_EVENT | Could not find mobid in self.Mobs")
                local Mob = self.Mobs[mobid]
                if Mob.Model == nil then return end
                -- assert(Mob.Model ~= nil, "MobController.DAMAGE_EVENT | Could not find model")
                
                for i, v in ipairs(Mob.Model:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Color = Color3.new(1, v.Color.g, v.Color.b)
                        delay(0.25, function()
                            v.Color = v:FindFirstChild("BaseColor").Value
                        end)
                        -- TweenService:Create(v, TweenInfo.new(0.5), {Color = v:FindFirstChild("BaseColor").Value}):Play()
                    end
                end

                local Blob = self.Controllers.DataBlob.Blob
                if not Blob then print("nope2") return end

                --get effect
                local RootPos = Mob.Model.PrimaryPart.Position

                local BaseHolder = ReplicatedStorage.Assets.Particles:FindFirstChild("Var" .. tostring(math.random(1, 2)), true)

                local fRay = Ray.new(Player.Character.PrimaryPart.Position, CFrame.new(Player.Character.PrimaryPart.Position, RootPos).lookVector*50)
                local hit, pos = workspace:FindPartOnRayWithWhitelist(fRay, {Mob.Model})

                pos = pos+Vector3.new(0, 1, 0)
                if BaseHolder then
                    local bAtt = BaseHolder:FindFirstChild("Attachment")
                    if bAtt then
                        local tAtt = bAtt:Clone()
                        tAtt.Parent = Mob.Model.PrimaryPart

                        Attachments:setAttachmentWorldCFrame(tAtt, CFrame.new(pos))
                        local ColorValue = Player.Character:FindFirstChild("BaseColor", true)
                        Debris:AddItem(tAtt, 1)
                        for i, v in ipairs(tAtt:GetChildren()) do
                            if v:IsA("ParticleEmitter") then
                                if ColorValue then
                                    v.Color = ColorSequence.new(ColorValue.Value)
                                else
                                    local trail = Player.Character:FindFirstChild("Trail", true)
                                    if trail then
                                        v.Color = trail.Color
                                    end
                                end

                                FastSpawn(function()
                                    v.Enabled = true
                                    wait(1/8.5)
                                    v.Enabled = false
                                end)
                            end
                        end
                    end
                end

                --check distance
                if Player.Character ~= nil then
                    if Player.Character.PrimaryPart == nil then return end
                    local Distance = (Player.Character.PrimaryPart.Position-RootPos).Magnitude
                    --add Z model
                    local Hitbox = Mob.Model:FindFirstChild("Hitbox")
                    if Hitbox then
                        Distance = Distance-(Hitbox.Size.Z/2)
                    end

                    if Distance > AttackRangeLibrary[Blob.Inventory[Blob.Equipment.PrimaryWeapon].ItemId] and Skill == nil then
                        return
                    elseif Skill ~= nil then
                        if Distance > Skill.LocalInfo.range+5 then print("TF") return end                    
                    end
                else
                    return
                end

                --display rounded damage dealt
                local Damage = FormulasModule:HitDamage(Blob, Skill)
                if Mob.ServerParams.Stats.Stagger > 0 then
                    Damage = Damage*0.25
                end

                self:DamageIndicator(mobid, tostring(GlobalMath:round(Damage)), false)

                if TargetingController.TargetInstance ~= nil then
                    if TargetingController.TargetInstance == Mob.Model.PrimaryPart then
                        if HUDController.UI:FindFirstChild("EnemyContainer") then
                            HUDController.UI.EnemyContainer.Health.HealthDisplay.Size = UDim2.new(
                                math.clamp((Mob.ServerParams.Stats.Health-Damage)/Mob.ServerParams.Stats.MaxHealth, 0, 1),
                                0, 1, 0
                            )

                            local StaggerConnect = FormulasModule:CalculateAttack(Blob)/5

                            HUDController.UI.EnemyContainer.Stagger.StaggerDisplay.Size = UDim2.new(
                                math.clamp((Mob.ServerParams.Stats.Stagger-StaggerConnect)/Mob.ServerParams.Stats.MaxStagger, 0, 1),
                                0, 1, 0
                            )

                            delay(0.17, function()
                                TweenService:Create(HUDController.UI.EnemyContainer.Health.HealthDelay, TweenInfo.new(0.5), {Size = HUDController.UI.EnemyContainer.Health.HealthDisplay.Size}):Play()
                            end)
                        end
                    end
                end

                MobService.BasicDamage:Fire(Mob.ServerParams.Id, Skill, tick())
            end)
        )

        -- MobService.DestroyMob:Connect(function(mobid)
        --     self:DestructMob(mobid)
        -- end)

        local function ComputeIndicator(Mob)
            local track = Mob.Animations:GetTrack("Attack")
            if Mob.Model.PrimaryPart ~= nil then
                local ncf = Mob.Model:GetPrimaryPartCFrame()
                

                if Mob.ServerParams.TargetPos ~= nil then
                    local mcf = Mob.Model:GetPrimaryPartCFrame()
                    local tcf = Mob.ServerParams.TargetPos
                    ncf = CFrame.new(
                        mcf.p,
                        Vector3.new(
                            tcf.X,
                            mcf.p.Y,	--use height of model instead of height of target
                            tcf.Z
                        )
                    )

                    Mob.Model:SetPrimaryPartCFrame(ncf)
                    return ncf
                end
            end
        end

        local function GenerateIndicatorPart(ncf, Mob, fadetime)
            local angles, f = ncf:toAxisAngle()
            local origincf = ncf * CFrame.Angles(0, angles.Y*f, 0)

            local targetcf = origincf * CFrame.new(0, 0, Mob.ServerParams.AttackRange)
            local mag = (origincf.p-targetcf.p).magnitude
            local z = 0
            local hitbox = Mob.Model:FindFirstChild("Hitbox", true)
            if hitbox then
                z = hitbox.Size.Z/2
            end
            local Indicator = Instance.new("Part")
            local AttackSize = Mob.ServerParams.Stats.AttackBox
            Indicator.Size = Vector3.new(AttackSize.X, 3, mag)
            -- print(Mob.ServerParams._CFrame)
            -- if not Mob.ServerParams._CFrame then return end
            Indicator.CFrame = ncf*CFrame.new(0, -Mob.ServerParams.Stats.Height, -z)*CFrame.new(0,0,-mag/2)

            --Indicator.CFrame = Indicator.CFrame:toObjectSpace(CFrame.new(0,0,0))

            Indicator.Anchored = true
            Indicator.CanCollide = false
            Indicator.Transparency = 1
            Indicator.Color = Color3.fromRGB(255,0,0)
            Indicator.Material = Enum.Material.Neon
            Indicator.CastShadow = false
            Indicator.Parent = workspace.Markers

            local tCI = CastIndicator:Clone()
            tCI.Frame.Size = UDim2.new(0, 0, 1, 0)
            tCI.Frame.BackgroundTransparency = 1
            tCI.Parent = Indicator

            -- print(fadetime)
            TweenService:Create(Indicator, TweenInfo.new(fadetime), {Transparency = 0.7}):Play()
            TweenService:Create(tCI.Frame, TweenInfo.new(fadetime, Enum.EasingStyle.Linear), {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0.4
            }):Play()
            -- tCI.Frame:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Linear", fadetime)
            delay(fadetime+4, function()
                if Indicator then
                    TweenService:Create(Indicator, TweenInfo.new(1), {Transparency = 1}):Play()
                end
                if tCI then
                    local f = tCI:FindFirstChild("Frame")
                    if f then
                        TweenService:Create(f, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
                    end
                end
            end)
            Debris:AddItem(Indicator, fadetime+5)
        end

        local function CreateIndicator(Mob, fadetime, isRadial)
            local ncf = ComputeIndicator(Mob)
            if ncf then
                GenerateIndicatorPart(ncf, Mob, fadetime)
            end
        end


        MobMaid:GiveTask(
            MobService.MobAttack:Connect(function(mobid, _casttimes, fadetime, isRadial)
                if self.Mobs[mobid] == nil then return end
                -- assert(self.Mobs[mobid] ~= nil, "MobController.MobAttack | Could not find mobid in self.Mobs")
                local Mob = self.Mobs[mobid]
                if Mob then
                    CreateIndicator(Mob, fadetime, isRadial)

                    delay(fadetime, function()
                        if Mob.Model ~= nil and Mob.Animations ~= nil then
                            local track = Mob.Animations:GetTrack("Attack")
                            if track then
                                Mob.Animations:PlayTrack("Attack")

                                --perform damage and dodge calculations here
                                if _casttimes then
                                    local Humanoid = self.Controllers.Character.Character:WaitForChild("Humanoid")
                                    local TargetVector = Mob.ServerParams.TargetPos
                                    for i, v in next,_casttimes do

                                        -- set up this function to cast for player at proper times, then tell the server what happened
                                            -- server will verify on their end if this actually happened/if the player cheated
                                        delay(v, function()
                                            local attackbox = Mob.ServerParams.Stats.AttackBox
                                            -- if typeof(attackbox) == "number" or not attackbox then
                                            --     attackbox = AttackRangeLibrary[Mob.ServerParams.MobType .. "_Attack"]
                                            -- end

                                            print(Mob.ServerParams.MobType, attackbox)
                                            local hits, pos, norm = Boxcast(
                                                Mob.ServerParams._CFrame,
                                                CFrame.new(Mob.ServerParams._CFrame.p, TableUtil.ToVector3(TargetVector)).lookVector*attackbox.Z,
                                                attackbox,
                                                {workspace.Characters},
                                                false
                                            )

                                            for i, hit in ipairs(hits) do
                                                local p = game.Players:GetPlayerFromCharacter(hit.Parent)
                                                if not p then
                                                    local m = hit:FindFirstAncestorOfClass("Model")
                                                    p = game.Players:GetPlayerFromCharacter(m)
                                                end
                                                if p == self.Player then
                                                    local PlayerData = self.Controllers.DataBlob.Blob
                                                    local Damage = self.Shared.FormulasModule:CalculateMob(Mob.ServerParams, PlayerData)
                                                    -- local Damage = Mob.Stats.ATK
                                                    if Mob.ServerParams.Stats.Stagger <= 0 then
                                                        Damage = Damage*0.5
                                                    end
            
                                                    Humanoid:TakeDamage(Damage)
                                                    self.Services.MobService.ReflectHealth:Fire(Humanoid.Health)
                                                    break
                                                end
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        )

        MobMaid:GiveTask(
            MobService.SpecialAttack:Connect(function(MobId, attack)
                local Mob = MobId
                if not Mob then return end

                if Mob.Animations:GetTrack(attack) then
                    local thisMaid = Maid.new()
                    thisMaid:DoCleaning()
                    local Track = Mob.Animations:GetTrack(attack)
                    Mob.Animations:PlayTrack(attack)
                    thisMaid:GiveTask(
                        Track:GetMarkerReachedSignal("SetAttack"):Connect(function(value)
                            Mob.SpecialAttack = tostring(value)
                        end)
                    )

                    thisMaid:GiveTask(
                        Track:GetMarkerReachedSignal("RadialAttack"):Connect(function(value)
                            local radius, ox, oy, oz = value:match("(%d+),(%d+),(%d+),(%d+)")
                            local offset = Vector3.new(ox, oy, oz)
                            self:RadialAttack(Mob, radius, offset)
                        end)
                    )

                    thisMaid:GiveTask(
                        Track:GetMarkerReachedSignal("IndicateRadial"):Connect(function(value)
                            
                        end)
                    )

                    thisMaid:GiveTask(
                        Track:GetMarkerReachedSignal("Attack"):Connect(function(value)
                            
                        end)
                    )

                    thisMaid:GiveTask(
                        Track.Stopped:Connect(function()
                            Mob.SpecialAttack = 0
                            thisMaid:DoCleaning()
                        end)
                    )

                end
            end)
        )

        MobMaid:GiveTask(
            MobService.MobCenter:Connect(function(MobId)
                local Mob = self.Mobs[MobId]
                if not Mob then return end
                if Mob.Animations:GetTrack("Center") then
                    Mob.Animations:PlayTrack("Center")
                end
            end)
        )

        MobMaid:GiveTask(
            MobService.DamagePlayer:Connect(function(Damage)
                self:DamageIndicator(nil, tostring(GlobalMath:round(Damage)), true)
            end)
        )

        local UpdateBeat = 0
        MobMaid:GiveTask(
            RunService.Heartbeat:Connect(function(dt)
                UpdateBeat = UpdateBeat + dt
                if UpdateBeat < 0.35 then return end
                UpdateBeat = 0
                local Package = self.Services.MobService:GetPackage()
                if Package == nil then warn("MobController.PackageUpdate | Package does not exist") return end
                if typeof(Package) ~= "table" then warn("MobController.PackageUpdate | Package was not a table") return end
                -- assert(Package ~= nil, "MobController.PackageUpdate | Package does not exist")
                -- assert(typeof(Package) == "table", "MobController.PackageUpdate | Package was not a table")

                if #Package == 0 then
                    for MobId, Mob in pairs(self.Mobs) do
                        if typeof(Mob) == "table" then
                            self:PauseMob(MobId)
                        end
                    end
                    return
                end

                -- print("snapple")
                for _,MobInfo in ipairs(Package) do
                    --check if mob already exists
                    if self.Mobs[MobInfo.Id] ~= nil and self.Mobs[MobInfo.Id] ~= "Replicating..." then
                        if self.Mobs[MobInfo.Id].Model ~= nil then
                            self.Mobs[MobInfo.Id].ServerParams = MobInfo
                            self.Mobs[MobInfo.Id].ServerParams.MobType = MobData.Serial[self.Mobs[MobInfo.Id].ServerParams.MobType]
                        else
                            self.Mobs[MobInfo.Id] = "Replicating..."
                            self:ReplicateMob(MobInfo)
                        end
                    else
                        self.Mobs[MobInfo.Id] = "Replicating..."
                        self:ReplicateMob(MobInfo)
                    end
                end

                --check for removed mobs
                for MobId, Mob in pairs(self.Mobs) do
                    if typeof(Mob) == "table" then
                        local existence = TableUtil.Filter(Package, function(item)
                            return item.Id == Mob.ServerParams.Id
                        end)
                        -- print(#existence)
                        if #existence == 0 then --mob no longer in package, doesn't exist for this client anymore
                            self:PauseMob(MobId)
                        end
                    end
                end
            end)
        )
        local function TransparencyInit(child)
            local folderOfParts = child:GetDescendants()
            if child:FindFirstChild("Visual") then
                folderOfParts = child:FindFirstChild("Visual"):GetDescendants()
            end

            
            for i, v in ipairs(folderOfParts) do
                if v:IsA("BasePart") and v.Name ~= "Hitbox" and v.Name ~= "HumanoidRootPart" then 
                    local original = Instance.new("NumberValue", v)
                    original.Name = "OriginalTransparency"
                    original.Value = v.Transparency
                    -- if not self.Mobs[child.Name] then
                    v.Transparency = 1
                    -- end
                end
            end

        end
        MobMaid:GiveTask(
            workspace:WaitForChild("Mobs").ChildAdded:Connect(TransparencyInit)
        )
        
        for i, v in ipairs(workspace:WaitForChild("Mobs"):GetChildren()) do
            if v:IsA("Model") then
                TransparencyInit(v)
            end
        end

        MobMaid:GiveTask(
            RunService.Heartbeat:Connect(function(dt)
                --update model to match position
                for MobId, Mob in pairs(self.Mobs) do
                    if typeof(Mob) == "table" then
                        --construct vector from ServerParams
                        local sPosition = Vector3.new(
                            Mob.ServerParams.Position.X,
                            Mob.ServerParams.Position.Y + Mob.ServerParams.Stats.Height,
                            Mob.ServerParams.Position.Z
                        )

                        --create looking CFramwe
                        -- local lCF = CFrame.new(sPosition) * (CFrame.new(Mob.Model.PrimaryPart.Position, sPosition) * CFrame.new(-Mob.Model.PrimaryPart.Position))

                        local lCF = Mob.ServerParams._CFrame
                        if Mob.Model ~= nil and Mob.Model.PrimaryPart ~= nil then
                            
                            -- print(Mob.ServerParams.AttackRange)
                            if (sPosition-Mob.Model.PrimaryPart.Position).Magnitude > 2 then
                                --calculate alpha
                                    --get distance, time that would be necessary to travel, then use that to get how far you can travel in a single step
                                local Distance = (sPosition-Mob.Model.PrimaryPart.Position).Magnitude
                                local TimeToTravel = Distance/Mob.ServerParams.Stats.Speed
                                if lCF and TimeToTravel then
                                    lCF = lCF * CFrame.new(0, Mob.ServerParams.Stats.Height, 0)
                                    Mob.Model:SetPrimaryPartCFrame(Mob.Model:GetPrimaryPartCFrame():lerp(lCF, dt/TimeToTravel))
                                    if not Mob.Animations:GetTrack("Walk").IsPlaying then
                                        Mob.Animations:PlayTrack("Walk")
                                    end
                                end
                            elseif (sPosition-Mob.Model.PrimaryPart.Position).Magnitude > 30 then
                                Mob.Model:SetPrimaryPartCFrame(lCF)
                            elseif Mob.ServerParams.FSMcurrent == 1 or Mob.ServerParams.FSMcurrent == 2 then
                                if not Mob.Animations:GetTrack("Attack").IsPlaying then
                                    Mob.Animations:PlayTrack("Idle")
                                end
                            end
                        end


                        if TargetingController.TargetInstance ~= nil then
                            if TargetingController.TargetInstance == Mob.Model.PrimaryPart then
                                if HUDController.UI then
                                    local EnemyContainer = HUDController.UI:FindFirstChild("EnemyContainer")
                                    if EnemyContainer then
                                        EnemyContainer.Stagger.StaggerDisplay.Size = UDim2.new(
                                            math.clamp((Mob.ServerParams.Stats.Stagger)/Mob.ServerParams.Stats.MaxStagger, 0, 1),
                                            0, 1, 0
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        )
    end)
end

---Init method used in AeroGameFramework, initializes global variables and events
function MobController:Init()
    self:RegisterEvent("DAMAGE_EVENT")

	HUDController = self.Controllers.HUD
    CharacterController = self.Controllers.Character
    CameraController = self.Controllers.CameraController
    StaggerController = self.Controllers.StaggerController
    TargetingController = self.Controllers.Targeting
    TaskScheduler = self.Controllers.TaskScheduler

    MobService = self.Services.MobService

    Attachments = self.Shared.Attachments
    AnimationPlayer = self.Shared.AnimationPlayer
    Boxcast = self.Shared.Boxcast
    TableUtil = self.Shared.TableUtil
    Maid = self.Shared.Maid
    FSM = self.Shared.FSM
    AnimationLibrary = self.Shared.Cache:Get("AnimationLibrary")
    AttackRangeLibrary = self.Shared.Cache:Get("AttackRangeLibrary")
    repr = self.Shared.repr
    GlobalMath = self.Shared.GlobalMath
    MobData = self.Shared.MobData
    FormulasModule = self.Shared.FormulasModule
    FastSpawn = self.Shared.FastSpawn

    self.Mobs = {}
end


return MobController