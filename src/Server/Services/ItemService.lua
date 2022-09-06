-- Item Service
-- oniich_n
-- April 29, 2019

--[[
	
	Server:
		
		ItemService:CreateItem(SourceId)
	


	Client:
		
	

--]]
local ItemService = {Client = {}}

local TableUtil
local ItemLibrary

function ItemService:CreateItem(SourceId, Player)
    if ItemLibrary[SourceId] == nil then return end
    
    local Blob = self.Services.PlayerService:GetPlayerData(Player)
    local UniqueData = TableUtil.Copy(ItemLibrary[SourceId])

    UniqueData.ItemId = SourceId
    UniqueData.UniqueId = game:GetService("HttpService"):GenerateGUID()

    if Blob then
        Blob.Inventory[UniqueData.UniqueId] = UniqueData
        self.Services.PlayerService:FireClientEvent("UpdateBlob", Player, Blob)
        self.Services.QuestService:UpdateQuest(Player, {
            Objective = "GATHER";
            Target = SourceId;
            Quantity = 1;
        })
    end
    
    return UniqueData
end

function ItemService:CreateStackable(SourceId, Player, Quantity)
    if ItemLibrary[SourceId] == nil then return end
    if Quantity == nil then return end

    if Player then
        local Blob = self.Services.PlayerService:GetPlayerData(Player)
        if Blob then
gghhhhhhhhhhhhhhhhhhhhhhhhhhhhnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn            if Blob.Inventory[SourceId] ~= nil then
                if Blob.Inventory[SourceId] < ItemLibrary[SourceId].Max then
                    Blob.Inventory[SourceId] = math.clamp(Blob.Inventory[SourceId]+Quantity, 1, ItemLibrary[SourceId].Max)
                end
            elseif Quantity < ItemLibrary[SourceId].Max then
                Blob.Inventory[SourceId] = Quantity
            end
            
            self.Services.PlayerService:SetPartial(Player, "Inventory", Blob.Inventory)
            self.Services.PlayerService:FireClientEvent("UpdateBlob", Player, Blob)

            self.Services.QuestService:UpdateQuest(Player, {
                Objective = "GATHER";
                Target = SourceId;
                Quantity = Quantity;
            })
        end
        return
    end
end

function ItemService:AugmentItem(Player, ToAugment, AugmentType, AugmentQuantity)
    local Blob = self.Services.PlayerService:GetPlayerData(Player)
    local AugmentData = self.Shared.Cache:Get("Augments")[AugmentType]

    if Blob.Stats.Level < 30 then return end
    -- get augment info from cache, should have item requirements and stats affected
    --[[
        AugmentData = {
            Stats = {
                -- Base 4 + ATK/DEF
            };
            RequiredItems = {
                ItemId = {
                    Type = "Stack" or "Other";
                    Amount = int;
                };
            };
        }
    ]]

    local Inventory = Blob.Inventory
    local AugmentedItem = Inventory[ToAugment]
    if AugmentedItem then
        -- check required items
    
        local HasRequired = true
        local ToRemove = {}
        for NeededItem, Data in pairs(AugmentData.RequiredItems) do
            if Data.Type == "Stack" then
                if Inventory[NeededItem] then
                    if Inventory[NeededItem] >= Data.Amount then
                        ToRemove[NeededItem] = Data.Amount
                        continue
                    end
                end
            else
                for i, v in pairs(Inventory) do
                    local has = TableUtil.Has(v, "ItemId", NeededItem)
                    if has then
                        ToRemove[NeededItem] = i
                        continue
                    end
                end
            end
        end

        for i, v in pairs(AugmentData.RequiredItems) do
            if ToRemove[i] == nil then
                HasRequired = false
                break
            end
        end
        
        if HasRequired then
            -- remove items
            for RemoveId, Value in pairs(ToRemove) do
                if typeof(Value) == "number" then
                    Inventory[RemoveItem] = Inventory[RemoveItem] - Value
                elseif typeof(Value) == "string" then
                    Inventory[RemoveItem] = nil
                end
            end
            -- apply augments
            for Stat, Value in pairs(AugmentData.Stats) do
                if AugmentedItem[Stat] and typeof(Value) == "number" then
                    AugmentedItem[Stat] = AugmentedItem[Stat] + Value
                else -- stat is a string (like element) or DNE
                    AugmentedItem[Stat] = Value
                end
            end

            Inventory[ToAugment] = AugmentedItem
            self.Services.PlayerServices:SetPartial(Player, "Inventory", Inventory)
        end
        
    end
end

function ItemService.Client:ConsumeItem(Player, ItemId)
    local Blob = self.Server.Services.PlayerService:GetPlayerData(Player)
    local ItemInfo = ItemLibrary[ItemId]
    if ItemInfo == nil then return end
    if Blob then
        print('INIT CONSUM')
        if Blob.Inventory[ItemId] ~= nil then
            if Blob.Inventory[ItemId] > 0 then
                Blob.Inventory[ItemId] = Blob.Inventory[ItemId]-1
                for effect, value in pairs(ItemInfo.Stats) do
                    if effect == "HEAL" then
                        local Character = Player.Character
                        if Character then
                            if Character.Humanoid then
                                Character.Humanoid.Health = math.clamp(Character.Humanoid.Health+value, 0, Character.Humanoid.MaxHealth)
                                print(Character.Humanoid.Health, 'HEALED')
                            end
                        end
                    end
                end

                if Blob.Inventory[ItemId] == 0 then
                    --update inventory client
                end

                self.Server.Services.PlayerService:SetPartial(Player, "Inventory", Blob.Inventory)
                return true
            end
        end
    end
    print('no item used')
    return false
end

function ItemService.Client:ClientTestItem(player)
    if ItemLibrary["ScissorBladeR"] == nil then return end
    local UniqueData = TableUtil.Copy(ItemLibrary["ScissorBladeR"])
    UniqueData.ItemId = "ScissorBladeR"
    UniqueData.UniqueId = game:GetService("HttpService"):GenerateGUID()
    UniqueData.Owner = player

    table.insert(self.ItemQueue, UniqueData)

    return UniqueData
end

function ItemService:Start()

end


function ItemService:Init()
	TableUtil = self.Shared.TableUtil
    ItemLibrary = self.Shared.Cache:Get("ItemLibrary")
    FastSpawn = self.Shared.FastSpawn
end


return ItemService