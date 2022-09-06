local SkillsCache = {}

local stuff = {}

for i, v in pairs(script:GetDescendants()) do
	if v:IsA("ModuleScript") then
		stuff[v.Name] = require(v)
		stuff[v.Name].LocalInfo.SkillId = v.Name
	end
end

function SkillsCache:Get(name)
	return stuff[name]
end

return SkillsCache