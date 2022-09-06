-- State Controller
-- Username
-- August 26, 2019



local StateController = {__aeroOrder = 4}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jumpTweakerApi = require(ReplicatedStorage:WaitForChild("JumpTweakerAPI"))

local AnimationList = {
    ["Idle"]		= 1763006620;
	["Run"]		    = 4800876834;--4204759596;
	-- ["Sprint"]		= 2530495991;
    ["Jump"]		= 3595519447;
    ["Jump2"]       = 4812473866;
	["Fall"]		= 4816708968;
	["Climb"]		= 507765644;
	["Sit"]			= 507768133;
	["Evade"]		= 3116250186;--1813862674;
	["EvadeReverse"] = 3139088284;

	["Flyback"]		= 2163463697;
	["Stagger"]		= 2166941495;

	["Landing"]		= 3251596487;
}

function StateController:Start()
    local StateMaid = Maid.new()
    local LastEvent = 0
    CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        StateMaid:DoCleaning()
        local Humanoid = Character:WaitForChild("Humanoid")
        local CurrentHealth = Humanoid.Health
        StateMaid:GiveTask(Humanoid.HealthChanged:Connect(function(Health)
            if CurrentHealth > Health then
                self.CombatTimer = 0
                self.CombatCheck = self.CombatTimer < 7.5
            end
            CurrentHealth = Health
        end))

        StateMaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
            self.CombatTimer = self.CombatTimer+dt
            self.CombatCheck = self.CombatTimer < 7.5
            -- print(self.CombatCheck)
        end))

        local Blob = self.Controllers.DataBlob.Blob
        if not Blob then
            self.Controllers.DataBlob:ForceUpdate()
            Blob = self.Controllers.DataBlob.Blob
        end

        Keyboard = self.Controllers.UserInput:Get("Keyboard")
        LastEvent = 0
        local Humanoid = Character:WaitForChild("Humanoid")
        
        self.StateAnimations = AnimationPlayer.new(Humanoid)
        for i, v in pairs(AnimationList) do
            self.StateAnimations:AddAnimation(i, v)
        end

        self.StateAnimations:AddAnimation(Blob.Stats.Class .. "Idle", AnimationLibrary[Blob.Stats.Class .. "Idle"])
        self.StateAnimations:AddAnimation(Blob.Stats.Class .. "Run", AnimationLibrary[Blob.Stats.Class .. "Run"])

        --create new state machine
        self.CharacterState = FSM.create({
            initial = "idle",
            events = {
                {
                    name = "walk",
                    from = {"idle", "postattack", "postevade", "postcast", "between"},
                    to = "walking"
                },
                {
                    name = "jump",
                    from = {"idle", "postattack", "postevade", "postcast", "walking", "airborne", "falling"},
                    to = "airborne"
                },
                {
                    name = "fall",
                    from = {"airborne", "walking", "idle", "postattack", "postevade", "postcast", "falling", "landing"},
                    to = "falling"
                },
                {
                    name = "land",
                    from = {"falling", "airborne"},
                    to = "landing"
                },
                {
                    name = "attack",
                    from = {"idle", "postattack", "postevade", "postcast", "walking", "between"},
                    to = "attacking"
                },
                {
                    name = "attack_end",
                    from = "attacking",
                    to = "postattack"
                },

                {
                    name = "cast",
                    from = {"idle", "postattack", "postevade", "postcast", "walking", "between"},
                    to = "casting"
                },
                {
                    name = "cast_end",
                    from = "casting",
                    to = "postcast"
                },

                {
                    name = "evade",
                    from = {"idle", "walking", "postattack", "postevade", "postcast", "between"},
                    to = "evading"
                },
                {
                    name = "evade_end",
                    from = "evading",
                    to = "postevade"
                },


                {
                    name = "stop",
                    from = {"walking", "landing", "postattack", "postevade", "postcast", "between"},
                    to = "idle"
                },

                {
                    name = "reset",
                    from = "*",
                    to = "idle"
                },

                {
                    name = "btwn",
                    from = "*",
                    to = "between"
                },

                {
                    name = "message",
                    from = "*",
                    to = "inmessage"
                },
                
                {
                    name = "message_end",
                    from = "inmessage",
                    to = "idle"
                }
            },
            
            callbacks = {
                on_enter_state = function(this, event, from, to)
                    LastEvent = 0
                end,

                on_enter_idle = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()
                    if self.Controllers.WeaponController.WeaponState.current == "unequipped" then
                        self.StateAnimations:PlayTrack("Idle", 0.15)
                    else
                        self.StateAnimations:PlayTrack(Blob.Stats.Class .. "Idle", 0.15)
                    end
                end,

                on_enter_walking = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()
                    if self.Controllers.WeaponController.WeaponState.current == "unequipped" then
                        self.StateAnimations:PlayTrack("Run", 0.25)
                    else
                        self.StateAnimations:PlayTrack(Blob.Stats.Class .. "Run", 0.25)
                    end
                end,

                on_enter_airborne = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()

                    self.JumpCounter = self.JumpCounter + 1
                    if self.JumpCounter == 1 then
                        self.StateAnimations:PlayTrack("Jump")
                    elseif self.JumpCounter > 1 then
                        self.JumpCounter = 0
                        self.StateAnimations:PlayTrack("Jump2")
                    end
                end,
                on_enter_falling = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()
                    --add multiple jump animations later

                    if not self.StateAnimations:GetTrack("Jump").IsPlaying
                    and not self.StateAnimations:GetTrack("Jump2").IsPlaying then

                        self.StateAnimations:PlayTrack("Fall")
                    end
                end,
                on_enter_landing = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()
                    --add multiple jump animations later
                    self.JumpCounter = 0
                    -- self.Player.Character.Humanoid.WalkSpeed = 0
                    self.StateAnimations:PlayTrack("Landing")
		            jumpTweakerApi:SetCharacterBehavior(Character, "JumpingEnabled", false)
                    wait(self.StateAnimations:GetTrack("Landing").Length)
                    this.btwn()
                    if Humanoid.MoveDirection.Magnitude > 0 then
                        this.walk()
                    else
                        this.stop()
                    end
                    -- self.Player.Character.Humanoid.WalkSpeed = 22

		            jumpTweakerApi:SetCharacterBehavior(Character, "JumpingEnabled", true)
                end,

                on_enter_attacking = function(this, event, from, to)
                    -- print("attacking!!")
                    self.StateAnimations:StopAllTracks()
                end,
                on_enter_postattack = function(this, event, from, to)
                    -- print("done attacking!!")
                    if Humanoid.MoveDirection.Magnitude > 0 then
                        if self.CharacterState.can("walk") then
                            self.CharacterState.walk()
                        end
                    elseif Humanoid.MoveDirection.Magnitude <= 0 then
                        if self.CharacterState.can("stop") then
                            self.CharacterState.stop()
                        end
                    end
                end,

                on_enter_postcast = function(this, event, from, to)
                    if Humanoid.MoveDirection.Magnitude > 0 then
                        if self.CharacterState.can("walk") then
                            self.CharacterState.walk()
                        end
                    elseif Humanoid.MoveDirection.Magnitude <= 0 then
                        if self.CharacterState.can("stop") then
                            self.CharacterState.stop()
                        end
                    end
                end,

                on_enter_evading = function(this, event, from, to)
                    self.StateAnimations:StopAllTracks()
                    if Keyboard:IsDown(Enum.KeyCode.D) and not Keyboard:IsDown(Enum.KeyCode.A) then
                        self.StateAnimations:PlayTrack("EvadeReverse")
                    elseif Keyboard:IsDown(Enum.KeyCode.W) or Keyboard:IsDown(Enum.KeyCode.A) then
                        self.StateAnimations:PlayTrack("Evade")
                    else
                        self.StateAnimations:PlayTrack("EvadeReverse")
                    end

                    Character.PrimaryPart:FindFirstChild("Evade"):Play()
                end,
                on_enter_postevade = function(this, event, from, to)
                    if Humanoid.MoveDirection.Magnitude > 0 then
                        if self.CharacterState.can("walk") then
                            self.CharacterState.walk()
                        end
                    elseif Humanoid.MoveDirection.Magnitude <= 0 then
                        if self.CharacterState.can("stop") then
                            self.CharacterState.stop()
                        end
                    end
                end
            }
        })

        Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
            if Humanoid.MoveDirection.Magnitude > 0 then
                if self.CharacterState.can("walk") then
                    self.CharacterState.walk()
                end
            elseif Humanoid.MoveDirection.Magnitude <= 0 then
                if self.CharacterState.can("stop") then
                    self.CharacterState.stop()
                end
            end
        end)

        self.Controllers.WeaponController:ConnectEvent("ChangeEquip", function(state)
            if state then
                if self.CharacterState.current == "walking" then
                    self.StateAnimations:StopAllTracks()
                    self.StateAnimations:PlayTrack(Blob.Stats.Class .. "Run")
                elseif self.CharacterState.current == "idle" then
                    self.StateAnimations:StopAllTracks()
                    self.StateAnimations:PlayTrack(Blob.Stats.Class .. "Idle")
                end
            else
                if self.CharacterState.current == "walking" then
                    self.StateAnimations:StopAllTracks()
                    self.StateAnimations:PlayTrack("Run")
                elseif self.CharacterState.current == "idle" then
                    self.StateAnimations:StopAllTracks()
                    self.StateAnimations:PlayTrack("Idle")
                end
            end
        end)

        -- Humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        --     if Humanoid.Jump then
        --         if self.CharacterState.can("jump") then
        --             self.CharacterState.jump()
        --         end
        --     end
        -- end)

        Humanoid.StateChanged:Connect(function(OldState, NewState)
            if NewState == Enum.HumanoidStateType.Landed then
                if self.CharacterState.can("land") then
                    self.CharacterState.land()
                end
            elseif NewState == Enum.HumanoidStateType.Freefall then
                if self.CharacterState.can("fall") then
            
                    if self.StateAnimations:GetTrack("Jump").IsPlaying then
                        self.StateAnimations:GetTrack("Jump").Stopped:Wait()
                    end

                    if self.StateAnimations:GetTrack("Jump2").IsPlaying then
                        self.StateAnimations:GetTrack("Jump2").Stopped:Wait()
                        
                    end

                    self.CharacterState.fall()
                end
            elseif NewState == Enum.HumanoidStateType.Jumping then
                if self.CharacterState.can("jump") then
                    self.CharacterState.jump()
                end
            end
        end)

        local currenthealth = Humanoid.Health
        Humanoid.HealthChanged:Connect(function(health)
            if currenthealth > health then
                if health > 0 then
                    self.CombatCheck = 0
                end
            end

            currenthealth = health
        end)
    end)
end


function StateController:Init()
    self.JumpCounter = 0
    self.CombatCheck = false
    self.CombatTimer = 10
    CharacterController = self.Controllers.Character
    Maid = self.Shared.Maid
    FSM = self.Shared.FSM
    AnimationPlayer = self.Shared.AnimationPlayer
    AnimationLibrary = self.Shared.Cache:Get("AnimationLibrary")

    self:RegisterEvent("LoadedState")
end


return StateController