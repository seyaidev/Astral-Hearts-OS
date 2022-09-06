-- Barrier Controller
-- Username
-- March 30, 2020



local BarrierController = {}


function BarrierController:Start()
    local Barriers = workspace:WaitForChild("DestructibleBarriers", 3)
    if Barriers then
        Barriers = Barriers:GetChildren()
    end
end


function BarrierController:Init()
	
end


return BarrierController