-- Music Controller
-- Username
-- September 7, 2019

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MusicController = {}

function MusicController:Start()
    local Music = game:GetService("ReplicatedStorage"):WaitForChild("Music"):Clone()
    Music.Parent = workspace
    self.InCombat = false

    local LastCombat = 0
    local MusicMaid = self.Shared.Maid.new()

    local MusicFSM = self.Shared.FSM.create({
        initial = "passive",
        events = {
            {
                name = "activate",
                from = "passive",
                to = "active"
            },
            {
                name = "deactivate",
                from = "active",
                to = "passive"
            }
        },

        callbacks = {
            on_enter_active = function()
                Music.Battle.TimePosition = 0
                Music.Battle.Volume = 0.37
                Music.Overworld.Volume = 0
                Music.Village.Volume = 0
                wait(0.1)
                Music.Battle:Play()
            end,

            on_leave_active = function()
                TweenService:Create(Music.Battle, TweenInfo.new(0.65), {Volume = 0}):Play()
                delay(0.66, function()    
                    if Music.Battle.Volume <= 0 then
                        Music.Battle.Playing = false
                    end
                end)
                if self.Controllers.ZoneController.IsSafe then
                    TweenService:Create(Music.Village, TweenInfo.new(0.65), {Volume = 0.35}):Play()
                else
                    TweenService:Create(Music.Overworld, TweenInfo.new(0.65), {Volume = 0}):Play()
                end
            end
        }
    })

    self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)

        if not Music.Village.Playing then Music.Village.Playing = true end
        if not Music.Overworld.Playing then Music.Overworld.Playing = true end
        -- if not Music.Battle.Playing then Music.Battle.Playing = true end

        if MusicMaid then MusicMaid:DoCleaning() end

        local initcombat = false

        MusicMaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
            --check last time damage dealt or damage taken
            -- print(Music.Battle.TimePosition)

            if not self.Controllers.DataBlob.Options["Music"] then
                for i, v in ipairs(Music:GetChildren()) do
                    if v:IsA("Sound") then 
                        if v.Volume > 0 then
                            v.Volume = math.clamp(v.Volume - dt, 0, 1)
                        end
                    end
                end
                return
            end

            if self.Controllers.StateController.CombatCheck then
                if MusicFSM.can("activate") then
                    MusicFSM.activate()
                elseif MusicFSM.current == "active" then
                    if Music.Battle.TimePosition >= 163.65 then 
                        print("LOOP")
                        Music.Battle.TimePosition = 0.45
                    end
                end
            else
                if MusicFSM.can("deactivate") then
                    MusicFSM.deactivate()
                end
                Music.Battle.Volume = math.clamp(Music.Battle.Volume-(dt/4), 0, 1)
            end
            
            

            if Music.Battle.Volume > 0.3 then return end

            if self.Controllers.ZoneController.IsSafe then
                Music.Village.Volume = math.clamp(Music.Village.Volume+(dt/5), 0, 0.35)
                Music.Overworld.Volume = math.clamp(Music.Overworld.Volume-(dt/4), 0, 0.35)
            else
                Music.Village.Volume = math.clamp(Music.Village.Volume-(dt/5), 0, 0.35)
                Music.Overworld.Volume = math.clamp(Music.Overworld.Volume+(dt/5), 0, 0.35)
            end
        end))
    end)
end


function MusicController:Init()
    self:RegisterEvent("FadeTracks")
end


return MusicController