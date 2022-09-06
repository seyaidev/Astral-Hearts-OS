-- Progress Controller
-- Username
-- November 22, 2019


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressController = {}


function ProgressController:Start()
    local SaveNotif = ReplicatedStorage.Assets.Interface:WaitForChild("SaveNotif"):Clone()
    SaveNotif.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    PlayerService.SaveNotif:Connect(function(result)
        if not SaveNotif.Enabled then
            SaveNotif.Enabled = true
        end
        if result == 0 then
            --save failed
            SaveNotif.Label.Text = "Data cache failed! Retrying..."
        elseif result == 1 then
            --save success
            SaveNotif.Label.Text = "Data cached!"
        elseif result == 2 then
            SaveNotif.Label.Text = "Caching data..."
        elseif result == 3 then
            SaveNotif.Label.Text = "Saving to server..."
        elseif result == 4 then
            SaveNotif.Label.Text = "Saved to server!"

        elseif result == 5 then
            SaveNotif.Label.Text = "Data currently locked, retry later"
        end
        delay(1.5, function() SaveNotif.Enabled = false end)
    end)
end


function ProgressController:Init()
	PlayerService = self.Services.PlayerService
end


return ProgressController