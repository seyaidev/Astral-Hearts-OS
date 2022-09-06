-- Rbx Web Hook
-- oniich_n
-- August 3, 2019


local RbxWebHook = {Client = {}}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GlobalData
local RbxWeb

function RbxWebHook:GetStore(NAME, perma)
    if self.Initialized == false then repeat wait() until self.Initialized end
    if self.DataModels[NAME] == nil then
        if not perma then
            print(NAME .. (RunService:IsStudio() and "Testing" or "Release") .. "_" .. GlobalData.DATA_VERSION)
            self.DataModels[NAME] = RbxWeb:AddGeneric(
                NAME .. (RunService:IsStudio() and "Testing" or "Release") .. "_" .. GlobalData.DATA_VERSION,
                "Global"
            )
        else
            self.DataModels[NAME] = RbxWeb:AddGeneric(
                NAME .. (RunService:IsStudio() and "Testing" or "Release"),
                "Global"
            )
        end
    end

    if self.HookedModels[NAME] == nil and self.DataModels[NAME] then
        self.HookedModels[NAME] = RbxWeb:GetGeneric(self.DataModels[NAME])
    end

    return self.HookedModels[NAME]
end

function RbxWebHook:Start()
end

function RbxWebHook:Init()
    self.Initialized = false
    self.DataModels = {}
    self.HookedModels = {}

    GlobalData = self.Shared.GlobalData
    
    RbxWeb = self.Modules.RbxWeb
    if RunService:IsStudio() then
        print("using mock...")
        RbxWeb:Initialize(require)
        -- RbxWeb:Initialize(game)
    else
        print("using live...")
        RbxWeb:Initialize(game)
    end
    self.Initialized = true
end


return RbxWebHook