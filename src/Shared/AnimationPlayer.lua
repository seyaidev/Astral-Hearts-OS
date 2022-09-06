--- Makes playing and loading tracks into a humanoid easy
-- @classmod AnimationPlayer

local Signal = require(script.Parent:WaitForChild("Event"))

local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer
AnimationPlayer.ClassName = "AnimationPlayer"

--- Constructs a new animation player
-- @constructor
-- @tparam Humanoid Humanoid
function AnimationPlayer.new(Humanoid)
	local self = setmetatable({}, AnimationPlayer)
	-- if type(Humanoid) == "table" then
	-- 	for i, v in pairs(Humanoid) do
	-- 		print(i, v)
	-- 	end
	-- end
	self.Humanoid = Humanoid or error("No Humanoid")
	self.Tracks = {}
	self.FadeTime = 0.1 -- Default

	self.TrackPlayed = Signal.new()

	return self
end

--- Adds an animation to use
function AnimationPlayer:ClearAllTracks()
	for i, v in pairs(self.Tracks) do
		self.Tracks[i]:Destroy()
		self.Tracks[i] = nil
	end
	return self
end

function AnimationPlayer:RemoveTrack(Name)
	if self.Tracks[Name] ~= nil then
		self.Tracks[Name]:Destroy()
	end

	self.Tracks[Name] = nil
	return self
end

function AnimationPlayer:WithAnimation(Animation)
	self.Tracks[Animation.Name] = self.Humanoid:LoadAnimation(Animation)

	return self.Tracks[Animation.Name]
end

--- Adds an animation to play
function AnimationPlayer:AddAnimation(Name, AnimationId)
	local Animation = Instance.new("Animation")

	if tonumber(AnimationId) then
		Animation.AnimationId = "http://www.roblox.com/Asset?ID=" .. tonumber(AnimationId) or error("No AnimationId")
	else
		Animation.AnimationId = AnimationId
	end

	Animation.Name = Name or error("No name")

	return self:WithAnimation(Animation)
end

--- Returns a track in the player
function AnimationPlayer:GetTrack(TrackName)
	return self.Tracks[TrackName] --or error("Track does not exist")
end

---Plays a track
-- @tparam string TrackName Name of the track to play
-- @tparam[opt=0.4] number FadeTime How much time it will take to transition into the animation.
-- @tparam[opt=1] number Weight Acts as a multiplier for the offsets and rotations of the playing animation
	-- This parameter is extremely unstable.
	-- Any parameter higher than 1.5 will result in very shaky motion, and any parameter higher '
	-- than 2 will almost always result in NAN errors. Use with caution.
-- @tparam[opt=1] number Speed The time scale of the animation.
	-- Setting this to 2 will make the animation 2x faster, and setting it to 0.5 will make it
	-- run 2x slower.
-- @tparam[opt=0.4] number StopFadeTime
function AnimationPlayer:PlayTrack(TrackName, FadeTime, Weight, Speed, StopFadeTime)
	FadeTime = FadeTime or self.FadeTime
	local Track = self:GetTrack(TrackName)

	if not Track.IsPlaying then
		self.TrackPlayed:Fire(TrackName, FadeTime, Weight, Speed, StopFadeTime)

		self:StopAllTracks(StopFadeTime or FadeTime)
		Track:Play(FadeTime, Weight, Speed)
	end

	return Track
end

--- Stops a track from being played
-- @tparam string TrackName
-- @tparam[opt=0.4] number FadeTime
-- @treturn AnimationTrack
function AnimationPlayer:StopTrack(TrackName, FadeTime)
	FadeTime = FadeTime or self.FadeTime

	local Track = self:GetTrack(TrackName)

	Track:Stop(FadeTime)

	return Track
end

--- Stops all tracks playing
function AnimationPlayer:StopAllTracks(FadeTime)
	for TrackName, _ in pairs(self.Tracks) do
		self:StopTrack(TrackName, FadeTime)
	end
end

function AnimationPlayer:GetTracks()
	return self.Tracks
end
---
function AnimationPlayer:Destroy()
	self:StopAllTracks()
	setmetatable(self, nil)
end

return AnimationPlayer