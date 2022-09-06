-- Drop Service
-- oniich_n
-- August 2, 2019

--Receive a drop request from other services
--Player specific

 --Player says "i picked it up"
 --Verify position
 --Verify drop actually exists
 --Award item


local DropService = {Client = {}}
local DropCache = {}

local DROP_SEND_CLIENT = "DROP_SEND_CLIENT"

function DropService:CacheDrop(DropInfo, Region)
    --get drop info
    --create drop in cache
    --tell player that the drop has been created

    --[[
        {
            Id = GUID;
            ItemId = string;
            UserId = Player.UserId;
            Position = Vector3.new();
            Timeout = number;
        }
    ]]

    local Player = game.Players:GetPlayerByUserId(DropInfo.UserId)
    print(Player)
    if Player then
        DropCache[DropInfo.Id] = DropInfo
        self:FireClientEvent(DROP_SEND_CLIENT, Player, DropInfo)
        -- print("OH SNAP, CRACKLE, POP")

        -- timeout drop, readd to the counter
        delay(90, function()
            if DropCache[DropInfo.Id] ~= nil and Region then
                self.Services.MobService:ReturnDrop(Player, Region, DropInfo.Items)
                DropCache[DropInfo.Id] = nil
                self:FireClientEvent("RemoveDrop", Player, DropInfo.Id)
                print("returning drop...")
            end
        end)

        return true
    end
    return false
end

function DropService.Client:CollectDrop(Player, DropId)
    local Drop = DropCache[DropId]
    if Drop == nil then return end --drop does not exist
    if Player.Character == nil then return end --character does not exist
    if (Player.Character.PrimaryPart.Position-Drop.Position).Magnitude >= 25 then return end --player too far from the drop
    if Drop.UserId ~= Player.UserId then return end

    --create item based on DropInfo
    for i, ItemInfo in pairs(Drop.Items) do
        local Item
        if ItemInfo.Type == "Use" or ItemInfo.Type == "Misc" then
            Item = ItemService:CreateStackable(ItemInfo.ItemId, Player, 1)
            print("stacked", ItemInfo.ItemId)

        else
            Item = ItemService:CreateItem(ItemInfo.ItemId, Player)
            self.Server.Services.PlayerService:GiveItem(Player, Item, false)
            print("created", ItemInfo.ItemId)
        end
    end

    --give munny/exp(?)
    DropCache[DropId] = nil
    return true
end

function DropService:Start()
end

function DropService:Init()
    ItemService = self.Services.ItemService
    PlayerService = self.Services.PlayerService
    self:RegisterClientEvent("DROP_SEND_CLIENT")
    self:RegisterClientEvent("RemoveDrop")
end


return DropService