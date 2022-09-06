-- Raven Service
-- Username
-- September 10, 2019



local LogService = game:GetService("LogService")
local RavenService = {Client = {}}


function RavenService:Start()
    if game:GetService("RunService"):IsStudio() then return end
    
    local environment = "live"
    if game.GameId == 514087790 then
        environment = "preview"
    end

    if game:GetService("RunService"):IsStudio() then
        local nenvironment = "studio-" .. environment
        environment = nenvironment
    end

    local client = Raven:Client("https://24656e21fa7c450d8774bc554f53f5d4:737be05eb7fc49a4832d58481db2b6dc@sentry.io/284156",
    {
        logger = "server",
        release = GlobalData.GAME_VERSION,
        environment = environment
    })

    LogService.MessageOut:Connect(function(message, messageType)
        if (messageType == Enum.MessageType.MessageError) then
            client:SendException(Raven.ExceptionType.Server, message)
        elseif string.sub(message, 1, 5) == "Data_" then
            client:SendMessage(message, Raven.EventLevel.Info)
        end
    end)

    self:ConnectEvent("RavenDebug", function(debugMessage, level)
        -- print("notifying server", debugMessage)
        client:SendMessage(debugMessage, Raven.EventLevel[level])
    end)

    self:ConnectClientEvent("RavenSend", function(player, errorMessage, traceback, rtype)
        -- print(traceback)
        client:ConnectRemoteEvent(player, errorMessage, traceback, rtype)
    end)
end


function RavenService:Init()
    self:RegisterEvent("RavenDebug")
    self:RegisterClientEvent("RavenSend")

    Raven = self.Modules.Raven
    GlobalData = self.Shared.GlobalData
end


return RavenService