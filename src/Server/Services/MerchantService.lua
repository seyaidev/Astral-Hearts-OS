-- Merchant Service
-- oniich_n
-- July 29, 2019

local MerchantService = {Client = {}}
local ServerStorage = game:GetService("ServerStorage")

function MerchantService:CSRequest(Player, RequestId)
    local PlayerService = self.Server.Services.PlayerService

    local ProductInfo = self.Server.Modules.CashStore[RequestId]
    if not ProductInfo then return end

    local PlayerCurrency = PlayerService:GetCredits(Player)
    if PlayerCurrency >= ProductInfo.Price then
        local t = ProductInfo.callback(Player)
        if t then
            PlayerService:SubtractCredits(Player, ProductInfo.Price)
            return true
        end
    end

    return false
end

function MerchantService.Client:PurchaseRequest(Player, Merchant, WareId)
    local PlayerService = self.Server.Services.PlayerService
    if self.Server.Merchants[Merchant] == nil then return end
    local MerchantInfo = self.Server.Merchants[Merchant]
    local PlayerInfo = PlayerService:GetPlayerData(Player)

    if MerchantInfo == nil or PlayerInfo == nil then return end

    local ItemInfo = self.Server.Shared.Cache:Get("ItemLibrary")[MerchantInfo.Wares[WareId].ItemId]
    local PlayerCurrency = PlayerInfo.Stats.Munny
    if MerchantInfo.Currency == "SayoCredits" then
        PlayerCurrency = PlayerService:GetCredits(Player)
    end
    if PlayerCurrency >= MerchantInfo.Wares[WareId].Price then

    --create new item based off WareId Info
        if ItemInfo.Type ~= "Use" then
            local NewItem = ItemService:CreateItem(MerchantInfo.Wares[WareId].ItemId, Player)
            if NewItem ~= nil then

                -- local HasSkin = {}

                -- for i, v in pairs(Skins) do
                --     if TableUtil.IndexOf(HasSkin, v.Id) or TableUtil.IndexOf(HasSkin, v.ItemId) then
                --         Skins[i] = nil
                --     else
                --         table.insert(HasSkin, v.Id or v.ItemId)
                --     end
                -- end

                local IsImportant = false
                if MerchantInfo.Currency == "SayoCredits" then
                    PlayerService:SubtractCredits(Player, MerchantInfo.Wares[WareId].Price)
                    IsImportant = true
                else
                    PlayerService:UpdateMunny(Player.UserId, -MerchantInfo.Wares[WareId].Price)
                end
                PlayerService:GiveItem(Player.UserId, NewItem, IsImportant)
                wait()
                local nPlayerInfo = PlayerService:GetPlayerData(Player)
                PlayerService:FireClientEvent("UpdateBlob", Player, nPlayerInfo)
                return true
            end
        else
            PlayerService:UpdateMunny(Player.UserId, -MerchantInfo.Wares[WareId].Price)
            ItemService:CreateStackable(MerchantInfo.Wares[WareId].ItemId, Player, 1)

            return true
        end
    end
    return false
end

function MerchantService:Start()
    --initiate merchants
    local MerchantFolder = ServerStorage:FindFirstChild("Merchants")
    if MerchantFolder == nil then return end
    for i, v in pairs(MerchantFolder:GetChildren()) do
        if v:IsA("ModuleScript") then
            local MerchantInfo = require(v)
            self.Merchants[MerchantInfo.Id] = MerchantInfo
        end
    end
end


function MerchantService:Init()
    self:RegisterClientEvent("StartShop")

    self.Merchants = {}
    GlobalData = self.Shared.GlobalData
    PlayerService = self.Services.PlayerService
    ItemService = self.Services.ItemService
end


return MerchantService