local State = {}
State.__index = State

State.Id = "passive"

function State:new()
	local s = {}
	setmetatable(s, State)
	return s
end

function State:Enter(EnterParams)
	-- print(EnterParams.Mob._Params._Id .. " entered passive state")
end


function State:Update(dt, Mob)
	if Mob._LastDecision >= math.random(10, 12) then
		Mob._LastDecision = 0

		local fray = Ray.new(Mob._Params._Position+Vector3.new(0,2,0), Vector3.new(0, -10, 0))
		local part, rpos, norm, material = workspace:FindPartOnRayWithIgnoreList(
			fray, {
				workspace.Mobs,
				workspace.Characters,
				workspace.Regions,
				workspace.Zones,
				workspace.Foliage, 
				workspace.Trash
			}
		)

		local newpos = Vector3.new(
			math.clamp(Mob._Params._Position.X+math.random(-30,30), Mob._Params._MinPos.X, Mob._Params._MaxPos.X),
			rpos.Y + Mob._Params._Height,
			math.clamp(Mob._Params._Position.Z+math.random(-30,30), Mob._Params._MinPos.Z, Mob._Params._MaxPos.Z)
		)

		-- print(rpos.Y + Mob._Params._Height)

		Mob._Params._vCF = CFrame.new(
			Mob._Params._Position,
			newpos
		)
		Mob._PassivePos = newpos
		Mob._PassiveStartPos = Mob._Params._Position
		Mob._PassiveTime = (Mob._Params._Position-newpos).magnitude/Mob._Params._Speed
		Mob._PassiveDt = 0
	end

	if Mob._PassivePos ~= nil and Mob._PassiveStartPos ~= nil then
		-- print("1")
		-- print((Mob._Params._vCF.p-Mob._PassivePos).magnitude)
		if (Mob._Params._vCF.p-Mob._PassivePos).magnitude > 1 then
			Mob._PassiveDt = Mob._PassiveDt+dt
			-- print("2")

			Mob._Params._Position = Mob._PassiveStartPos:lerp(Mob._PassivePos, Mob._PassiveDt/Mob._PassiveTime)

			local fray = Ray.new(Mob._Params._Position+Vector3.new(0,2,0), Vector3.new(0, -10, 0))
			local part, rpos, norm, material = workspace:FindPartOnRayWithIgnoreList(
				fray, {
					workspace.Mobs,
					workspace.Characters,
					workspace.Regions,
					workspace.Zones,
					workspace.Foliage, 
					workspace.Trash
				}
			)

			Mob._Params._Position = Vector3.new(
				Mob._Params._Position.X,
				rpos.Y + Mob._Params._Height,
				Mob._Params._Position.Z
			)

			local vCFe = Vector3.new(
				Mob._PassivePos.X,
				rpos.Y + Mob._Params._Height,
				Mob._PassivePos.Z
			)

			Mob._Params._vCF = CFrame.new(Mob._Params._Position, vCFe)
		else
			local fray = Ray.new(Mob._Params._Position+Vector3.new(0,2,0), Vector3.new(0, -10, 0))
			local part, rpos, norm, material = workspace:FindPartOnRayWithIgnoreList(
				fray, {
					workspace.Mobs,
					workspace.Characters,
					workspace.Regions,
					workspace.Zones,
					workspace.Foliage, 
					workspace.Trash
				}
			)

			Mob._Params._Position = Vector3.new(
				Mob._Params._Position.X,
				rpos.Y + Mob._Params._Height,
				Mob._Params._Position.Z
			)

			local vCFe = Vector3.new(
				Mob._PassivePos.X,
				rpos.Y + Mob._Params._Height,
				Mob._PassivePos.Z
			)

			Mob._Params._vCF = CFrame.new(Mob._Params._Position, Mob._PassivePos)
		end
	end


	if Mob._Params._Health < Mob._Params._MaxHealth then
		-- print('now healing')
		Mob._Params._Health = math.clamp(Mob._Params._Health+(dt*5), 1, Mob._Params._MaxHealth)
		-- Mob._HUD:FindFirstChild("HealthBar", true).Size = UDim2.new(Mob._Params._Health/Mob._Params._MaxHealth, 0, 1, 0)
	end
end

function State:Exit()
end

return State