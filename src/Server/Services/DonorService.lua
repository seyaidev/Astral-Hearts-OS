--Donor Service
--DarkLizz
--September 13, 2019

--[[
	
	Server:
		DonorService.UpdateDonation(player, amount)
	
	Client:
		DonorService.GetDonorRank(player)
		DonorService.GetDonorLeaderboard()
	
	
	]]

local DonorService = {Client  = {};}
ReplicatedStorage = game:GetService("ReplicatedStorage")
ServerStorage = game:GetService("ServerStorage")
MarketplaceService = game:GetService("MarketplaceService")
ReplicatedStorage = ReplicatedStorage:FindFirstChild("Lizz Folder of Stoof") -- Remove/modify path

local DataStoreService = game:GetService("DataStoreService")

if game:GetService("RunService"):IsStudio() then
    DataStoreService = require(game.ServerStorage:FindFirstChild("MockDataStoreService", true))
end

local DonatorDatastore = DataStoreService:GetOrderedDataStore("Donations")

local Event
local UPDATE_LEADERBOARD = "UpdateLeaderboard"


--Donations
function DonorService.Client:GetDonorRank(player)
    local pages = DonatorDatastore:GetSortedAsync(true, 100)
    local page = pages:GetCurrentPage();
    while true do
        for i, v in pairs(page) do
            if v.key == player.UserId then
                return {
                    rank = i,
                    id = v.key,
                    value = v.value,
                }
            end
        end
        if pages.IsFinished then
            break
        else pages:AdvanceToNextPageAsync();
        end
    end
end

function DonorService.Client:GetDonorLeaderBoard()
    local pages = DonatorDatastore:GetSortedAsync(true, 10)
    return pages:GetCurrentPage();
end

function DonorService:UpdateDonation(player, amount)
    DonatorDatastore:IncrementASync(player.UserId, amount)
    self:FireClientEvent(UPDATE_LEADERBOARD)
end

function DonorService:Start()
    if true then return end
    game.Players.PlayerAdded:connect(function(player)
        if DonatorDatastore:GetAsync(player.UserId) == nil then
            DonatorDatastore:SetAsync(player.UserId, 0)
        end
    end)
end

function DonorService:Init()
    if true then return end
    self:RegisterClientEvent(UPDATE_LEADERBOARD)
end

return DonorService
