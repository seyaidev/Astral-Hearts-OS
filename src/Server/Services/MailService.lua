-- Mail Service
-- Username
-- September 7, 2019

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local DataStore2 = require(game:GetService("ServerStorage"):FindFirstChild("DataStore2", true))

local MailService = {Client = {}}

local PostOffice = {}
local GlobalPending = {}
local StoreBox = {}
local SingleBox = {}

--[[
    LetterInfo = {
        Name = "";
        Id = "";
        Message = "";
        Gifts = {
            Items = {};
            EXP = 123;
            Munny = 123;
        };
        ExpireDate = date to epoch
    }

]]

function MailService:CodeCheck(Code)

    local OneTimeStore = RbxWebHook:GetStore("OneTimeStore2", true)
    local Success, Data = OneTimeStore:GetAsync(Code)

    print(Code, Success, Data)
end

function MailService:AcceptGifts(Player, LetterId, CID)
    local InboxBlob = PostOffice[Player]
    if InboxBlob == nil then return end
    print(LetterId, InboxBlob.Available[LetterId])
    if InboxBlob.Available[LetterId] == nil then return end

    local LetterInfo = InboxBlob.Available[LetterId]
    PlayerService:Reward(Player.UserId, LetterInfo.Gifts)
    if LetterInfo.Gifts.SayoCredits then
        PlayerService:PurchaseCredits(Player.UserId, LetterInfo.Gifts.SayoCredits)
    end
    if #LetterInfo.Gifts.Items > 0 then
        for i, v in ipairs(LetterInfo.Gifts.Items) do
            local UniqueItem = ItemService:CreateItem(v, Player)
            -- PlayerService:GiveItem(Player, UniqueItem)
        end
    end

    InboxBlob.Discarded[LetterId] = true
    InboxBlob.Available[LetterId] = nil

    PostOffice[Player] = InboxBlob
    StoreBox[Player]:Set(InboxBlob)
    DataStore2(CID .. "_I", Player):Set(InboxBlob)
end

function MailService.Client:RedeemCode(Player, Code)
    local InboxBlob = PostOffice[Player]
    if InboxBlob == nil then return end
    -- local GiftCodes = self.Server.Modules.GiftCodes
    -- print(GiftCodes)

    local GiftId = GiftCodes.Available[Code] or GiftCodes.OneTime[Code] or GiftCodes.Single[Code]
    if GiftId == nil then return("Not a valid code") end
    if GiftCodes.Gift[GiftId] == nil then return("SERVER ERROR") end

    if InboxBlob.Available[GiftId] ~= nil or InboxBlob.Discarded[GiftId] ~= nil then print("Already received") return "Already redeemed" end

    local function ExtraCheck(Player, Code, key)

        local thisStore = RbxWebHook:GetStore("OneTimeStore2", true)
        if key == "Single" then
			DataStore2.Combine(self.Server.Version, "SingleCode")
            local store = DataStore2("SingleCode", Player)
            local curr = store:Get({})
            
            if curr[Code] then return "Already redeemed" end
            
            curr[Code] = true
            store:Set(curr)
            print('saving to single..')
            return false
        end
        local Success, Data = thisStore:GetAsync(Code)
        if Success and Data ~= nil then print(Success, Data) return "Already redeemed" end
        
        thisStore:SetAsync(Code, true)

        print("SAVED:", Code, thisStore:GetAsync(Code))
        if key == "OneTimeStore2" then
            if GlobalPending[Code] ~= nil then print("Code is pending") return "Already redeemed" end
            GlobalPending[Code] = Player.UserId
            if not RunService:IsStudio() then
                MessagingService:PublishAsync("GlobalCode", tostring(Player.UserId) .. "_" .. tostring(Code) .. ".p")
            end
        end
    end

    --if code is a one time use
    local t = false
    if GiftCodes.Single[Code] then
        t = ExtraCheck(Player, Code, "Single")
    end
    if GiftCodes.OneTime[Code] then
        --check global pending via MessagingService
        --check datastore
        t = ExtraCheck(Player, Code, "OneTimeStore2")
    end
    print(t)
    if t then return t end

    InboxBlob.Available[GiftId] = TableUtil.Copy(GiftCodes.Gift[GiftId])
    if GiftCodes.OneTime[Code] then
        if not RunService:IsStudio() then
            MessagingService:PublishAsync("GlobalCode", tostring(Player.UserId) .. "_" .. tostring(Code) .. ".f")
        end
        GlobalPending[Code] = "f"
    end

    PostOffice[Player] = InboxBlob
    StoreBox[Player]:Set(InboxBlob)
    -- self:FireClientEvent("LetterReceived", Player)
    print("Well then..., this is awkward")
    return true
end

function MailService:GetBlob(Player)
    if PostOffice[Player] then
        return PostOffice[Player]
    end
    return
end

function MailService.Client:GetBlob(Player)
    local Blob = self.Server:GetBlob(Player)
    print("Got InboxBlob:", Blob)
    return Blob
end

function MailService:Start()

    if not RunService:IsStudio() then
        MessagingService:SubscribeAsync("GlobalCode", function(data)
            if data ~= nil then
                if typeof(data) ~= "string" then return end
                local UserId, Code, Status = data:match("(%d+)_(.+)%.(%l+)")
                if UserId == nil or Code == nil or Status == nil then return end
                if GiftCodes.OneTime[Code] == nil then return end
                
                if Status == "p" then
                    GlobalPending[Code] = UserId
                elseif Status == "f" then
                    GlobalPending[Code] = "f"
                end
            end
        end)
    end

    self:ConnectClientEvent("DiscardLetter", function(Player, LetterId)
        local InboxBlob = PostOffice[Player]
        if InboxBlob == nil then return end

        if InboxBlob.Available[LetterId] == nil then return end
        InboxBlob.Discarded[LetterId] = InboxBlob.Available[LetterId]
        InboxBlob.Available[LetterId] = nil

        PostOffice[Player] = InboxBlob
    end)

    self:ConnectClientEvent("AcceptGifts", function(Player, LetterId)
        local InboxBlob = PostOffice[Player]
        if InboxBlob == nil then return end
        local CharacterId = self.Services.PlayerService:GetPartial(Player, "CharacterId")
        -- print("CID:", CharacterId)
        self:AcceptGifts(Player, LetterId, CharacterId)
    end)

    self:ConnectClientEvent("RedeemCode", function(Player, Code)
        local InboxBlob = PostOffice[Player]
        if InboxBlob == nil then return end

        self:RedeemCode(Player, Code) 
    end)

    PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(Player, InitAppearance, InitPlayerData, CachedStores)
        --get current inbox
        --check if there are new global letters
            --note: create module on the server to send letters from using Packages
            --make sure they havent already been received/deleted
        
        local InboxBlob = CachedStores.InboxStore:GetTable({
            Available = {};
            Discarded = {};
        })

        for LetterId, LetterInfo in pairs(NewLetters.Letters) do
            --check if letter hasnt already been received
            local CanSend = true
            for i, v in pairs(InboxBlob.Available) do
                if LetterId == i then CanSend = false end
            end

            for i, v in pairs(InboxBlob.Discarded) do
                if LetterId == i then CanSend = false end
            end

            if CanSend then
                InboxBlob.Available[LetterId] = LetterInfo
            end
        end

        PostOffice[Player] = InboxBlob
        StoreBox[Player] = CachedStores.InboxStore
        SingleBox[Player] = CachedStores.SingleCodeStore
        print("Loaded inbox", Player)
    end)

    PlayerService:ConnectEvent("PLAYER_REMOVED_EVENT", function(Player)
        PostOffice[Player] = nil
    end)

    -- for i, v in pairs(GiftCodes.OneTime) do
    --     self:CodeCheck(i)
    -- end
end


function MailService:Init()
    self:RegisterClientEvent("RedeemCode")
    self:RegisterClientEvent("DiscardLetter")
    self:RegisterClientEvent("AcceptGifts")
    self:RegisterClientEvent("LetterReceived")

    ItemService = self.Services.ItemService
    PlayerService = self.Services.PlayerService
    RbxWebHook = self.Services.RbxWebHook

	Maid = self.Shared.Maid
	TableUtil = self.Shared.TableUtil
	GlobalData = self.Shared.GlobalData

	repr = self.Shared.repr
	TableUtil = self.Shared.TableUtil
    FormulasModule = self.Shared.FormulasModule
    
    NewLetters = self.Modules.NewLetters
    GiftCodes = TableUtil.Copy(self.Modules.GiftCodes)

    self.Version = GlobalData.DATA_VERSION
    if game.GameId == 514087790 then
    	--self.Version = GlobalData.TEST_VERSION
    end
end


return MailService