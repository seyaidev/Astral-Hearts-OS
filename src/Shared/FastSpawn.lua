-- You should use the benchmarker to compare this one to the one you have. :P

local SpawnEvent = Instance.new("BindableEvent")
SpawnEvent.Event:Connect(function(Function, Pointer) Function(Pointer()) end)

local function FastSpawn(Function, ...)
	local Length = select("#", ...)
	local Arguments = {...}
	SpawnEvent:Fire(Function, function() return unpack(Arguments, 1, Length) end)
end

return FastSpawn