-- Ping Controller
-- oniich_n
-- August 19, 2019

--hi if you're an exploiter, you will get kicked :)
--dont try to break my game. its no fun for anyone involved.


local PingController = {}


function PingController:Start()
    PingService.PingRand:Connect(function(number)
        PingService.PingSend:Fire(number)
    end)
end


function PingController:Init()
	PingService = self.Services.PingService
end


return PingController