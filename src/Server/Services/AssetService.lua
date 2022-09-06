--Asset Service
--oniich_n
--October 8, 2019
local ServerStorage = game:GetService("ServerStorage")

local InsertService = game:GetService("InsertService")
local AssetService = {Client = {}; __aeroOrder = 2}

function AssetService:LoadAsset(AssetName)
    local CachedAsset = AssetCache:FindFirstChild(AssetName)
    if CachedAsset then
        return CachedAsset
    else
        if self.Modules.AssetIds[AssetName] == nil then return end

        local AssetId = self.Modules.AssetIds[AssetName]
        local function getAsset(asset_name)
            local success, asset = pcall(function()
                local AssetModel = InsertService:LoadAsset(AssetId)
                return AssetModel
            end)

            if success and asset then
                local atable = asset:GetChildren()
                if not AssetCache:FindFirstChild(AssetName) then
                    atable[1].Parent = AssetCache
                end
                return atable[1]
            else
                wait(1)
                getAsset(asset_name)
            end
        end

        return getAsset(asset_name)
    end
end

function AssetService.Client:RequestAsset(Player, AssetName)
    local ClientCache = Player:WaitForChild("ClientCache")
    local SauceToFind = Player.ClientCache:FindFirstChild(AssetName)
    if SauceToFind then
        return SauceToFind
    else
        local ClientSauce = self.Server:LoadAsset(AssetName)
        if ClientSauce then
            local ClientPasta = ClientSauce:Clone()
            ClientPasta.Parent = Player:WaitForChild("ClientCache")
            return ClientPasta
        end
    end
    return nil
end

function AssetService:Start()
    self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(Player)
        local ClientCache = Instance.new("Folder", Player)
        ClientCache.Name = "ClientCache"
    end)
end

function AssetService:Init()
    -- Promise = self.Shared.Promise
    AssetCache = Instance.new("Folder", ServerStorage)
    AssetCache.Name = "AssetCache"
end

return AssetService