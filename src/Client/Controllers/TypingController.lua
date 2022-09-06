local TypingController = {}

local UserInputService = game:GetService("UserInputService")

function TypingController:Start()
    UserInputService.TextBoxFocused:Connect(function()
        self.IsTyping = true
    end)

    UserInputService.TextBoxFocusReleased:Connect(function()
        self.IsTyping = false
    end)
end

function TypingController:Init()
    self.IsTyping = false
end

return TypingController