-- Mob Service
-- oniich_n
-- August 10, 2019


--wehn receiving events from the client, check position to 10 frames in the future

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TreeCreator = require(ReplicatedStorage:WaitForChild("BehaviorTrees").TreeCreator)

local MobService = {Client = {}}
-- MobService.__aeroOrder = 3

local Regions = {}
local Mobs = {}
local Packages = {}
local TimeVault = {}

local PlayerRegions = {}
local RegionInventories = {}

--- create mob based on parameters
-- @param InitParams table of initial parameters for the mob (like mob type, data, etc.)
function MobService:SpawnMob(InitParams)
    assert(typeof(InitParams) == "table", "MobService:SpawnMob | InitParams was not a table")
    local Mob = TableUtil.Copy(InitParams)

    --Establish Mob properties
        --Create a state machine!
    Mob.Id = HttpService:GenerateGUID(false)
    Mob.Maid = Maid.new()
    Mob._resolveHits = {}
    Mob._idleCountdown = 10
    --[[
        planned states:
            walking, idle, attacking, dizzy

    ]]

    Mob.FSM = FSM.create({
        initial = "idle";
        events = {
            {name = "walk", from = {"idle", "walking", "attacking"}, to = "walking"},
            {name = "prepare", from = {"idle", "walking"}, to = "preparing"},
            {name = "attack", from = "preparing", to = "attacking"},
            {name = "stagger", from = {"idle", "walking", "attacking", "preparing"}, to = "dizzy"},
            {name = "stop", from = "*", to = "idle"},
            {name = "center", from = {"idle", "dizzy"}, to = "centering"},
            {name = "special", from = "preparing", to = "special_attacking"}
        },
        callbacks = {
            on_attack = function()
                local otimes = {}
                for i, v in ipairs(Mob._CastTimes) do
                    otimes[i] = v-Mob.Time
                end
                -- print(repr(otimes))
                self:FireAllClientsEvent("MobAttack", Mob.Id, otimes, 0.5, false) 
            end,

            on_prepare = function(this, event, from, to, First, isRadial)
                local fadetime = 0.5
                if First then
                    fadetime = First+(0.35*1.25)
                end
                -- print("fadetime:", fadetime)
                for _, Player in ipairs(Players:GetPlayers()) do
                    local Delay = PingService.Delays[Player.UserId] or 2.5
                    local DelayTime = Delay/60
                    delay(DelayTime, function()
                        self:FireClientEvent("Indicator", Player, Mob.Id, fadetime, isRadial)
                    end)                 
                end
            end,

            on_stagger = function()
                self:FireAllClientsEvent("MobDizzy", Mob.Id)
            end,

            on_center = function()
                -- plays the centering animation
                Mob.Position = Mob.OriginPos
                Mob.TargetPos = Mob.OriginPos
                self:FireAllClientsEvent("MobCenter", Mob.Id)
            end,

            on_special = function(this, event, from, to, specialMove)
                for _, Player in ipairs(Players:GetPlayers()) do
                    local Delay = PingService.Delays[Player.UserId] or 2.5
                    local DelayTime = Delay/60
                    delay(DelayTime, function()
                        self:FireClientEvent("SpecialAttack", Player, Mob.Id, specialMove)
                    end)                 
                end
            end
        }
    })

    Mob.State = FSM.create({
        initial = "passive";
        events = {
            {name = "aggro", from = {"active", "passive"}, to = "active"},
            {name = "chill", from = "active", to = "passive"}
        };

        callbacks = {
            on_aggro = function(this, event, from, to, Target)
                Mob.Target = Target
                if Target:IsA("Model") then
                    local Humanoid = Target:FindFirstChild("Humanoid")
                    if Humanoid ~= nil then
                        Mob.Maid:GiveTask(Humanoid.Died:Connect(function()
                            -- print("TARGET DIED")
                            Mob.Target = nil
                            this.chill()
                        end))
                    end
                end
                -- print("Aggro'd " .. tostring(Mob.Target))
            end,

            on_enter_passive = function(this, event, from, to)
                Mob.Target = nil
                Mob.Maid:DoCleaning()
            end
        }
    })

    Mob._ActionFinish = 0

    local CGID = self.Services.CollisionService:GetGroupId("Mobs")
    local BaseModel = AssetService:LoadAsset(Mob.MobType .. "_Model")
    Mob.Model = BaseModel:Clone()
    Mob.Model.Name = Mob.Id
    Mob.Model.Parent = workspace.Mobs
    Mob.Model.PrimaryPart.Anchored = true

    Mob._ZOffset = Mob.Model:FindFirstChild("Hitbox", true).Size.Z

    local HealthDisplay = ReplicatedStorage.Assets.Interface:FindFirstChild("MicroHealth"):Clone()
    HealthDisplay.Parent = Mob.Model

    CollectionService:AddTag(Mob.Model.PrimaryPart, "Targetable")
    for i, v in pairs(Mob.Model:GetDescendants()) do
        if v:IsA("BasePart") then
            local BaseColor = Instance.new("Color3Value")
            BaseColor.Name = "BaseColor"
            BaseColor.Value = v.Color
            BaseColor.Parent = v

            CollectionService:AddTag(v, "mobid:" .. Mob.Id)
            v.CollisionGroupId = CGID
        end
    end

    Mob.Animations = AnimationPlayer.new(Mob.Model:FindFirstChild("AnimationController", true))
    for i, v in pairs(AnimationLibrary.Mob[Mob.MobType]) do
        Mob.Animations:AddAnimation(i, v)
    end

    Mob.Model:SetPrimaryPartCFrame(CFrame.new(Mob.Position.X, Mob.Position.Y, Mob.Position.Z))

    ---create the behavior tree of the for use when performing actions
    local FreshNodes = TableUtil.Copy(self.Modules.NodesModule)

    if InitParams.Tree then
        Mob.Brain = TreeCreator:Create(Mob, InitParams.Tree)
    else
        Mob.Brain = TreeCreator:Create(Mob, "BasicMob")
    end

    Mob.Brain:setObject(Mob)
    Mob.Time = 0
    Mob.LastOrigin = 0
    Mob.OriginPos = TableUtil.ToVector3(Mob.Position)

    --- radial attack (as opposed to a hitbox)
    -- @param origin Vector3 of where to start the radial attack from
    -- @param radius Radius of the radial attack
    -- @param dt Delay time for the attack (obsolete, convert to _resolveHits)
    function Mob.RadialAttack(origin, radius, dt)
        dt = dt or 0.1
        delay(dt, function()
            --get players in region
            local inRegion = {}
            for Player, Regions in pairs(PlayerRegions) do
                if table.find(Regions, Mob.RegionId) then
                    table.insert(inRegion, Player)
                end
            end
            --check their distance to the player
            for _, Player in ipairs(inRegion) do
                local Character = Player.Character
                local HRP = Character.PrimaryPart
                if HRP then
                    if (origin-HRP.Position).Magnitude <= radius then
                        --damage players and stuff
                        local Damage = self.Shared.FormulasModule:CalculateMob(Mob, PlayerData)
                        -- local Damage = Mob.Stats.ATK
                        if Mob.Stats.Stagger <= 0 then
                            Damage = Damage*0.5
                        end

                        -- print(Damage)
                        Player.Character.Humanoid:TakeDamage(Damage)
                        self:FireClientEvent("DamagePlayer", Player, Damage)
                    end
                end
            end
        end)
    end

    --- step function for updating the state of the mob
    -- @param this self reference
    -- @param time current time of the server
    -- @param dt Delta time since last step
    function Mob.Update(this, time, dt)
        Mob.Time = time

        if Mob.State.current == "passive" then
            --check for nearby aggro
            local Position = TableUtil.ToVector3(Mob.Position)
            if (Position-Mob.Origin).Magnitude > 15 then
                -- return to base
                local NextPosition, NextCFrame = CalculateNextPosition(Position, Mob.Origin, Mob.Stats.Height, Mob.Stats.Speed, dt)
                Mob.Position.Y = math.clamp(Mob.Position.Y, Mob.MinHeight, Mob.MaxHeight)
                Mob.Position = NextPosition
                Mob._CFrame = NextCFrame

            -- elseif (Position-Mob.OriginPos).Magnitude > 0.2 then
            --     local NextPosition, NextCFrame = CalculateNextPosition(Position, Mob.OriginPos, Mob.Stats.Height, Mob.Stats.Speed, dt)
            --     -- print("moving")
            --     if Mob.FSM.can("walk") then
            --         Mob.FSM.walk()
            --     end
            --     Mob.Position = NextPosition
            --     Mob._CFrame = NextCFrame
            --     Mob.LastOrigin = 0
            -- elseif Mob.LastOrigin > 3 and (Position-Mob.OriginPos).Magnitude <= 0.2 then
            --     Mob.OriginPos = Mob.Origin+Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
            --     Mob.LastOrigin = 0
            else
                if Mob._idleCountdown <= 0 then
                    local Position = TableUtil.ToVector3(Mob.Position)
                    local offsetVector = Vector3.new(
                        math.random(-15, 15),

                        Mob.Stats.Height,

                        math.random(-15, 15)
                    )

                    if Mob.FSM.can("walk") then
                        Mob.FSM.walk()
                    end

                    local NewPosition = Mob.OriginPos + offsetVector
                    local NextPosition, NextCFrame = CalculateNextPosition(Position, NewPosition, Mob.Stats.Height, Mob.Stats.Speed, dt)
                    
                    -- print((Position-NewPosition).Magnitude)
                    

                    Mob.Position = NextPosition
                    -- Mob.Position.Y = math.clamp(Mob.Position.Y, Mob.MinHeight, Mob.MaxHeight)
                    Mob._CFrame = NextCFrame
                    Mob._idleCountdown = math.random(3, 4)
                else
                    if Mob.FSM.current ~= "idle" then
                        Mob.FSM.stop()
                    end
                    Mob._idleCountdown = Mob._idleCountdown - dt
                end
            end
            -- Mob.LastOrigin = Mob.LastOrigin+dt
           
            if Mob.Stats.Aggro == true then
                for i, Character in ipairs(workspace.Characters:GetChildren()) do
                    local nvec = Vector3.new(Mob.Position.X, Mob.Position.Y, Mob.Position.Z)
                    if Character.PrimaryPart ~= nil then
                        if (Character.PrimaryPart.Position-nvec).Magnitude < 40 then
                            if Mob.State.can("aggro") and Mob.Target == nil then
                                Mob.State.aggro(Character)
                            end
                        end
                    end
                end
            end
        end

        if Mob.State.current == "active" then
            if Mob.Target == nil then --add checks to see if truly nil
                if Mob.State.can("chill") then
                    Mob.State.chill()
                end
            end
        end

        if Mob.Stats.Stagger <= 0 then
            Mob.Stats.UnDCounter = Mob.Stats.UnDCounter+dt
            if Mob.Stats.UnDCounter >= Mob.Stats.Undizzy then
                Mob.Stats.Stagger = Mob.Stats.MaxStagger
                Mob.Stats.UnDCounter = 0
                Mob.FSM.stop()
            end
        else
            if Mob.Stats.Stagger < Mob.Stats.MaxStagger and Mob.Stats.Stagger > 0 then
                Mob.Stats.Stagger = math.clamp(Mob.Stats.Stagger+(Mob.Stats.MaxStagger*(0.05/(1/dt))), 0.1, Mob.Stats.MaxStagger)
            end
        end

        if Mob._resolveHits then
            local toRemove = {}
            for i, hit in ipairs(Mob._resolveHits) do
                if hit.Time > 0 then
                    hit.Time = hit.Time - dt
                    -- print(hit.Time)
                elseif hit.Humanoid then
                    --check if player's health is reduced
                    if hit.Humanoid.Health > hit.ExpectedHealth then
                        -- hit.Humanoid.Health = hit.ExpectedHealth
                        local Player = game.Players:GetPlayerFromCharacter(hit.Humanoid.Parent)
                        if Player then
                            self.Services.PlayerService:SetPartial(Player, "_lastHit", 7.5)
                        end
                        table.insert(toRemove, i)
                        -- print("Adjusted", Humanoid.Health)
                    end
                end
            end

            for i, v in ipairs(toRemove) do
                table.remove(Mob._resolveHits, v)
            end
        end

        if Mob._CastTimes ~= nil then
            if #Mob._CastTimes > 0 then

                if Mob.FSM.can("attack") or Mob.FSM.current == "attacking" then 
                    if Mob.FSM.current ~= "attacking" then
                        Mob.FSM.attack()
                    end

                    for i, v in pairs(Mob._CastTimes) do
                        if Mob.Time >= v and Mob.TargetPos ~= nil and Mob._CFrame ~= nil then
                            Mob._CastTimes[i] = nil
                            --get potential hits
                            
                            local attackbox = Mob.Stats.AttackBox

                            local hits, pos, norm = Boxcast(
                                Mob._CFrame,
                                CFrame.new(Mob._CFrame.p, Mob.TargetPos).lookVector*attackbox.Z,
                                attackbox,
                                {workspace.Characters},
                                false
                            )

                            -- in X amount of frames + 2,
                            -- check again to see if thfdae player was in that
                            -- area and if they were dodging or not
                            for i,hit in ipairs(hits) do

                                local Player = game.Players:GetPlayerFromCharacter(hit.Parent)
                                if not Player then
                                    local m = hit:FindFirstAncestorOfClass("Model")
                                    Player = game.Players:GetPlayerFromCharacter(m)
                                end
                                local PlayerData = self.Services.PlayerService:GetPlayerData(Player)

                                -- print(hit)
                                if Player then
                                    if Player.Character then
                                        if (hit.Position-pos[i]).Magnitude <= 4 then
                                            if Player.Character.Humanoid ~= nil then
                                                if Player.Character.Humanoid.Health > 0 then
                                                    local Damage = self.Shared.FormulasModule:CalculateMob(Mob, PlayerData)
                                                    -- local Damage = Mob.Stats.ATK
                                                    if Mob.Stats.Stagger <= 0 then
                                                        Damage = Damage*0.5
                                                    end
                                                    -- print(Damage)

                                                    --get lowest expected health from this mob

                                                    table.insert(Mob._resolveHits, {
                                                        Humanoid = Player.Character.Humanoid;
                                                        Time = 1;
                                                        ExpectedHealth = Player.Character.Humanoid.Health-Damage;
                                                    })
                                                    print("regeistered")
                                                    -- Player.Character.Humanoid:TakeDamage(Damage)
                                                    -- self:FireClientEvent("DamagePlayer", Player, Damage)
                                                end
                                            end
                                        end
                                    end
                                    
                                end
                            end
                        end
                    end
                end
            end
        end

        if Mob.FSM.current == "attacking" then 
            if Mob.Time >= Mob._ActionFinish then
                Mob.FSM.stop()
            end
            return
        end
    end

    setmetatable(Mob, Mobs)
    Mobs[Mob.Id] = Mob
    return Mob
end

--- Reward player when a mob has been slain
-- @param Player player that killed the mob
-- @param MobId internal mob identifier
function MobService:MobSlain(oPlayer, MobId)
    local Blob = self.Services.PlayerService:GetPlayerData(oPlayer)
    assert(Blob ~= nil, "MobService:MobSlain | Could not get Player blob")

    local Mob = Mobs[MobId]
    assert(Mob ~= nil, "MobService:MobSlain | Could not get Mob from MobId")

    if Mob.Slain then return end
    --get rewards
    local BaseRewards = {
        EXP = Mob.Stats.EXP;
        Munny = math.random(6*Mob.Stats.Level, 9*Mob.Stats.Level);
    }
    -- MobRewards[Mob.MobType]
    --update rewards based on level difference
        --come up with a formula for this LATER
    local PartiesRewarded = {}
    FastSpawn(function() 
        for Player, DamageDealt in pairs(Mob.DamagePool) do

            if RegionInventories[Player] then
                if RegionInventories[Player][Mob.RegionId] then
                    local Items = {}
                    for DropName, DropData in pairs(RegionInventories[Player][Mob.RegionId]) do
                        -- random check
                        if DropData.Quest then
                            if not self.Services.QuestService:HasQuestInProgress(Player, DropData.Quest) then
                                print("does not have the quest")
                                continue
                            end
                            print("does have the quest")
                        end
                        local num = math.random(0, 100)
                        local check = math.floor(DropData.Rate*100)
                        print(DropName, num, check)
                        if num <= check then
                            if DropData.Quantity == -1 then

                                table.insert(Items, {
                                    Type = DropData.Type;
                                    ItemId = DropName;
                                })
                            elseif DropData.Quantity > 0 then
                                table.insert(Items, {
                                    Type = DropData.Type;
                                    ItemId = DropName;
                                })
                                DropData.Quantity = DropData.Quantity - 1
                                RegionInventories[Player][Mob.RegionId][DropName] = DropData
                            else
                                print("no drops left:", DropName)
                            end
                        end
                    end

                    if #Items > 0 then
                        self.Services.DropService:CacheDrop({
                            Id = HttpService:GenerateGUID();
                            Items = Items;
                            UserId = Player.UserId;
                            Position = TableUtil.ToVector3(Mob.Position);
                            -- Timeout = 60;
                        }, Mob.RegionId)
                    end
                end
            end

            local Percent = math.clamp(DamageDealt/Mob.Stats.MaxHealth, 0, 1)
            if Percent > 0 then
                local LevelDiff = Blob.Stats.Level-Mob.Stats.Level
                if LevelDiff <= 3 and LevelDiff > 0 then
                    Percent = Percent
                
                --underleveled player, bonus percent
                elseif LevelDiff < 0 and LevelDiff > -2 then
                    Percent = Percent*1.03
                elseif LevelDiff < 0 and LevelDiff > -5 then
                    Percent = Percent*1.05

                elseif LevelDiff > 3 then
                    Percent = Percent*0.7
                elseif LevelDiff > 5 then
                    Percent = Percent*0.3
                elseif LevelDiff > 7 then
                    Percent = Percent*0.1
                end
                self.Services.PlayerService:Reward(Player.UserId, BaseRewards, Percent)

                -- potentially generate a drop from this
                    -- go thru all the potential drop items, use random to check if it will be created
                    -- subtract from total player quantity if > 0
                
                
                
                local otherMembers, leader = self.Services.PartyService:findParty(Player.UserId)
                if otherMembers and leader then
                    if not PartiesRewarded[leader] then
                        local multiplier = Percent*0.5 --change this to check leechable and stuff later on down the line

                        self.Services.PlayerService:Reward(leader.UserId, BaseRewards, multiplier)
                        for i, v in pairs(otherMembers) do
                            self.Services.PlayerService:Reward(v, BaseRewards, multiplier)
                        end
                    end
                end
            end
        end
    end)

    --update player quests
    self.Services.QuestService:UpdateQuest(oPlayer, {
        Objective = "KILL";
        Target = Mob.MobType
    })
    --remove from mob list
    FastSpawn(function()
        Mob.Dead = true
        Mob.Model:Destroy()
        Mobs[MobId] = nil
        Regions[Mob.RegionId].Mobs[MobId] = nil
        Mob.Slain = true
    end)
end

--- client request for a mob package for use in its their replication
-- @param Player player requesting
-- @return table of current mob states
function MobService.Client:GetPackage(Player)
    if Packages[Player.UserId] ~= nil then
        return Packages[Player.UserId]
    else
        return nil
    end
end

function MobService:ReturnDrop(Player, Region, Items)
    if RegionInventories[Player] then
        if RegionInventories[Player][Region] then
            for _, ItemData in pairs(Items) do
                if RegionInventories[Player][Region][ItemData.ItemId] then
                    if RegionInventories[Player][Region][ItemData.ItemId].Quantity < 0 then return end
                    RegionInventories[Player][Region][ItemData.ItemId].Quantity = RegionInventories[Player][Region][ItemData.ItemId].Quantity + 1
                    print("Returned", ItemData.ItemId, RegionInventories[Player][Region][ItemData.ItemId].Quantity)
                end
            end

            
        end
    end
end

function MobService:GetLocations(player, type, id)
    local Locations = {}
    local RegionInventory = RegionInventories[player]
    if not RegionInventory then return Locations end
    for RegionName, RegionData in pairs(Regions) do
        if type == "GATHER" then
            -- check if drop exists
            if RegionData.Drops[id] then
                -- check player inventory to see if uncollected
                if RegionInventory[RegionData.Id][id].Quantity > 0 then
                    local data = {RegionData.Center, RegionInventory[RegionData.Id][id].Quantity}
                    table.insert(Locations, data)
                end
            end
        elseif type == "KILL" then
            if RegionData.MobType == id then
                table.insert(Locations, {RegionData.Center})
            end
        end
    end

    return Locations
end

--- get parameters of a mob spawn region
-- @param Region name of the region
-- @return table of initial parameters for use in mob spawning
function MobService:GetInitParams(Region)
    local InitParams = {
        MobType = Region.MobType;
        RegionId = Region.Id;
        AttackRange = (typeof(AttackRangeLibrary[Region.MobType .. "_Attack"]) == "Vector3" and AttackRangeLibrary[Region.MobType .. "_Attack"].Z or AttackRangeLibrary[Region.MobType .. "_Attack"]) ;

        Stats = TableUtil.Copy(MobData[Region.MobType]);
        Tree = Region.Tree;

        Center = Region.Center;
        MinPos = Region.MinPos;
        MaxPos = Region.MaxPos;

        Position = Vector3.new(
            math.random(Region.MinPos.X, Region.MaxPos.X),
            Region.Center.Y,
            math.random(Region.MinPos.Z, Region.MaxPos.Z)
        );

        MinHeight = Region.Center.Y - 15;
        MaxHeight = Region.Center.Y + 15;

        LastSpawn = 0;
        DamagePool = {};
        Slain = false;
    }
    
    -- local level_string = tostring(InitParams.Stats.Level)
    -- if not BaselineHP[level_string] then
    --     for i = InitParams.Stats.Level, 1, -1 do
    --         if BaselineHP[tostring(i)] then
    --             InitParams.Stats.MaxHealth = BaselineHP[tostring(i)](InitParams.Stats.Level)
    --             break
    --         end
    --     end
    -- else
    --     InitParams.Stats.MaxHealth = BaselineHP[level_string](InitParams.Stats.Level)
    -- end

    -- if not LevelMultipliers[level_string] then
    --     for i = InitParams.Stats.Level, 1, -1 do

    --         if LevelMultipliers[tostring(i)] then
    --             InitParams.Stats.MaxHealth = InitParams.Stats.MaxHealth * LevelMultipliers[tostring(i)](InitParams.Stats.Level)
    --             break
    --         end
    --     end
    -- else
    --     InitParams.Stats.MaxHealth = InitParams.Stats.MaxHealth * LevelMultipliers[level_string](InitParams.Stats.Level)
    -- end
    
    -- print("MaxHealth:", InitParams.Stats.MaxHealth)
    InitParams.Stats.Health = InitParams.Stats.MaxHealth
    InitParams.Stats.Height = Region.Height
    InitParams.Stats.MaxStagger = InitParams.Stats.Stagger
    InitParams.Stats.Undizzy = 12
    InitParams.Stats.UnDCounter = 0
    

    local heightray = Ray.new(Vector3.new(InitParams.Position.X, InitParams.Position.Y, InitParams.Position.Z), Vector3.new(0, -20, 0))
    local hit, pos, norm = workspace:FindPartOnRayWithWhitelist(heightray, {
        workspace.Terrain
    })

    if hit and pos then
        local NewPos = Vector3.new(
            InitParams.Position.X,
            pos.Y + Region.Height,
            InitParams.Position.Z
        )
        InitParams.Position = NewPos
    end
    InitParams.Origin = TableUtil.ToVector3(InitParams.Position)
    return InitParams
end



function MobService:GenerateRegion(RegionPart)
    if RegionPart:FindFirstChild("MobType") then
        local BaseModel = AssetService:LoadAsset(RegionPart.MobType.Value .. "_Model")
        -- local BaseModel = ReplicatedStorage:FindFirstChild(RegionPart.MobType.Value .. "_Model", true)
        if BaseModel ~= nil then
            local NewRegion = {
                Id = RegionPart.Name;
                LastSpawn = 0;
                
                Center = RegionPart.Position;
                MinPos = RegionPart.Position-(RegionPart.Size/2);
                MaxPos = RegionPart.Position+(RegionPart.Size/2);

                Mobs = {};
                Players = {};

                Height = BaseModel.Hitbox.Size.X/2 + (BaseModel.PrimaryPart.Position.Y-BaseModel.Hitbox.Position.Y);
                Drops = {};
            }
            for _,Value in ipairs(RegionPart:GetChildren()) do
                if not Value:IsA("Folder") then
                    NewRegion[Value.Name] = Value.Value
                else
                    local Quest = Value:FindFirstChild("Quest")
                    if Quest then
                        Quest = Quest.Value
                    end
                    NewRegion.Drops[Value.Name] = {
                        Quantity = Value:FindFirstChild("Quantity").Value;
                        Rate = Value:FindFirstChild("Rate").Value;
                        Type = Value:FindFirstChild("Type").Value;
                        Quest = Quest;
                    }
                    print(Value.Name, NewRegion.Drops[Value.Name])
                end
            end
            RegionPart:Destroy()
            return NewRegion
        end
    end
end

function MobService:SingleSpawn(RegionParams, Quantity)
    if Regions[RegionParams.Id] then
        RegionParams = Regions[RegionParams.Id]
    end

    if not RegionParams.Mobs then RegionParams.Mobs = {} end
    local InitParams = self:GetInitParams(RegionParams)

    if not Quantity then Quantity = 1 end
    for i = 1, Quantity do
        local Mob = self:SpawnMob(InitParams)
        RegionParams.Mobs[Mob.Id] = Mob
    end

    Regions[RegionParams.Id] = RegionParams
    print(Regions[RegionParams.Id], RegionParams)
    for i, v in pairs(Regions) do
        print(i, v)
    end
end

--- start function for AeroGameFramework, initializing local variables and loops
function MobService:Start()
    local BaselineHP = {
        ["1"] = function(level) return 45 * level + 205 end;
        ["9"] = function(level) return 75 * level + 155 end;
        ["26"] = function(level) return 95 * level + 120 end;
        ["30"] = function(level) return 135 * level + 75 end;
        ["32"] = function(level) return 255 * level + 40 end;
        ["46"] = function(level) return 300 * level + 150 end;
        ["51"] = function(level) return 400 * level - 690 end;
        ["56"] = function(level) return 500 * level - 1250 end;
        ["61"] = function(level) return 600 * level - 1850 end;
        ["66"] = function(level) return 700 * level - 2500 end;
        ["71"] = function(level) return 1000 * level - 6000 end;
        ["76"] = function(level) return 2000 * level - 13500 end;
        ["126"] = function(level) return 2000 * level - 13400 end;
        ["128"] = function(level) return 5000 * level - 51500 end;
        ["151"] = function(level) return 10000 * level - 127000 end;
        ["181"] = function(level) return 20000 * level - 307000 end;
    }
    
    local LevelMultipliers = {
        ["1"] = function() return 1 end;
        ["30"] = function() return 2 end;
        ["101"] = function(level) return 0.01 * math.floor(level^2/50) end;
        ["110"] = function(level) return 0.015 * math.floor(level^2/50) end;
        ["160"] = function(level) return 0.02 * math.floor(level^2/50) end;
    }


    --InitRegion
    --Initialize spawns
    for _,RegionPart in ipairs(workspace.Regions:GetChildren()) do
        local NewRegion = self:GenerateRegion(RegionPart)
        --initial spawn
        for i = 1, NewRegion.MaxLimit do
            local InitParams = self:GetInitParams(NewRegion)
            local Mob = self:SpawnMob(InitParams)

            NewRegion.Mobs[Mob.Id] = Mob
            -- table.insert(NewRegion.Mobs, Mob)
            -- print(i)
        end
        Regions[RegionPart.Name] = NewRegion
    end

    --- initialize packages for new players
    self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(Player)
        if Player then
            Packages[Player.UserId] = {}
            self.PlayerTimes[Player] = {}

            local RegionInventory = {}

            for RegionId, RegionData in pairs(Regions) do
                if RegionData.Drops then
                    RegionInventory[RegionData.Id] = {}
                    for DropName, DropData in pairs(RegionData.Drops) do
                        RegionInventory[RegionData.Id][DropName] = TableUtil.Copy(DropData); 
                    end
                end
            end


            RegionInventories[Player] = RegionInventory
        end
    end)

    local MobLivin = {}
    --connect client events
    self:ConnectClientEvent("BasicDamage", function(Player, MobId, Skill, t)
        if t == nil then Player:Kick("Fell out of sync: SayoError 303") return end

        local Blob = self.Services.PlayerService:GetPlayerData(Player)
        if Blob == nil then return end
        if MobLivin[MobId] == false then return end
        -- assert(Blob ~= nil, "MobService.BasicDamage | Could not get Player blob")

        local Mob = Mobs[MobId]
        if Mob == nil then print("Could not get mob from MobId") return end
        -- assert(Mob ~= nil, "MobService.BasicDamage | Could not get Mob from MobId")
        local SkillInfo
        if Skill ~= nil then
            SkillInfo = TableUtil.Copy(SkillCache:Get(Skill.LocalInfo.SkillId))
            -- check if player knows skill
            if not Blob.SkillInfo[Skill.LocalInfo.SkillId] then print("does not know skill") return end
        end
        
        --check distance
        if Player.Character == nil then return end
        local Distance = (Player.Character.PrimaryPart.Position-TableUtil.ToVector3(Mob.Position)).Magnitude

        --add Z model
        local Hitbox = Mob.Model:FindFirstChild("Hitbox")
        if Hitbox then
            Distance = Distance-(Hitbox.Size.Z/2)
        end

        if Distance > AttackRangeLibrary[Blob.Inventory[Blob.Equipment.PrimaryWeapon].ItemId] and Skill == nil then
            return
        elseif Skill ~= nil then
            if Distance > SkillInfo.LocalInfo.range+5 and SkillInfo.LocalInfo.range > SkillInfo.LocalInfo.range+5 then print("TF") return end
        end
        if self.Services.WeaponService.State[Player] == false then return end

        if Mob.State.can("aggro") then
            Mob.State.aggro(Player.Character)
        end
        local Damage = FormulasModule:HitDamage(Blob, Skill)

        if Mob.Stats.Stagger > 0 then Damage = Damage*0.25 end

        local dpscheck = self.Services.DamageService:CollectDamage(Player, Damage, t, MobId, Skill)
        if dpscheck then
            if Mob.Stats.Stagger > 0 then
                Mob.Stats.Stagger = math.clamp(Mob.Stats.Stagger-(Blob.Stats.ATK/4), 0, math.huge)
                local StaggerDisplay = Mob.Model:FindFirstChild("MicroHealth", true).Stagger
                if StaggerDisplay then
                    StaggerDisplay.Size = UDim2.new(math.clamp(Mob.Stats.Stagger/Mob.Stats.MaxStagger, 0, 1),
                    0, 0.4, 0)
                end
            end
    
            if Mob.DamagePool[Player] then
                Mob.DamagePool[Player] = math.clamp(Mob.DamagePool[Player]+Damage, 1, Mob.Stats.MaxHealth)
            else
                Mob.DamagePool[Player] = math.clamp(Damage, 1, Mob.Stats.MaxHealth)
            end
    
            local UpdatedHealth = Mob.Stats.Health-Damage
            Mob.Stats.Health = UpdatedHealth
    
            local HealthDisplay = Mob.Model:FindFirstChild("MicroHealth", true).Health
            if HealthDisplay then
                HealthDisplay.Size = UDim2.new(math.clamp(UpdatedHealth/Mob.Stats.MaxHealth, 0, 1),
                0, 0.4, 0)
            end
    
            Mobs[MobId].Stats.Health = UpdatedHealth
            Regions[Mob.RegionId].Mobs[MobId].Stats.Health = UpdatedHealth
            if UpdatedHealth <= 0 and MobLivin[MobId] then
                --YO HE DEAD
                MobLivin[MobId] = false
                self:MobSlain(Player, MobId)
            elseif MobLivin[MobId] == nil then
                MobLivin[MobId] = true
            end
        end
    end)

    self:ConnectClientEvent("ReflectHealth", function(Player, Health)
        local Humanoid = Player.Character:FindFirstChild("Humanoid")
        if Humanoid then
            if Health < Humanoid.Health and Health > 0 and Health < Humanoid.MaxHealth then
                Humanoid.Health = Health
            end
        end
    end)

    local CanUpdate1 = true
    local CanUpdate2 = true
    local CanUpdate3 = true
    local dt_sum = 0

    --handle all logic stuff
    --RunService.Stepped:Connect(function(time, dt)        
    local dt = 1/30
    local time = 0
    FastSpawn(function()
        while true do
            wait(dt)
            time = time+dt
            for RegionId, Region in pairs(Regions) do

                --timestamp mob server params
                local Actors = {}
                for i,v in pairs(Region.Mobs) do
                    local pvec = TableUtil.ToVector3(v.Position)
                    if pvec then
                        table.insert(Actors, pvec)
                    end
                end

                for i, v in pairs(Region.Mobs) do
                    v.Update(v, time, dt)
                    v.Others = TableUtil.Copy(Actors)
                    v.Brain:run(dt)
                    
                end

                local MobCount = 0
                for i, v in pairs(Region.Mobs) do
                    MobCount = MobCount+1
                end

                --spawn mobs
                Region.LastSpawn = Region.LastSpawn+dt
                if MobCount >= Region.MaxLimit then
                    Region.LastSpawn = 0
                end
                if Region.SpawnTime ~= math.huge then
                    if Region.LastSpawn > Region.RespawnTime and MobCount < Region.MaxLimit then
                        -- print(MobCount, Region.MaxLimit)
                        --create a mob
                        local InitParams = self:GetInitParams(Region)

                        local Mob = self:SpawnMob(InitParams)
                        -- table.insert(Region.Mobs, Mob)
                        Region.Mobs[Mob.Id] = Mob
                        Region.LastSpawn = 0
                    end
                end
            end
        end
    end)

    local FSMcurrent = {
        ["idle"] = 1;
        ["preparing"] = 2;
        ["walking"] = 3;
        ["attacking"] = 4;
        ["dizzy"] = 5;
    }

    while true do
        --package players
        -- print('prething')
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player.Character then
                if Player.Character:FindFirstChild("Humanoid") ~= nil then
                    PlayerRegions[Player] = {}
                    -- print("thing")
                    for RegionId, Region in pairs(Regions) do
                        -- print(RegionId)
                        table.insert(PlayerRegions[Player], RegionId)
                        local Character = Player.Character
                        local Humanoid = Character.Humanoid
                        
                        if Region.Players[Player.UserId] == true then
                            if Packages[Player.UserId] ~= nil then
                                -- print("H2")
                                Packages[Player.UserId].Time = time
                                for i, v in pairs(Region.Mobs) do

                                    local NewPack = {
                                        Id = v.Id;
                                        MobType = MobData.DeSerial[v.MobType];
                                        Position = v.Position;

                                        FSMcurrent = FSMcurrent[v.FSM.current];
                                        Target = v.Target;

                                        Stats = v.Stats;
                                        Time = v.Time;
                                        _CFrame = v._CFrame;
                                        AttackRange = v.AttackRange;
                                    }

                                    if v.TargetPos ~= nil then
                                        -- NewPack.TargetPos = v.TargetPos
                                        NewPack.TargetPos = {
                                            X = v.TargetPos.X,
                                            Y = v.TargetPos.Y,
                                            Z = v.TargetPos.Z
                                        };
                                    end
                                    table.insert(Packages[Player.UserId], NewPack)
                                end
                            end
                        end

                        -- Check if distance from Player to Center (+ outer region)
                        if Character.PrimaryPart ~= nil then
                            if (Character.PrimaryPart.Position-Region.Center).Magnitude-(Region.Center-Region.MinPos).Magnitude < 90 then
                                --player is close enough
                                Region.Players[Player.UserId] = true
                            elseif (Character.PrimaryPart.Position-Region.Center).Magnitude-(Region.Center-Region.MinPos).Magnitude > 130 then
                                Region.Players[Player.UserId] = false
                            end
                        end
                    end
                end
            end
        end

        wait(1/10)

        for _,Player in ipairs(Players:GetPlayers()) do
            if Packages[Player.UserId] ~= nil then
                Packages[Player.UserId] = {}
            end
        end
    end
end


function MobService:Init()
    self:RegisterClientEvent("PackageUpdate")
    self:RegisterClientEvent("BasicDamage")
    self:RegisterClientEvent("MobAttack")
    self:RegisterClientEvent("Indicator")
    self:RegisterClientEvent("DamagePlayer")
    self:RegisterClientEvent("MobDizzy")
    self:RegisterClientEvent("MobCenter")
    self:RegisterClientEvent("SpecialAttack")

    self:RegisterClientEvent("Stagger")
    self:RegisterClientEvent("Flyback")
    self:RegisterClientEvent("ReflectHealth")

    self.PlayerTimes = {}

    -- self:RegisterClientEvent("DestroyMob")
    
    AssetService = self.Services.AssetService
    PingService = self.Services.PingService
    CalculateNextPosition = self.Modules.CalculateNextPosition

	SkillCache = self.Shared.Cache:Get("SkillCache")
    FastSpawn = self.Shared.FastSpawn
    TableUtil = self.Shared.TableUtil
    MobData = self.Shared.MobData
    MobRewards = self.Shared.MobRewards
    FSM = self.Shared.FSM
    BehaviorTree2 = self.Shared.BehaviorTree2
    AnimationPlayer = self.Shared.AnimationPlayer
    AnimationLibrary = self.Shared.Cache:Get("AnimationLibrary")
    AttackRangeLibrary = self.Shared.Cache:Get("AttackRangeLibrary")
    Boxcast = self.Shared.Boxcast
    repr = self.Shared.repr
    FormulasModule = self.Shared.FormulasModule
    Maid = self.Shared.Maid
    GlobalMath = self.Shared.GlobalMath
end


return MobService