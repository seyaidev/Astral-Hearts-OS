local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local DialogueController = {
    __aeroPreventStart = false;
    __aeroPreventInit = false;
    __aeroOrder = 11;
}

local EndFadeTime = 5
local DialogueBase = ReplicatedStorage.Assets.Interface.Dialogue:WaitForChild("DialogueBase")


local function RecursiveDisplayIn(obj, confirmcheck)
	for i, v in ipairs(obj:GetChildren()) do
		if v.Name ~= "Confirm" and v.Name ~= "Cancel" and not confirmcheck then
			if CollectionService:HasTag(v, "TransitionDown") then
			    Transitions:TransitionDown(v, false)
			elseif CollectionService:HasTag(v, "TransitionUp") then
			    Transitions:TransitionUp(v, false)
			end
			
			if #v:GetChildren() > 0 then
			    delay(0.05, function()
			        RecursiveDisplayIn(v)
			    end)
			end
		elseif confirmcheck then
			if CollectionService:HasTag(v, "TransitionDown") then
			    Transitions:TransitionDown(v, false)
			elseif CollectionService:HasTag(v, "TransitionUp") then
			    Transitions:TransitionUp(v, false)
			end
			
			if #v:GetChildren() > 0 then
				delay(0.05, function()
					RecursiveDisplayIn(v)
				end)
			end
		end
	end
end

local function RecursiveDisplayOut(obj)
	for i, v in ipairs(obj:GetChildren()) do
		Transitions:TweenOut(v)

		if #v:GetChildren() > 0 then
			delay(0.05, function()
				RecursiveDisplayOut(v)
			end)
		end
	end
end

function DialogueController:sortPrompts(promptsFolder)
    local initprompt = promptsFolder[1].Value
    if #promptsFolder > 1 then
        for i = 1, #promptsFolder do
            local prompt = promptsFolder[i].Value
            local t
            if prompt:FindFirstChild("Condition") then
                t = require(prompt.Condition)(self.Player)
            end
            if t or i == #promptsFolder then initprompt = prompt break end 
        end
    end

    local data
    if initprompt:FindFirstChild("DataScript") then
        data = require(initprompt:FindFirstChild("DataScript"))
        if data.server then
            data = self.Services.DialogueService:ProcessData(initprompt:FindFirstChild("DataScript"))
        end 
    end

    local Responses = initprompt:FindFirstChild("Responses")
    if Responses then Responses = Responses:GetChildren() end

    local Prompts = initprompt:FindFirstChild("Prompts")
    if Prompts then Prompts = Prompts:GetChildren() end

    local promptTable = {
        Line = initprompt.Line.Value;
        Responses = Responses;
        Prompts = Prompts;
        Data = data or {};

        node = initprompt;
    }
    return promptTable
end

function DialogueController:clearResponses()
    if not self.Dialogue then return end
    local ResponsesFrame = self.Dialogue:FindFirstChild("Responses", true)
	if not ResponsesFrame then return end
	for _, child in pairs(ResponsesFrame:GetChildren()) do
		if child.Name == "ResponseFrame" then
			local info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)

			TweenService:Create(child.ResponseBox, info, {BackgroundTransparency = 1}):Play()
			
			for i, v in ipairs(child.ResponseBox:GetDescendants()) do
				if v:IsA("TextLabel") then
					TweenService:Create(v, info, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
				end
			end

			delay(0.11, function()
				child:Destroy()
			end)
		end
	end
end

local function showResponse(nResponse, line)
    local RichPromptText = RichText:New(
        nResponse:FindFirstChild("ResponseBox", true),
        line,
        {
            ContainerVerticalAlignment = "Center",
            ContainerHorizontalAlignment = "Center",
            Font = Enum.Font.Gotham,
            TextColor3 = "240,234,207",
            TextScale = 0.33
        },
        false
    )
    nResponse.ResponseBox.BackgroundTransparency = 1
    
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
    TweenService:Create(nResponse.ResponseBox, info, {BackgroundTransparency = 0.2}):Play()
    if not UserInputService.TouchEnabled then
        RichPromptText:Animate(true)
    else
        RichPromptText:Show(false)
    end
end

function DialogueController:EndDialogue()
    self.inDialogue = false
    if self.Dialogue then
		if self.Dialogue:FindFirstChild("Main") == nil then self.inDialogue = false return end
		self:clearResponses()

		
		TweenService:Create(self.Dialogue.Main.Background, TweenInfo.new(0.5), {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 1.5, 0);
		}):Play()
		
		TweenService:Create(self.Dialogue.Main.Background.NPCName, TweenInfo.new(0.5), {
			TextTransparency = 1;
		}):Play()
		
		for i, v in ipairs(self.Dialogue.Main.Background.NPCPrompt:GetChildren()) do
			if v:IsA("TextLabel") then
				TweenService:Create(v, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			end
		end
		
		delay(0.6, function()
			self.Dialogue:Destroy()
			self.Dialogue = nil
			
			self.Controllers.Camera.PlayerCamera._MenuLock:Fire(true)
		end)
    end
    
    local posBase = self.Player:WaitForChild("PlayerGui"):FindFirstChild("DialogueBase")
    if posBase then
        posBase:Destroy()
    end
end

-- @param thisPrompt a folder containing info about the prompt
function DialogueController:DisplayPrompt(promptTable, chained)
	--update prompt data
	local data = promptTable.Data
    -- print(repr(promptTable.Data))
	local QuestDisplay = self.Dialogue.Main.QuestDisplay
	if data.Quest ~= nil then
		local QuestData = data.Quest
		QuestDisplay.Title.Description.Text = QuestData.DisplayName
        QuestDisplay.DescFrame.Description.Text = QuestData.Desc

        for i,v in ipairs(QuestDisplay.Objectives:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        for ObjectiveType, ObjectiveTable in pairs(QuestData.Objectives) do
			for Target, Objective in pairs(ObjectiveTable) do

				local pattern = "%u+%l*"
				local NewName = ""
				for v in Target:gmatch(pattern) do
					NewName = NewName .. v .. " "
				end
				if string.len(NewName) > 1 then
					NewName = string.sub(NewName, 1, string.len(NewName)-1)
				end

                local NewObjective = self.Dialogue.Resources.Item:Clone()
				NewObjective.Visible = true
				
				if ObjectiveType == "KILL" or ObjectiveType == "GATHER" then
                    NewObjective.Text = ":: [" .. ObjectiveType .. "] " .. tostring(Objective) .. " " .. NewName .. (Objective > 1 and "s." or ".") .. " (" .. tostring(0) .. "/" .. tostring(Objective) .. ")"
        
				elseif ObjectiveType == "TALK" then
					NewObjective.Text = ":: TALK to " .. NewName 
                end
                
				NewObjective.Parent = QuestDisplay.Objectives
			end
        end

        for i,v in ipairs(QuestDisplay.Rewards:GetChildren()) do
            if v:IsA("GuiObject") then
                v:Destroy()
            end
        end

        for RewardName, Reward in pairs(QuestData.Rewards) do
            if typeof(Reward) == "number" then
                local rname = RewardName
                if RewardName == "GOLD" then
                    rname = "Munny"
                end
                local NewReward = self.Dialogue.Resources.Item:Clone()
                NewReward.Text = tostring(Reward) .. " " .. rname
                NewReward.Parent = QuestDisplay.Rewards
            elseif typeof(Reward) == "table" then
                for i, item in pairs(Reward) do
                    local NewReward = self.Dialogue.Resources.Item:Clone()
                    NewReward.Text = item
                    NewReward.Parent = QuestDisplay.Rewards
                end
            end
        end
		
		QuestDisplay.Visible = true
		
		RecursiveDisplayIn(QuestDisplay)
    else
        RecursiveDisplayOut(QuestDisplay)
		delay(1, function()
			QuestDisplay.Visible = false
		end)
	end
	
    --update portrait image
    local portrait = self.Dialogue:FindFirstChild("Portrait", true)
    if data.PortraitImage then
        portrait.Image = data.PortraitImage
        if data.PortraitSize and data.PortraitOffset then
            portrait.ImageRectOffset = data.PortraitOffset
            portrait.ImageRectSize = data.PortraitSize
            portrait.ScaleType = Enum.ScaleType.Fit
        end
    else
        portrait.Image = ""
    end

	--update title text
	local titleText = self.Dialogue:FindFirstChild("NPCName", true)
	titleText.Text = ""
	if data.Title then
        titleText.Text = data.Title
    else
        titleText.Text = promptTable.node:FindFirstAncestorOfClass("Model").Name
	end

    -- process prompt action
    if promptTable.node:FindFirstChild("Action") then
        self.Services.DialogueService:ProcessNode(promptTable.node, "Action")
    end

	--display animated text
	local PromptBox = self.Dialogue:FindFirstChild("NPCPrompt", true)
	assert(PromptBox ~= nil, "Could not find prompt box")
	local RichPromptText = RichText:New(
		PromptBox,
		data.ExtendedLine or promptTable.Line,
		{
			ContainerVerticalAlignment = "Top",
			ContainerHorizontalAlignment = "Left",
			Font = Enum.Font.Gotham,
			TextColor3 = "240,234,207"
		},
		false
	)
	
	if not UserInputService.TouchEnabled then
		RichPromptText:Animate(true)
	else
		RichPromptText:Show(false)
	end

	if RichPromptText.Overflown then
		wait(0.5)
		local OverflowText = RichText:ContinueOverflow(PromptBox, RichPromptText)
		if OverflowText.Overflown then
			repeat
				wait(0.5)
				local Overflown = RichText:ContinueOverflow(PromptBox, OverflowText)
			until OverflowText.Overflown == false
		end
    end
    
    if not self.Dialogue then
        self:EndDialogue()
        return
    end
    local BaseResponse = self.Dialogue:WaitForChild("Resources"):FindFirstChild("ResponseFrame")
    local Responses = self.Dialogue:FindFirstChild("Responses", true)

    if promptTable.Prompts then -- chain the prompts!@!
        wait(1)
        local nResponse = BaseResponse:Clone()
        nResponse.LayoutOrder = index
        nResponse.Parent = Responses
        nResponse.Visible = true

        local Button = nResponse:WaitForChild("Button")

        self.ButtonMaid:GiveTask(Button.Activated:Connect(function()
            self.ButtonMaid:DoCleaning()
            self:clearResponses()

            -- print(#promptTable.Prompts)
            local nextPrompt = self:sortPrompts(promptTable.Prompts)
            self:DisplayPrompt(nextPrompt)
        end))

        showResponse(nResponse, "C O N T I N U E")
        
    elseif promptTable.Responses then -- display responses
        print("displaying responses...")
        

        if #promptTable.Responses == 0 then
            -- end dialogue after delay
            print("ending dialogue...")
            wait(EndFadeTime)
            self:EndDialogue()
            return
        end

        wait(1)
        table.sort(promptTable.Responses, function(a, b)
            local aref = a.Value
            local bref = b.Value

            if aref and bref then
                local aorder = aref.Order
                local border = bref.Order
                return aorder.Value < border.Value
            else
                return true
            end
        end)

        for index, responseRef in ipairs(promptTable.Responses) do
            local response = responseRef.Value

            local Condition = response:FindFirstChild("Condition")
            if Condition then
                if not require(Condition)(self.Player) then print(response, "false") continue end
            else
                print(response, "no condition")
            end

            local nResponse = BaseResponse:Clone()
            nResponse.LayoutOrder = response:FindFirstChild("Order").Value
            nResponse.Parent = Responses
            nResponse.Visible = true            
            
            nResponse.Button.Activated:Connect(function()
                self.ButtonMaid:DoCleaning()
                self:clearResponses()
                local Action = response:FindFirstChild("Action")
                if Action then
                    print("processing Action", response)
                    require(Action)()
                    print("processed client action...")
                    self.Services.DialogueService:ProcessNode(response, "Action")
                    print("processed server action...")
                end

                local nextPromptsFolder = response:FindFirstChild("Prompts")
                if nextPromptsFolder then
                    local nextPrompts = nextPromptsFolder:GetChildren()
                    if #nextPrompts > 0 then
                        local nextPrompt = self:sortPrompts(nextPrompts)
                        self:DisplayPrompt(nextPrompt)
                    else
                        -- delay acouple then endDialogue
                        wait(EndFadeTime)
                        self:EndDialogue()
                    end
                end
            end)

            -- display response method
            showResponse(nResponse, response.Line.Value)
        end
    else
        print('ending dialogue...')
        delay(EndFadeTime, function()
            self:EndDialogue()
        end)
    end
end

    -- use DisplayPrompt recursion to handle all prompts.
function DialogueController:StartDialogue(srcFolder)
    -- ensure that this is a valid NPC   
    if not srcFolder:FindFirstAncestor("NPCs") then return end
    
    -- get initial prompts, sort them by order
        -- sort by descending
    local InitialPrompts = srcFolder.InitialPrompts:GetChildren()
    print('#initprompts', #InitialPrompts)
    table.sort(InitialPrompts, function(asrc, bsrc)
        local a = asrc.Value
        local b = bsrc.Value
        local apri = a:FindFirstChild("Priority")
        local bpri = b:FindFirstChild("Priority")
        if apri and bpri then
            return apri.Value > bpri.Value
        end

        return true
    end)
    -- determine an initial prompt
    
    local initprompt = self:sortPrompts(InitialPrompts)
    -- print('initprompt:', initprompt)

    if initprompt then
        -- create new dialogue
        self.Dialogue = DialogueBase:Clone()
        local Background = self.Dialogue.Main.Background
        Background.Position = UDim2.new(0, 0, 1.5, 0)
        Background.BackgroundTransparency = 1
        
        self.Dialogue.Parent = self.Player:WaitForChild("PlayerGui")

        TweenService:Create(Background, TweenInfo.new(0.5), {
			BackgroundTransparency = 0.3,
			Position = UDim2.new(0, 0, 1, 0)
		}):Play()
        self.inDialogue = srcFolder.Parent
        self.Controllers.Camera.PlayerCamera._MenuLock:Fire(false)
        self:DisplayPrompt(initprompt, false)
        return true
    end

    return false
end


function DialogueController:Start()
    if self.__aeroPreventStart then return end
    -- establish NPCs

    --[[
        when establishing, make sure to watch for parts added to. 
        *set the adornee whenever the primary part is added
    ]]
    local npcs = workspace.NPCs:GetChildren()
    local pgui = self.Player:WaitForChild("PlayerGui")

    local baseTrigger = ReplicatedStorage.Assets.Interface.Dialogue:FindFirstChild("DialogueTrigger")

    local triggers = {}
    for _, npc in ipairs(npcs) do
        --establish the parts added thing
        if npc:IsA("Model") then

            -- insert trigger here
            local newTrigger = baseTrigger:Clone()
            newTrigger.Parent = pgui
            
            newTrigger.Adornee = npc
            newTrigger.Enabled = false
            triggers[npc] = newTrigger

            if GIC.LastInput == Enum.UserInputType.Keyboard then
                newTrigger.Trigger.Text = "[Y] Talk to " .. npc.Name
            end

            if GIC.LastInput == Enum.UserInputType.Touch or GIC.TouchEnabled then
                newTrigger.Trigger.Text = "[Tap] Talk to " .. npc.Name
            end

            newTrigger.Trigger.Activated:Connect(function()
                local RobloxDialogue = npc:WaitForChild("RobloxDialogue")
                local t = self:StartDialogue(RobloxDialogue)
                print(t)
            end)
        end
    end

    workspace.NPCs.ChildRemoved:Connect(function(child)
        if triggers[child] then
            triggers[child] = nil
        end
    end)

    -- connect actual prompt triggers
    -- keyboard
    local InstanceCache = {}
    local function CheckTargetInstance()
        local TargetInstance = self.Controllers.Targeting.TargetInstance
        if TargetInstance then
            if InstanceCache[TargetInstance] == nil then
                if not CollectionService:HasTag(TargetInstance, "NPC") then
                    InstanceCache[TargetInstance] = false
                    return false
                else
                    InstanceCache[TargetInstance] = true
                    return true
                end
            else
                return InstanceCache[TargetInstance]
            end
        end
        return false
    end

    local function HideAllTriggers()
        for i, v in pairs(triggers) do
            v.Enabled = false
        end
    end

    UserInputService.InputBegan:Connect(function(input)
        if self.inDialogue then return end
        if self.Controllers.GlobalInputController.TextBoxFocused then return end

        local TargetInstance = self.Controllers.Targeting.TargetInstance
        if CheckTargetInstance() then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Y then
                    -- display the prompt
                    print('starting dialogue...')
                    local RobloxDialogue = TargetInstance.Parent:WaitForChild("RobloxDialogue")
                    local t = self:StartDialogue(RobloxDialogue)
                    print(t)
                    -- print('ended dialogue...')
                end
            elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
                if input.KeyCode == Enum.KeyCode.ButtonX then
                    -- check Gamepad Context Controller (mainly for altering the X/Y button actions)
                    
                end
            end
        end
    end)

    -- trigger loop; mainly for displaying the prompts, nothing more. logic handled above
    local targetingNpc = false
    local lastTargetInstance = nil
    while true do
        targetingNpc = false
        wait(1/10)
        
        -- check if NPC is near player
        -- check if the player has a target to display prompt
        if self.Controllers.Character.Character then

            if self.inDialogue then
                -- check distance to player
                if (self.inDialogue.PrimaryPart.Position-self.Player.Character.PrimaryPart.Position).Magnitude > 15 then
                    self:EndDialogue()
                end
                HideAllTriggers()
                continue
            end

            local TargetInstance = self.Controllers.Targeting.TargetInstance
            if lastTargetInstance ~= TargetInstance then
                lastTargetInstance = TargetInstance
                -- print(lastTargetInstance)
                
                -- if the player is on mobile, disregard this and display all

                if CheckTargetInstance() then 
                    -- print('1ti')
                    local npc = TargetInstance.Parent
                    if npc:IsA("Model") then
                        -- print('2ti')
                        local thisTrigger = triggers[npc]
                        if thisTrigger then

                            HideAllTriggers()
                            thisTrigger.Enabled = true
                        end
                    end
                else
                    HideAllTriggers()
                end
            end
        end
    end
end

function DialogueController:Init()
    if self.__aeroPreventStart then return end

    self.inDialogue = false
    self.ActivePrompt = false
    self.Dialogue = nil

    self:RegisterEvent("DialogueStart")
    self:RegisterEvent("DialogueEnd")

    
    GIC = self.Controllers.GlobalInputController
    
    RichText = self.Modules.RichText
    Transitions = self.Modules.Transitions
    
    FastSpawn = self.Shared.FastSpawn
    repr = self.Shared.repr
    
    Maid = self.Shared.Maid
    self.ButtonMaid = Maid.new()
end

return DialogueController