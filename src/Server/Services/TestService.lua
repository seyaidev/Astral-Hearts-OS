-- Test Service
-- oniich_n
-- August 5, 2019



local TestService = {Client = {}}

local EnableTest = false
function TestService:Start()

	-- require(2110831719).new(2, "Behavior Tree Optimize", {
    --     ["oldTree"] = function() oldTree:run() end,
    --     ["newTree"] = function() newTree:run() end
    -- })
end


function TestService:Init()
    if not EnableTest then return end
    -- BehaviorTree = self.Shared.behavior_tree
    BehaviorTree2 = self.Shared.BehaviorTree2
    -- FastSpawn = self.Shared.FastSpawn
    -- FastSpawn2 = self.Shared.FastSpawn2
end


return TestService