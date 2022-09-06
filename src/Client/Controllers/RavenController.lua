-- Raven Controller
-- Username
-- September 10, 2019


local LogService = game:GetService("LogService")
local RavenController = {}


function RavenController:Start()
    -- if true then return end
    -- if game:GetService("RunService"):IsStudio() then return end

    -- local success, err = pcall(function() error("test client error") end)
	-- if (not success) then
	-- 	RavenService.RavenSend:Fire(err, debug.traceback())
	-- end
    if game:GetService("RunService"):IsStudio() then return end
    LogService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            RavenService.RavenSend:Fire(message, debug.traceback())
        end
    end)
end


function RavenController:Init()
	RavenService = self.Services.RavenService
end


return RavenController