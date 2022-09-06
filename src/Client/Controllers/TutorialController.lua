-- TutorialController
-- oniich_n
-- June 2, 2019



local TutorialController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

function TutorialController:Start()
	if self.IsTutorial == nil then return end
	local Sequences = {
		["DoubleJump"] = {
			lessThan = true;
			Z = -128;
			Read = false;
			MessageInfo = {
				Id = "tutorial_DoubleJump";
				Pages = {
					{
						Title = "Movement Tutorial";
						Image = 1237933259;
						Boxes = {
							{
								Subtitle = "Double Jumping";
                            	SubtitleColor = Color3.fromRGB(255, 239, 147);
								Description = "In this game, you can jump twice in a row. Use it to achieve new heights!";
							},

							{
								Subtitle = "Dashing";
								SubtitleColor = Color3.fromRGB(59, 248, 217);
								Description = "Evading is an important tool in combat and movement, allowing you to quickly change positions.";
							}
						}
					}
				}
			}
		};

		["tutorialBoss"] = {
			lessThan = true;
			Z = -500;
			singleSpawn = true;
			Read = false;
		};
	}

	local function LoadController(Character)
		self.Maid:DoCleaning()
		local HRP = Character:WaitForChild("HumanoidRootPart")
		self.Maid:GiveTask(RunService.Heartbeat:Connect(function()
			-- print(Character.PrimaryPart.Position.Z)
			for Sequence, Data in pairs(Sequences) do
				
				if not Data.Read then
					if (Data.lessThan and HRP.Position.Z <= Data.Z)
					or (not Data.lessThan and HRP.Position >= Data.Z)  then
						if Data.singleSpawn then
							Data.Read = true
							self.Services.SSpawnService.SpawnRegion:Fire(Sequence)
						else	
							Data.Read = true
							self.Controllers.MessageController:FireEvent("DisplayMessage", Data.MessageInfo)
						end
					end
				end
			end
		end))
		print("Loaded TutorialController")
	end

	self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", LoadController)
end


function TutorialController:Init()
    self.IsTutorial = ReplicatedStorage:WaitForChild("IsTutorial", 1)
	Maid = self.Shared.Maid
	self.Maid = Maid.new()
end


return TutorialController