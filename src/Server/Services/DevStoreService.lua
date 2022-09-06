-- Dev Store Service
-- DarkLizz
-- September 11, 2019

--[[
	
	Server:
		
	
	Client:
	
		DevStoreService:PromptPurchaseFailed(receiptInfo)}
		DevStoreService:PromptPurchaseFinished(receiptInfo)
	]]

local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

local RbxWeb
local PurchaseStore
local PURCHASE_STORE = "PurchaseStore"
local PROMPT_PURCHASE_FAILED_EVENT = "PromptPurchaseFailed"
local PROMPT_PURCHASE_FINISHED_EVENT = "PromptPurchaseFinished"

local DataStore2 = require(ServerStorage:FindFirstChild("DataStore2", true))


local DevStoreService = {Client = {}}
DevStoreService.__aeroOrder = 5

local Gamepasses = {}						--List of Gamepasses
local Subscriptions = {}					--List of Subscriptions
local Purchases = {}						--List of Other Dev Products 
local CashShop = {}

function DevStoreService:getGamepassFromId(id)
    for i,v in pairs(Gamepasses) do
        if v._id == id then
            return v._name;
        end
    end
end

function DevStoreService:getSubFromId(id)
    for i,v in pairs(Subscriptions) do
        if v._id == id then
            return v._name;
        end
    end
end

function DevStoreService:getProductFromId(id)
    for i,v in pairs(Purchases) do
        if v._id == id then
            return v._name;
        end
    end
end

--[[
    ReceiptInfo:
        PurchaseId
        PlayerId
        ProductId
        CurrencySpent
        CurrencyType
        PlaceId
    ]]

function DevStoreService:processGP(player, gamepass)
    local data = self.Players[player].Gamepasses
    if (data[gamepass] ~= true) then
        local success, message = pcall(function()
            self.Players[player].Gamepasses[gamepass] = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass._id)
        end)
        if not success then
            warn("Error while checking if player has pass: " .. tostring(message))
            --Data.log(player, "ProcessNewGP", message)
            return
        end
    end
end

function DevStoreService:processSub(player, sub)
    --Will complete later
end

--[[
    Dev Products currently
    XP - XP Boost
    Munny - Munny Boost
    Donation - Donation
    
    ]]

function DevStoreService:processPurchase(userid, purchase)
    local item = Purchases[purchase]._item
    local quantity = Purchases[purchase]._quantity

    print(purchase, item)
    if item == "XP" then
    elseif item == "Munny" then
    elseif item == "Donation" then
        return true
    elseif item == "SayoCredit" then
        print("SC:", quantity)
        return self.Services.PlayerService:PurchaseCredits(userid, quantity)
    end
    return false
end


function DevStoreService:checkGP(player, pass)
    return self.Players.Gamepasses[pass]
end

function DevStoreService:checkSub(player, sub)
    return self.Players.Subscriptions[sub]
end

function DevStoreService:RecordReceiptInfo(receiptInfo, this)
    receiptInfo.CurrencyType = "Robux"
    receiptInfo.Success = this
    local success, PurchaseTable = PurchaseStore:GetAsync(tostring(receiptInfo.PlayerId))
    local Player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if Player then
        local PlayerPurchaseHistory = DataStore2("PurchaseHistory", Player):Get({})
        receiptInfo.T = os.time()
        table.insert(PlayerPurchaseHistory, receiptInfo)
        DataStore2("PurchaseHistory", Player):Set(PlayerPurchaseHistory)
        DataStore2.SaveAll(Player)
    end
end


--client functions
function DevStoreService.Client:GetShop(Player, Filter)
    local FilteredShop = {}

    local this = {Gamepasses, Subscriptions, Purchases, CashShop}
    for _,Type in ipairs(this) do
        for i,v in pairs(Type) do
            if v._filter ~= nil then
                if v._filter == Filter then
                    table.insert(FilteredShop, TableUtil.Copy(v))
                end
            end
        end
    end

    table.sort(FilteredShop, function(a, b)
        local aq = a._quantity
        local bq = b._quantity

        if aq == nil then
            return false
        elseif bq == nil then
            return true
        else
            return aq < bq
        end
    end)

    return FilteredShop
end


function DevStoreService:Start()
    --Retrieve all the Gamepasses
    PurchaseStore = RbxWebHook:GetStore("PurchaseStore", true)
    for i,v in ipairs(ServerStorage:FindFirstChild("Gamepasses", true):GetChildren()) do
        local gamepass = require(v)
        Gamepasses[gamepass._name] = gamepass
    end

    --Retrieve all the Subscriptions
    for i,v in ipairs(ServerStorage:FindFirstChild("Subscriptions", true):GetChildren()) do
        local sub = require(v)
        Subscriptions[sub._name] = sub
    end

    --Retrieve all the In game purchases
    for i,v in ipairs(ServerStorage.DevProducts:FindFirstChild("Purchases", true):GetChildren()) do
        local purch = require(v)
        Purchases[purch._name] = purch
    end

    --Retrieve all cash shop items
    for i,v in ipairs(ServerStorage.DevProducts:FindFirstChild("CashShop", true):GetChildren()) do
        local cash = require(v)
        CashShop[cash._name] = cash
    end

    game:GetService("MarketplaceService").ProcessReceipt = function(receiptInfo)
        local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
        -- print(repr(receiptInfo))
        if not player then
            self:FireClientEvent(PROMPT_PURCHASE_FAILED_EVENT, player, receiptInfo)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        else
            self:FireClientEvent(PROMPT_PURCHASE_FINISHED_EVENT, player, receiptInfo)
        end
        
        
        local this = self:processPurchase(receiptInfo.PlayerId, self:getProductFromId(receiptInfo.ProductId))
        self:RecordReceiptInfo(receiptInfo, this)
        if this then
            return Enum.ProductPurchaseDecision.PurchaseGranted
        else
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
    end

    self:ConnectClientEvent("PromptProductPurchase", function(Player, ProductName)
        if Purchases[ProductName] then
            local product = Purchases[ProductName]
            MarketplaceService:PromptProductPurchase(Player, product._id)
        elseif Gamepasses[ProductName] then
            local product = Gamepasses[ProductName]
            MarketplaceService:PromptGamePassPurchase(Player, product._id)
        elseif CashShop[ProductName] then
            --check SayoCredits, process callback, subtract if successful
            local cs = CashShop[ProductName]

            local PlayerCurrency = self.Services.PlayerService:GetCredits(Player)
            if PlayerCurrency >= cs._price then
                --cleared price check
                local t = cs._callback(Player)
                if t then
                    self.Services.PlayerService:SubtractCredits(Player, cs._price)
                    return true
                else
                    self.Services.PlayerService:FireClientEvent("NotifyPlayer", Player,
                    {
                        Text = "Transaction failed somehow :^(";
                        Time = 3;
                    }
                )
                end
            else
                local diff = cs._price-PlayerCurrency
                self.Services.PlayerService:FireClientEvent("NotifyPlayer", Player,
                    {
                        Text = "Need " .. tostring(diff) .. " more SayoCredit" .. (diff > 1 and "s" or "");
                        Time = 3;
                    }
                )
            end
            return false
        end
    end)

    self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(player)
        self.Players[player.UserId] = {
            Gamepasses = {};
            Subscriptions = {};
        }

        for i, v in ipairs(Gamepasses) do
            local success, message = pcall(function()
                self.Players[player.UserId].Gamepasses[v._name] = MarketplaceService:UserOwnsGamePassAsync(player.UserId, v._id)
            end)
            if not success then
                warn("Error while checking if player has pass: " ..tostring(message))
            end
        end

        for i, v in ipairs(Subscriptions) do
            local success, message = pcall(function()
                --Unavailable yet
                self.Players[player.UserId].Subscriptions[v._name] = false
            end)
            if not success then
                warn("Error while checking if player has subscription: " ..tostring(message))
            end
        end
        
    end)

    print("Started DevStoreService")
end

function DevStoreService:Init()
    self.Players = {}
    GlobalData = self.Shared.GlobalData

    local Version = GlobalData.DATA_VERSION
	if game.GameId == 514087790 then
		--Version = GlobalData.TEST_VERSION
	end

    DataStore2.Combine(Version, "PurchaseHistory")
    self:RegisterClientEvent("PromptProductPurchase")
    self:RegisterClientEvent(PROMPT_PURCHASE_FINISHED_EVENT)
    self:RegisterClientEvent(PROMPT_PURCHASE_FAILED_EVENT)
    
    repr = self.Shared.repr
    RbxWebHook = self.Services.RbxWebHook
    TableUtil = self.Shared.TableUtil
end

return DevStoreService
    