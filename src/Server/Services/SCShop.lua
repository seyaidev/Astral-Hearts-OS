--SCShopService
--oniich_n
--October 18, 2019

local SCShopService = {}

function SCShopService:Start()
    self:ConnectClientEvent("SCShopPurchase", function(Player, SCId)
        --find this item in the index
    end)
end

function SCShopService:Init()
    self:RegisterClientEvent("SCShopPurchase")
    
    PlayerService = self.Services.PlayerService
end

return SCShopService