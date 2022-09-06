-- Social
-- Username
-- February 13, 2020



local Social = {}

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
local Attachments = require(ReplicatedStorage:FindFirstChild("Attachments", true))

function Social.Connect(InterfaceMain)
    InterfaceMain = InterfaceMain

    UserInput = InterfaceMain.Controllers.UserInput

    Keyboard = UserInput:Get("Keyboard")
	Mouse = UserInput:Get("Mouse")
	Gamepad = UserInput:Get("Gamepad")
    CharacterController = InterfaceMain.Controllers.Character
    ZoneController = InterfaceMain.Controllers.ZoneController

    SlideButton = InterfaceMain.Modules.SlideButton
    Buttonify = InterfaceMain.Modules.Buttonify
    AutoGrid = InterfaceMain.Modules.AutoGrid

    Gui3DCore = InterfaceMain.Shared["3DGuiCore"]
    Maid = InterfaceMain.Shared.Maid
    TableUtil = InterfaceMain.Shared.TableUtil
    WeaponManipulation = InterfaceMain.Shared.WeaponManipulation
    GlobalData = InterfaceMain.Shared.GlobalData
    GlobalMath = InterfaceMain.Shared.GlobalMath
    Transitions = InterfaceMain.Modules.Transitions

    Social.Maid = Maid.new()
    table.insert(InterfaceMain.ActiveMaids, Social.Maid)

    --display party
    
    --connect to party events, then update accordingly
end

return Social