local Info = {}

for i, v in pairs(script:GetDescendants()) do
    if v:IsA("ModuleScript") then
        Info[v.Name] = require(v)
        Info[v.Name].Id = v.Name
        Info[v.Name].ItemId = v.Name
    end
end

return Info