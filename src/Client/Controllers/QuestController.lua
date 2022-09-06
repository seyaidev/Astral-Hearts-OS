-- Quest Controller
-- Username
-- September 6, 2019

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestController = {__aeroOrder = 7}

function QuestController:CheckObjective(targetInfo)
    if self.QuestBlob then
        local Object = self.QuestBlob.InProgress[targetInfo.QuestId]
        if Object then
            for Objective, ObjTable in pairs(Object.Objectives) do
                if Objective == targetInfo.Objective then
                    for Target, Value in pairs(ObjTable) do
                        if Objective == "TALK" then
                            if Object.Progress[Objective][Target] == true and targetInfo.Target == Target then
                                return true
                            end
                            print("Not a true target", targetInfo.Target, Target)
                        elseif Objective == "KILL" or Objective == "GATHER" then
        
                            if Object.Progress[Objective][Target] == Value and targetInfo.Target == Target then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

function QuestController:Track()
    self.WaypointUI.Elements:ClearAllChildren()
    self.WaypointMaid:DoCleaning()
    if self.ActiveQuest and self.QuestBlob then
        if self.QuestBlob.InProgress[self.ActiveQuest] then
            -- get the tracking info
            local Waypoints = self.Services.QuestService:GetTrackingInfo(self.ActiveQuest)
            -- get signal for camera cframe changing
            local CameraSignal = workspace.CurrentCamera:GetPropertyChangedSignal("CFrame")
            
            local CharacterSignal
            if self.Player.Character then
                CharacterSignal = self.Player.Character.PrimaryPart:GetPropertyChangedSignal("Position")
            end
            for TargetId, pTable in pairs(Waypoints) do
                for _, data in ipairs(pTable) do
                    -- connect this position to the waypoint maid

                    local NewWaypoint = self.WaypointUI:WaitForChild("Waypoint"):Clone()
                    NewWaypoint.Parent = self.WaypointUI:WaitForChild("Elements")
                    NewWaypoint.Visible = false
                    self.WaypointMaid:GiveTask(CameraSignal:Connect(function()
                        if self.Player.Character then
                            local toScreen, visible = workspace.CurrentCamera:WorldToScreenPoint(data[1])
                            NewWaypoint.Position = UDim2.new(0, toScreen.X, 0, toScreen.Y)
                            NewWaypoint.Visible = visible

                            local magnitude = (self.Player.Character.PrimaryPart.Position-data[1]).Magnitude
                            NewWaypoint.Distance.Text = tostring(math.floor(magnitude)) .. "m"
                            if data[2] then
                                NewWaypoint.Quantity.Text = tostring(data[2] .. " left")
                            else
                                NewWaypoint.Quantity.Visible = false
                            end
                            -- if magnitude <= 30 then
                            --     k.Color = bc.Value:lerp(white, math.clamp(magnitude/10, 0, 1))
                            -- end
                        end
                    end))

                    
                end
            end
        end
    end
end

function QuestController:Start()

    local function UpdateQuest(v)
        PlayerData = self.Controllers.DataBlob.Blob
        if not PlayerData then 
            self.Controllers.DataBlob:ForceUpdate()
            PlayerData = self.Controllers.DataBlob.Blob
        end
        local Header = "Casual"

        local Quests = v:FindFirstChild("Quests")
        if Quests then
            for _, QuestId in ipairs(Quests:GetChildren()) do
                if QuestId:IsA("StringValue") then
                    local QuestInfo = self.Services.QuestService:GenQuest(QuestId.Value)
                    if QuestInfo and self.QuestBlob then
                        --check if in progress
                        if not self.QuestBlob.InProgress[QuestId.Value] and not self.QuestBlob.Completed[QuestId.Value] and QuestId.Name == "NewQuest" then
                            --brand new quest, check prereqs
                            local REQt = QuestInfo.Requirements
                            if REQt and Header ~= "Quest" then
                                Header = "Quest"
                                if PlayerData.Stats.Level < REQt.LEVEL then
                                    Header = "Casual"
                                end

                                local questReq = true
                                for QuestId, val in pairs(REQt.QUEST) do
                                    --check if the quest exists in completed pqd
                                    print("prereq:", QuestId)
                                    if not self.QuestBlob.Completed[QuestId] then
                                        questReq = false
                                    end
                                end

                                if not questReq then
                                    Header = "Casual"
                                end

                                local counts = {}
                                for UniqueId, ItemData in pairs(PlayerData.Inventory) do
                                    if typeof(ItemData) == "table" then
                                        if ItemData.ItemId then
                                            if counts[ItemData.ItemId] then
                                                counts[ItemData.ItemId] = counts[ItemData.ItemId]+1
                                            else
                                                counts[ItemData.ItemId] = 1
                                            end
                                        end
                                    elseif typeof(ItemData) == "number" then
                                        counts[UniqueId] = ItemData
                                    end
                                end
                                for ItemId, Amount in pairs(REQt.ITEM) do
                                    if counts[ItemId] < Amount then
                                        Header = "Casual"
                                    end
                                end
                            end
                        end

                        if self.QuestBlob.InProgress[QuestId.Value] then
                            Header = "Info"
                        end
                    end
                end
            end
        end

        local HeaderAsset = ReplicatedStorage.Assets.Interface.QuestMarkers:FindFirstChild(Header)
        if HeaderAsset then
            local NPCHead = v:FindFirstChild("Head")
            if NPCHead then
                for i,v in ipairs(NPCHead:GetChildren()) do
                    if v:IsA("BillboardGui") and v.Name ~= "NameTag" then
                        v:Destroy()
                    end
                end

                local f = HeaderAsset:Clone()
                f.Enabled = true
                f.Parent = NPCHead
            end
        end
    end

    workspace:WaitForChild("NPCs").DescendantAdded:Connect(function(v)
        if v.Name == "Head" then
            UpdateQuest(v.Parent)
        end
    end)

    self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        self.QuestBlob = self.Services.QuestService:ReturnQuestData()
        PlayerData = self.Controllers.DataBlob.Blob
        --check through NPCs

        local NPCs = workspace:WaitForChild("NPCs")
        for i, v in ipairs(NPCs:GetChildren()) do
            if v.PrimaryPart then
                UpdateQuest(v)
            end
        end
    end)


    self.Services.QuestService.NewQuest:Connect(function(QuestId)
        self.QuestBlob = self.Services.QuestService:ReturnQuestData()
        local QuestData = self.QuestBlob["InProgress"][QuestId]
        if QuestData == nil then return end
        --display quest received
        self.Controllers.NotificationController:FireEvent("Notify", {
            Text = "Received quest: " .. QuestData.DisplayName;
            Time = 4;
        })

        print("Received a new quest..", QuestId)
        self.Controllers.HUD:DisplayQuest(QuestId)
       
        self.ActiveQuest = QuestId

        self:Track()

        local NPCs = workspace:WaitForChild("NPCs")
        for i, v in ipairs(NPCs:GetChildren()) do
            if v.PrimaryPart then
                UpdateQuest(v)
            end
        end
    end)

    self.Services.QuestService.UpdateQuest:Connect(function(QuestId)
        self.QuestBlob = self.Services.QuestService:ReturnQuestData()
        local NPCs = workspace:WaitForChild("NPCs")
        for i, v in ipairs(NPCs:GetChildren()) do
            if v.PrimaryPart then
                UpdateQuest(v)
            end
        end

        self:FireEvent("UpdateQuest", QuestId)
        self:Track()
    end)

    self.Services.QuestService.RemoveQuest:Connect(function(QuestId)
        self.QuestBlob = self.Services.QuestService:ReturnQuestData()

        local QuestData = self.QuestBlob["InProgress"][QuestId] or self.QuestBlob["Completed"][QuestId]
        if QuestData == nil then return end
        --display quest received
        self.Controllers.NotificationController:FireEvent("Notify", {
            Text = "Completed quest: " .. QuestData.DisplayName;
            Time = 4;
        })

        local NPCs = workspace:WaitForChild("NPCs")
        for i, v in ipairs(NPCs:GetChildren()) do
            if v.PrimaryPart then
                UpdateQuest(v)
            end
        end
        self:FireEvent("RemoveQuest", QuestId)
    end)

    self.WaypointUI = ReplicatedStorage.Assets.Interface:FindFirstChild("Waypoints"):Clone()
    self.WaypointUI.Parent = self.Player:WaitForChild("PlayerGui")
    self.WaypointMaid = Maid.new()

    for QuestId, QuestData in pairs(self.QuestBlob.InProgress) do
        self.ActiveQuest = QuestId
    end
    self:Track()
end


function QuestController:Init()
    Maid = self.Shared.Maid
    self:RegisterEvent("UpdateQuest")
    self:RegisterEvent("RemoveQuest")

    self.QuestBlob = self.Services.QuestService:ReturnQuestData()
    self.ActiveQuest = nil
    self.Waypoints = {}
end


return QuestController