-- Nodes Module
-- oniich_n
-- August 17, 2019

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BehaviorTree2 = require(ReplicatedStorage.Aero.Shared:FindFirstChild("BehaviorTree2"))
local AttackRangeLibrary = require(ReplicatedStorage.Aero.Shared:FindFirstChild("Cache")):Get("AttackRangeLibrary")
local CalculateNextPosition = require(script.Parent:FindFirstChild("CalculateNextPosition"))

local NodesModule = {
    TestNode = BehaviorTree2.Task:new({
        start = function(task, object)
            object.i = 0
        end,
        run = function(task, object)
            object.i = object.i+1
            if object.i == 5 then
                print("completed")
                task:success()
                return
            end

            task:running()
        end
    });

    TargetCheck = BehaviorTree2.Task:new({
        run = function(task, object, dt)
            if object.Target ~= nil then
                local Humanoid = object.Target:FindFirstChild("Humanoid")
                if Humanoid ~= nil then
                    if Humanoid.Health > 0 then
                        task:success()
                        return
                    end
                end
            end
            task:fail()
        end
    });

    ChillCheck = BehaviorTree2.Task:new({
        run = function(task, object, dt)

            --check if target exists
            if object.Target == nil then
                --chill out
                if object.State.can("chill") then
                    object.State.chill()
                end
                task:fail()
                return
            end

            --check if in bounds
            if object.Position.X < object.MinPos.X-45 or
            object.Position.X > object.MaxPos.X+45 or
            object.Position.Z < object.MinPos.Z-45 or
            object.Position.Z > object.MaxPos.Z+45 then
                if object.State.can("chill") then
                    object.State.chill()
                end
                task:fail()
                return
            end

            task:success()
            return
        end
    });

    DizzyCheck = BehaviorTree2.Task:new({
        run = function(task, object, dt)
            if object.FSM.current == "dizzy" then
                task:fail()
                return
            end
            task:success()
        end
    });


    MoveTo = BehaviorTree2.Task:new({
        start = function(task, object)
            if object.FSM.can("walk") then object.FSM.walk() end
        end,
        run = function(task, object, dt)
            if object.Target == nil then task:fail() return end
            if typeof(object.Target) == "Instance" then
                if object.Target:IsA("Model") then
                    if object.Target.PrimaryPart ~= nil then
                        object.TargetPos = object.Target.PrimaryPart.Position
                    end
                elseif object.Target:IsA("BasePart") then
                    object.TargetPos = object.Target.Position
                end
            elseif typeof(object.Target) == "Vector3" then
                object.TargetPos = object.Target
            end

            if object.TargetPos.X < object.MinPos.X-45 or
            object.TargetPos.X > object.MaxPos.X+45 or
            object.TargetPos.Z < object.MinPos.Z-45 or
            object.TargetPos.Z > object.MaxPos.Z+45 then
                if object.State.can("chill") then
                    object.State.chill()
                end
                task:fail()
                return
            end

            local adjustedvector = object.TargetPos
            if object.TargetPos ~= nil then
                adjustedvector = Vector3.new(
                    object.TargetPos.X,
                    object.Position.Y,
                    object.TargetPos.Z
                )
            end

            local nvec = Vector3.new(object.Position.X, object.Position.Y, object.Position.Z)
            if (nvec-adjustedvector).Magnitude > (object.AttackRange+object._ZOffset)/2 then
                -- print(object.Others)
                local pos, cf = CalculateNextPosition(nvec, adjustedvector, object.Stats.Height, object.Stats.Speed, dt, object.Others)
                pos.Y = math.clamp(pos.Y, object.MinHeight, object.MaxHeight)
                object.Position = pos
                object._CFrame = cf                
                task:running()
                return
            else
                if not object._DelayCounter then object._DelayCounter = 0 end
                object._DelayCounter = object._DelayCounter + dt
                if object._DelayCounter < 0.35 then
                    task:running()
                    return
                end
                task:success()
                return
            end
            task:fail()
        end,
        finish = function(task, object)
            object._DelayCounter = 0
        end
    });

    BasicAttack = BehaviorTree2.Task:new({
        start = function(task, object)
            object._GapCloser = false

            object._CastTimes = {}

            if object.Animations:GetTrack("Attack") ~= nil then
                local Track = object.Animations:GetTrack("Attack")
                for i = 1, 20 do
                    local success, message = pcall(function()
                        local t = Track:GetTimeOfKeyframe("Cast" .. tostring(i))
                        -- local frame = t*60
                        if t then table.insert(object._CastTimes, t+object.Time) end
                    end)
                    if not success then
                        break
                    end
                end
                
                object._ActionFinish = object.Time+Track.Length
            end
        end,
        run = function(task, object)
            if object.Target == nil then task:fail() return end
            if typeof(object.Target) == "Instance" then
                if object.Target:IsA("Model") then
                    if object.Target.PrimaryPart ~= nil then
                        object.TargetPos = object.Target.PrimaryPart.Position
                    end
                elseif object.Target:IsA("BasePart") then
                    object.TargetPos = object.Target.Position
                end
            elseif typeof(object.Target) == "Vector3" then
                object.TargetPos = object.Target
            end
            
            if object.Time >= object._ActionFinish then
                task:success()
                return
            end
            task:running()
        end,

        finish = function(task, object)
            object._CastTimes = {}
        end
    });

    PreAttack = BehaviorTree2.Task:new({
        start = function(task, object)
            object._Cooldown = math.random(40, 75)/100
            if object.Animations:GetTrack("Attack") ~= nil then
                local Track = object.Animations:GetTrack("Attack")
                local t
                pcall(function()
                    t = Track:GetTimeOfKeyframe("Cast1") 
                end)
                if t then object._First = t end
                -- print(object._First)
            end
            object._Preparing = true

        end,

        run = function(task, object, dt)
            if object._Cooldown > 0 then
                object._Cooldown = object._Cooldown-dt
                task:running()
                return
            end
            task:success()
        end,

        finish = function(task, object)
            object._Preparing = false
        end
    });

    BasicCooldown = BehaviorTree2.Task:new({
        start = function(task, object)
            object._Cooldown = math.random(1, 2)
        end,

        run = function(task, object, dt)
            if object._Cooldown > 0 then
                object._Cooldown = object._Cooldown-dt
                task:running()
                return
            end
            task:success()
        end
    })
}


return NodesModule