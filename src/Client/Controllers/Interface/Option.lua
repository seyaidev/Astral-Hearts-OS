-- Option
-- Username
-- February 11, 2020



local Option = {}

local InterfaceMain
local UserInput
local Keyboard
local Gamepad
local CharacterController
local ZoneController
local Buttonify
local AutoGrid
local Gui3DCore
local Maid
local TableUtil
local WeaponManipulation
local GlobalData
local GlobalMath

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

function Option.Connect(InterfaceMain)
    InterfaceMain = InterfaceMain

    UserInput = InterfaceMain.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = InterfaceMain.Controllers.Character
    ZoneController = InterfaceMain.Controllers.ZoneController

    Buttonify = InterfaceMain.Modules.Buttonify
    AutoGrid = InterfaceMain.Modules.AutoGrid

    Gui3DCore = InterfaceMain.Shared["3DGuiCore"]
    Maid = InterfaceMain.Shared.Maid
    TableUtil = InterfaceMain.Shared.TableUtil

    GlobalData = InterfaceMain.Shared.GlobalData
    GlobalMath = InterfaceMain.Shared.GlobalMath
    Transitions = InterfaceMain.Modules.Transitions
    
    Option.Maid = Maid.new()

    table.insert(InterfaceMain.ActiveMaids, Option.Maid)

    local EditOption = InterfaceMain.Services.PlayerService.EditOption

    local OptionMenu = InterfaceMain.FullMenu.Main.MainPanel.OptionsMenu

    for i, v in ipairs(OptionMenu.Options:GetChildren()) do
        if v:IsA("Frame") then
            if InterfaceMain.Controllers.DataBlob.Options[v.Name] ~= nil then
                local result = InterfaceMain.Controllers.DataBlob.Options[v.Name]
                local display = OptionMenu:FindFirstChild(v.Name, true)

                if typeof(result) == "boolean" then
                    display.Radio.Text = result and "X" or ""

                    display.Button.Activated:Connect(function()
                        InterfaceMain.Controllers.DataBlob.Options[v.Name] = not InterfaceMain.Controllers.DataBlob.Options[v.Name]
                        InterfaceMain.Services.PlayerService.EditOption:Fire(v.Name, InterfaceMain.Controllers.DataBlob.Options[v.Name])


                        local result = InterfaceMain.Controllers.DataBlob.Options[v.Name]
                        local radio = display.Radio
                        if result then
                            radio.Text = "X"
                        else
                            radio.Text = ""
                        end

                        print(v.Name, result)
                    end)
                end
            end
        end
    end
end


return Option