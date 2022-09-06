local module = {}

local Params = {}
for i, v in pairs(script:GetChildren()) do
    Params[v.Name] = require(v)
end

function module:Get(Name)
    return Params[Name]
end

return module