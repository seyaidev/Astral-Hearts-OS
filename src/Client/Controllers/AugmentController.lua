local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseAugment = ReplicatedStorage.Assets.Interface:FindFirstChild("Augment")

local AugmentController = {}


function AugmentController:EnsureAugment()
    local CanAugment = false
    local Character = self.Player.Character
    if not Character then return end
    if not Character.PrimaryPart then return end
    for _, Specialist in ipairs(AugmentEnabled) do
        if Specialist.PrimaryPart then
            if (Character.PrimaryPart.Position - Specialist.PrimaryPart.Position).Magnitude <= 15 then
                CanAugment = true
                break
            end
        end
    end

    if not CanAugment then return end
    self.CanAugment = CanAugment
end

function AugmentController:FilterInventory(Filter)
    if not self.CanAugment then return end
    if not self.Controllers.DataBlob.Blob then return end
    return TableUtil.Filter(self.Controllers.DataBlob.Blob.Inventory, function(item, index)
        if typeof(item) == "number" then
            if item > 0 then
                local info = self.Shared.Cache:Get("ItemLibrary")[index]
                return info.Type == Filter
            else
                return false
            end
        end

        return item.Type == Filter
    end)
end

function AugmentController:BuildItems(Items)
    if not self.CanAugment then return end
    if not self.AugmentUI then return end

    for UniqueId, ItemData in pairs(Items) do
        -- create button
        local newButton = self.AugmentUI.Resources:FindFirstChild("ItemButton"):Clone()
        newButton.ItemName.Text = ItemData.Name
        if ItemData.Augments then
            newButton.Subtext.Text = tostring(#ItemData.Augments) .. "/30"
        end

        local function Click()
            self.AugmentMaid:DoCleaning()

            local AugmentMenu = self.AugmentUI:WaitForChild("AugmentMenu")
            local PreInfo = Augment:WaitForChild("PreInfo")
            PreInfo.ItemTitle.Text = ItemData.Name
            PreInfo.ItemDesc.Text = ItemData.Description

            for i,v in ipairs(PreInfo.Stats:GetChildren()) do
                if v:IsA("GuiObject") then
                    v:Destroy()
                end
            end

            if ItemInfo.Stats ~= nil then
                for i, v in pairs(ItemInfo.Stats) do
                    local NewStat = self.AugmentUI.Resources:FindFirstChild("Stat"):Clone()
                    NewStat.Text = i .. ": " .. tostring(v)
                    NewStat.Parent = ItemDisplay.Stats
                    NewStat.Visible = true
                end
            end


            self.AugmentUI.Visible = true
        end
    end
end

function AugmentController:InitializeAugment()
    self:EnsureAugment()
    if not self.CanAugment then return end

    self.AugmentUI = BaseAugment:Clone()
    self.AugmentUI.Parent = self.Player:WaitForChild("PlayerGui")
    
    local Blob = self.Controllers.DataBlob.Blob
    local FilteredInventory = self:FilterInventory("Weapon")

end

function AugmentController:Start()
    -- make sure that you're in the vicinty of someone that can augment your stuff so you're not augmenting randomly
    self:ConnectEvent("StartAugment", function()
        local AugmentEnabled = CollectionService:GetTagged("AugmentEnabled")
        
        self:InitializeAugment()
    end)
end

function AugmentController:Init()
    self.CanAugment = false
    self:RegisterEvent("StartAugment")
    
    TableUtil = self.Shared.TableUtil
    Maid = self.Shared.Maid
    self.AugmentMaid = Maid.new()
end

return AugmentController