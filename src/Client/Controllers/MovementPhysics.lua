-- Movement Physics
-- oniich_n
-- January 4, 2019

--[[


--]]



local MovementPhysics = {}

MovementPhysics.__aeroPreventInit = true
MovementPhysics.__aeroPreventStart = true

local CombatController
function MovementPhysics:Start()
	--[[
	J Jackson (Jon) [EchoZenkai]
	13:25 30/12/2018 (GMT)

	🎉🎉🎉 Happy new year! 🎉🎉🎉


	PUT THIS IN StarterGui / StarterCharacterScripts

	Shoot me (EchoZenkai) a PM if you're having any issues!
--]]
	local Player = game.Players.LocalPlayer
	self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(character)
		local MaximumDegrees = 35

		local waist = character:WaitForChild("UpperTorso"):WaitForChild("Waist")
		local root = character:WaitForChild("LowerTorso"):WaitForChild("Root")
		local baseCF = waist.C0
		local rootCF = root.C0
		game:GetService("RunService"):BindToRenderStep("MovementThing",Enum.RenderPriority.Last.Value,function()
			if character.PrimaryPart and character:FindFirstChild("Humanoid") then
				local hrp = character.PrimaryPart

				local pos = (hrp.CFrame * CFrame.new(0,-2,0)).p
				local nor = Vector3.new() -- can set this up if you want this to apply to wall walking etc. Use raycasts and get the normal vector
				local cross = Vector3.new(0, 1, 0):Cross(nor)
				local angle =  math.asin(cross.magnitude)

				local hum = character.Humanoid

				local desiredCF = CFrame.new(pos) * CFrame.fromAxisAngle(cross.magnitude == 0 and Vector3.new(1, 0, 0) or cross.unit, angle) * CFrame.new(Vector3.new(), hum.MoveDirection)
				local turnThing = desiredCF.lookVector:Dot(hrp.CFrame.rightVector)

					local turnVal = (0.125) * (hrp.Velocity.magnitude)
					if math.abs(turnThing) > 0.5 and CombatController.IsAttacking == false and hum.WalkSpeed > 0 then
						local Deg = math.rad(math.clamp(math.deg(turnThing * -turnVal),-MaximumDegrees,MaximumDegrees))
						root.C0 = root.C0:lerp(rootCF * CFrame.Angles(0, 0,Deg), 0.0125)
						waist.C0 = waist.C0:lerp(baseCF * CFrame.Angles(0, 0, Deg), 0.0125)
					else
						root.C0 = root.C0:lerp(rootCF, 0.125)
						waist.C0 = waist.C0:lerp(baseCF, 0.125)
					end

			end
		end)
	end)
end


function MovementPhysics:Init()
	CombatController = self.Controllers.Combat
end


return MovementPhysics