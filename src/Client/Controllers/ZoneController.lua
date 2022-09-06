-- Zone Controller
-- oniich_n
-- August 5, 2019



local ZoneController = {}

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

function ZoneController:Start()
    CharacterController:ConnectEvent("CHARACTER_DIED_EVENT", function()
        self.Maid:DoCleaning()
    end)

    CharacterController:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        --crate a loop for all the parts
        local IsDisplay = false
        local Zones = self.Services.ZoneService:GetZones()
        if Zones == nil then print("Could not get Zones") return end
        for i, Zone in pairs(Zones) do
            self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
                if self.Zone ~= Zone.Name then
                    local pos = Character.PrimaryPart.Position
                    if pos.X < Zone.Max.X and pos.X > Zone.Min.X and pos.Z <= Zone.Max.Z and pos.Z > Zone.Min.Z then
                        if IsDisplay then return end
                        IsDisplay = true
                        self.Zone = Zone.Name
    
                        if Zone.Safe then
                            self.IsSafe = true
                        else
                            self.IsSafe = false
                            -- self:FireEvent("DangerZone")
                        end

                        self.Services.ZoneService.ZoneChange:Fire(Zone.Name)
    
                        local SrcNotif = ReplicatedStorage.Assets.Interface:FindFirstChild("ZoneEnter")
                        assert(SrcNotif ~= nil, "ZoneController | Could not find SrcNotif")
                        local NewNotif = SrcNotif:Clone()
                        local Main = NewNotif:FindFirstChild("Main")
                        local ZoneText = NewNotif:FindFirstChild("Zone", true)
                        local Title = NewNotif:FindFirstChild("Title", true)
                        local Bar = Title.Bar
    
                        local TweenColor = Color3.fromRGB(165, 255, 165)
                        if not self.IsSafe then
                            TweenColor = Color3.fromRGB(255, 166, 166)
                        end
    
                        Bar.Size = UDim2.new(0,0,0,1)
    
                        ZoneText.Text = self.Zone
                        ZoneText.Position = UDim2.new(0,0,0,0)
                        ZoneText.TextTransparency = 1
                        ZoneText.TextStrokeTransparency = 1
    
                        Title.TextTransparency = 1
                        Title.TextStrokeTransparency = 1
    
                        NewNotif.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                        Debris:AddItem(NewNotif, 8)
    
                        local TI = TweenInfo.new(
                            1,
                            Enum.EasingStyle.Quint,
                            Enum.EasingDirection.Out
                        )
                        local TI2 = TweenInfo.new(
                            1,
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        )

    
                        FastSpawn(function()
                            Main:TweenPosition(UDim2.new(0.5, 0, 0.15, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 1, true)
                            wait(0.2)
                            TweenService:Create(Title, TI, {
                                TextTransparency = 0;
                                TextStrokeTransparency = 0.2;
                            }):Play()
    
                            TweenService:Create(Bar, TI, {
                                Size = UDim2.new(1, 0, 0, 1);
                            }):Play()
                            
                            

                            wait(0.1)
    
                            TweenService:Create(ZoneText, TI, {
                                TextColor3 = TweenColor;
                                TextTransparency = 0;
                                TextStrokeTransparency = 0.2;
                                Position = UDim2.new(0,0,1,0);
                            }):Play()
    
                            delay(2, function()
                                TweenService:Create(Title, TI2, {
                                    TextTransparency = 1;
                                    TextStrokeTransparency = 1;
                                }):Play()
    
                                TweenService:Create(Bar, TI2, {
                                    Size = UDim2.new(0, 0, 0, 1);
                                }):Play()
    
                                TweenService:Create(ZoneText, TI2, {
                                    -- TextColor3 = TweenColor;
                                    TextTransparency = 1;
                                    TextStrokeTransparency = 1;
                                    Position = UDim2.new(0,0,0,0)
                                }):Play()
                                wait(0.8)
                                Main.Position = UDim2.new(0.5, 0, 0, 0)
                                IsDisplay = false
                            end)
                        end)
    
                        print("Entered zone:", self.Zone)
                    end
                end
            end))
        end
    end)
end


function ZoneController:Init()
    self.IsSafe = false
    self.Zone = "none"
	self:RegisterEvent("DangerZone")

    CharacterController = self.Controllers.Character
    
    FastSpawn = self.Shared.FastSpawn
    Maid = self.Shared.Maid
    self.Maid = Maid.new()
end


return ZoneController