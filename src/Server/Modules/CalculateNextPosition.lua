-- Calculate Next Position
-- oniich_n
-- August 29, 2019
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage:FindFirstChild("TableUtil", true))

local maxForce = 2
local function GetRepulsionVector(unitPosition, otherUnitsPositions)
	local repulsionVector = Vector3.new(0,0,0)
	local count = 0
	for _, other in pairs(otherUnitsPositions) do
		local fromOther = unitPosition - other 
		--fromOther = fromOther.unit * ((-maxForce / 5) * math.pow(fromOther.magnitude,2) + maxForce)
		fromOther = fromOther.unit * maxForce / math.pow((fromOther.magnitude + 1), 2)
		repulsionVector = repulsionVector + fromOther
	end
	return repulsionVector * maxForce
end

return function(CurrentPosition, NextPosition, Height, Speed, dt, Actors)

    --remove curr pos from actors
    if Actors ~= nil then
        local thisIndex = TableUtil.IndexOf(Actors, CurrentPosition)
        if TableUtil.IndexOf(Actors, CurrentPosition) then
            table.remove(Actors, thisIndex)
        end
    end

    if typeof(CurrentPosition) == "table" then
        CurrentPosition = TableUtil.ToVector3(CurrentPosition)
    end

    if typeof(NextPosition) == "table" then
        NextPosition = TableUtil.ToVector3(NextPosition)
    end
    local Distance = (CurrentPosition-NextPosition).Magnitude
    local TimeToTravel = Distance/Speed

    -- print(nvec)
    -- print(NextPosition)
    -- print(dt)
    -- print(TimeToTravel)
    local XYpos = CurrentPosition:Lerp(NextPosition, dt/TimeToTravel)
    if Actors ~= nil then
        XYpos = XYpos + GetRepulsionVector(XYpos, Actors)
    end
    --get height
    local heightray = Ray.new(XYpos+Vector3.new(0,5,0), Vector3.new(0, -20, 0))
    local hit, pos, norm = workspace:FindPartOnRayWithWhitelist(heightray, {
        workspace:FindFirstChild("Terrain"),
        workspace:FindFirstChild("MobCollide")
    })

    if hit and pos then
        FinalPosition = {
            X = XYpos.X;
            Y = pos.Y;-- + Height;
            Z = XYpos.Z;
        }

        FinalCFrame = CFrame.new(
            Vector3.new(CurrentPosition.X, CurrentPosition.Y, CurrentPosition.Z),
            Vector3.new(NextPosition.X, CurrentPosition.Y, NextPosition.Z)
            -- NextPosition
        )
        return FinalPosition, FinalCFrame
    else
        return {
            X = XYpos.X;
            Y = XYpos.Y;
            Z = XYpos.Z;
        }, CFrame.new(
            Vector3.new(CurrentPosition.X, CurrentPosition.Y, CurrentPosition.Z),
            Vector3.new(NextPosition.X, CurrentPosition.Y, NextPosition.Z)
            -- NextPosition
        )
    end
end