local module = {}


local loadedcache = {}
for i, v in pairs(script:GetChildren()) do
	loadedcache[v.Name] = require(v)
end

function module:Get(name)
	return loadedcache[name]
end

return module
