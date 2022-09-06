local PlayerService = game:GetService("Players")

local State = {}
State.__index = State

State.Id = "active"

function State:new()
	local s = {}
	setmetatable(s, State)
	return s
end

function AggroSort(a, b)
	if a.AggroScore < b.AggroScore then
		return true
	else
		return false
	end
end

function State:Enter(EnterParams)
	print(EnterParams.Mob._Params._Id .. " entered active state")
end

function State:Update(dt, Mob)
	--update AggroScores and select targets
		--remove missing players
		--sort scores
		--select top pick as target
	for i, v in pairs(Mob._AggroScores) do
		if PlayerService:GetPlayerByUserId(v.UserId) == nil then
			table.remove(Mob._AggroScores, i)
		else
			v.AggroScore = math.clamp(v.AggroScore-dt, 0, 999)
			-- print(v.UserId, v.AggroScore)
			if v.AggroScore <= 0 then
				-- print('removed aggro score', v.Userid)
				-- table.remove(Mob._AggroScores, i)
			end
		end
	end
	if #Mob._AggroScores > 0 then
		local Player = nil
		if #Mob._AggroScores == 1 then
			Player = PlayerService:GetPlayerByUserId(Mob._AggroScores[1].UserId)
		else
			table.sort(Mob._AggroScores, AggroSort)
			Player = Mob._AggroScores[#Mob._AggroScores]
		end
		if Player then
			if Player.Character then
				Mob._Target = Player.Character
			else
				table.remove(Mob._AggroScores, #Mob._AggroScores)
			end
		end
	elseif #Mob._AggroScores == 0 then
		-- print('OHNO')
		Mob._State:Change("passive", {Mob = Mob})
		Mob._Target = nil
	end
	--pathfinding updates
	if #Mob._Pathfinding.PathWaypoints > 0 then
		Mob._Pathfinding.t = Mob._Pathfinding.t+dt
		-- print("i+1:", Mob._Pathfinding.i+1, "i:", Mob._Pathfinding.i)
		local maxt = (Mob._Pathfinding.PathWaypoints[math.clamp(Mob._Pathfinding.i+1, 1, #Mob._Pathfinding.PathWaypoints)]["Position"]-Mob._Pathfinding.PathWaypoints[Mob._Pathfinding.i]["Position"]).magnitude/Mob._Params._Speed
		if maxt == 0 then
			Mob._Pathfinding.alpha = 0
		else
			Mob._Pathfinding.alpha = Mob._Pathfinding.t/maxt
		--	print("alpha:",Mob._Pathfinding.alpha)
		end
	end

	if (Mob._Params._Position-Mob._Params._Origin).magnitude > 100 then
		Mob._State:Change("passive", {Mob = Mob})
	end
end

function State:Exit()
end

return State