function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local Library = {
	["stun"]		= 2138143850;
}

setDefault(Library, 2215289958)

return Library