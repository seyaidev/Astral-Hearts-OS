-- Global Input Controller
-- Username
-- September 10, 2019


local UserInputService = game:GetService("UserInputService")
local GlobalInputController = {__aeroOrder = 9;}


function GlobalInputController:Start()
    self.InputMaid = Maid.new()
    
    self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
        self.InputMaid:DoCleaning()
        wait()

        self.InputMaid:GiveTask(UserInputService.TextBoxFocused:Connect(function()
            self.TextBoxFocused = true
        end))

        self.InputMaid:GiveTask(UserInputService.TextBoxFocusReleased:Connect(function()
            self.TextBoxFocused = false
        end))
    end)
end

function GlobalInputController:Init()
    self.TextBoxFocused = false
    self.LastInput = Enum.UserInputType.Keyboard
    self.TouchEnabled = UserInputService.TouchEnabled

    UserInputService.LastInputTypeChanged:Connect(function(input)
        if input ~= Enum.UserInputType.Keyboard 
        and input ~= Enum.UserInputType.Touch 
        and input ~= Enum.UserInputType.Gamepad1 then return end
        self.LastInput = input
    end)
    
    Maid = self.Shared.Maid
end


return GlobalInputController