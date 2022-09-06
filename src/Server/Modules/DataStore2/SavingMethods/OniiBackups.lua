--[[
	berezaa's method of saving data (from the dev forum):

	What I do and this might seem a little over-the-top but it's fine as long as you're not using datastores
	excessively elsewhere is have a datastore and an ordereddatastore for each player. When you perform a save,
	add a key (can be anything) with the value of os.time() to the ordereddatastore and save a key with the os.time()
	and the value of the player's data to the regular datastore. Then, when loading data, get the highest number from
	the ordered data store (most recent save) and load the data with that as a key.

	Ever since I implemented this, pretty much no one has ever lost data. There's no caches to worry about either
	because you're never overriding any keys. Plus, it has the added benefit of allowing you to restore lost data,
	since every save doubles as a backup which can be easily found with the ordereddatastore

	edit: while there's no official comment on this, many developers including myself have noticed really bad cache
	times and issues with using the same datastore keys to save data across multiple places in the same game. With
	this method, data is almost always instantly accessible immediately after a player teleports, making it useful
	for multi-place games.

	ONII EDITS:
	- locking before saves
		make sure data is not being manipulated elsewhere (like in the title menu/other places)
		achieve this with a combo of MessagingService + Data stores, much like the gift service
		* replace this with ephermeal data stores whenever those decide to get dropped
	- automatic retries on set
		simple repeat-until w/ retry override
--]]

local DataStoreService = game:GetService("DataStoreService")
-- local MessagingService = game:GetService("MessagingService")
local LockStore = DataStoreService:GetDataStore("Lock")


local Promise = require(script.Parent.Parent.Promise)
local repr = require(game.ReplicatedStorage.Aero:FindFirstChild("repr", true))
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local OniiBackups = {}
OniiBackups.__index = OniiBackups

function OniiBackups:Get()
	return Promise.async(function(resolve)
		resolve(self.orderedDataStore:GetSortedAsync(false, 1):GetCurrentPage()[1])
	end):andThen(function(mostRecentKeyPage)
		if mostRecentKeyPage then
			local recentKey = mostRecentKeyPage.value
			self.dataStore2:Debug("most recent key", mostRecentKeyPage)
			self.mostRecentKey = recentKey

			return Promise.async(function(resolve)
				resolve(self.dataStore:GetAsync(recentKey))
			end)
		else
			self.dataStore2:Debug("no recent key")
			return nil
		end
	end)
end

function OniiBackups:Set(value)
	local key = (self.mostRecentKey or 0) + 1
	local aeroServer = _G.AeroServer
	local Player = game.Players:GetPlayerByUserId(self.dataStore2.UserId)

	return Promise.async(function(resolve, reject)
		if aeroServer and Player then
			if aeroServer.Services.PlayerService then
				aeroServer.Services.PlayerService:FireClientEvent("SaveNotif", Player, 3)
			end
		end

		local s, message = pcall(function() self.dataStore:SetAsync(key, value) end)
		if s then
			resolve()
		else
			local s, message = false, nil
			local Retry = 0
			repeat
				Retry = Retry+1
				wait(6.1)
				s, message = pcall(function() self.dataStore:SetAsync(key, value) end)
			until s or Retry >= 3
			if not s or RunService:IsStudio() then
				if aeroServer then
					if aeroServer.Services.RavenService and aeroServer.Services.PlayerService then
						aeroServer.Services.RavenService:FireEvent("RavenDebug",
							"Data_" .. tostring(self.dataStore2.UserId) .. "<" .. HttpService:JSONEncode(value) .. ">",
							"Info"
						)

						aeroServer.Services.PlayerService:FireEvent("IsBackup", Player)
					end
				end
			end
			resolve()
		end
	end):andThen(function()
		return Promise.promisify(function()
			self.orderedDataStore:SetAsync(key, key)
		end)()
	end):andThen(function()
		self.mostRecentKey = key
		local Player = game.Players:GetPlayerByUserId(self.dataStore2.UserId)

		-- MessagingService:PublishAsync("SaveLock", "ULK" .. tostring(self.dataStore2.UserId))

		if aeroServer and Player then
			if aeroServer.Services.PlayerService then
				aeroServer.Services.PlayerService:FireClientEvent("SaveNotif", Player, 4)
			end
		end
	end)
end

function OniiBackups.new(dataStore2)
	local dataStoreKey = dataStore2.Name .. "/" .. dataStore2.UserId

	local info = {
		dataStore2 = dataStore2,
		dataStore = DataStoreService:GetDataStore(dataStoreKey),
		orderedDataStore = DataStoreService:GetOrderedDataStore(dataStoreKey),
	}

	return setmetatable(info, OniiBackups)
end

return OniiBackups