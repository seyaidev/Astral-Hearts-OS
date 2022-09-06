-- The core resource manager and library loader for RoStrap
-- @rostrap Resources
-- It is designed to increase organization and streamline the retrieval and networking of resources.
-- @documentation https://rostrap.github.io/Resources/
-- @source https://github.com/RoStrap/Resources/
-- @author Validark

local RunService = game:GetService("RunService")

local Metatable = {}
local Resources = setmetatable({}, Metatable)
local Caches = {} -- All cached data within Resources is accessible through Resources:GetLocalTable()

local Instance_new, type, require = Instance.new, type, require
local LocalResourcesLocation

local SERVER_SIDE = RunService:IsServer()
local UNINSTANTIABLE_INSTANCES = setmetatable({
	Folder = false; RemoteEvent = false; BindableEvent = false;
	RemoteFunction = false; BindableFunction = false; Library = true;
}, {
	__index = function(self, InstanceType)
		local Instantiable, GeneratedInstance = pcall(Instance_new, InstanceType)
		local Uninstantiable

		if Instantiable and GeneratedInstance then
			GeneratedInstance:Destroy()
			Uninstantiable = false
		else
			Uninstantiable = true
		end

		self[InstanceType] = Uninstantiable
		return Uninstantiable
	end;
})

function Resources:GetLocalTable(TableName) -- Returns a cached table by TableName, generating if non-existant
	TableName = self ~= Resources and self or TableName
	local Table = Caches[TableName]

	if not Table then
		Table = {}
		Caches[TableName] = Table
	end

	return Table
end

local function GetFirstChild(Folder, InstanceName, InstanceType)
	local Object = Folder:FindFirstChild(InstanceName)

	if not Object then
		if UNINSTANTIABLE_INSTANCES[InstanceType] then error("[Resources] " .. InstanceType .. " \"" .. InstanceName .. "\" is not installed within " .. Folder:GetFullName() .. ".", 2) end
		Object = Instance_new(InstanceType)
		Object.Name = InstanceName
		Object.Parent = Folder
	end

	return Object
end

function Metatable:__index(MethodName)
	if type(MethodName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2) end
	if MethodName:sub(1, 3) ~= "Get" then error("[Resources] Methods should begin with \"Get\"", 2) end
	local InstanceType = MethodName:sub(4)

	-- Set CacheName to ["RemoteEvent" .. "s"], or ["Librar" .. "ies"]
	local a, b = InstanceType:byte(-2, -1) -- this is a simple gimmick but works well enough for all Roblox ClassNames :D
	local CacheName = b == 121 and a ~= 97 and a ~= 101 and a ~= 105 and a ~= 111 and a ~= 117 and InstanceType:sub(1, -2) .. "ies" or InstanceType .. "s"
	local IsLocal = InstanceType:sub(1, 5) == "Local"
	local Cache, Folder, FolderGetter -- Function Constants

	if IsLocal then -- Determine whether a method is local
		InstanceType = InstanceType:sub(6)

		if InstanceType == "Folder" then
			FolderGetter = function() return GetFirstChild(LocalResourcesLocation, "Resources", "Folder") end
		else
			FolderGetter = Resources.GetLocalFolder
		end
	else
		if InstanceType == "Folder" then
			FolderGetter = function() return script end
		else
			FolderGetter = Resources.GetFolder
		end
	end

	local function GetFunction(this, InstanceName)
		InstanceName = this ~= self and this or InstanceName
		if type(InstanceName) ~= "string" then error("[Resources] " .. MethodName .. " expected a string parameter, got " .. typeof(InstanceName), 2) end

		if not Folder then
			Cache = Caches[CacheName]
			Folder = FolderGetter(IsLocal and CacheName:sub(6) or CacheName)

			if not Cache then
				Cache = Folder:GetChildren() -- Cache children of Folder into Table
				Caches[CacheName] = Cache

				for i = 1, #Cache do
					local Child = Cache[i]
					Cache[Child.Name] = Child
					Cache[i] = nil
				end
			end
		end

		local Object = Cache[InstanceName]

		if not Object then
			if SERVER_SIDE or IsLocal then
				Object = GetFirstChild(Folder, InstanceName, InstanceType)
			else
				Object = Folder:WaitForChild(InstanceName, 5)

				if not Object then
					local Caller = getfenv(0).script

					if Caller and Caller.Parent and Caller.Parent.Parent == script then
						warn("[Resources] Make sure a Script in ServerScriptService calls `Resources:LoadLibrary(\"" .. Caller.Name .. "\")`")
					else
						if InstanceType == "Library" then
							warn("[Resources] Did you forget to install " .. InstanceName .. "?")
						elseif InstanceType == "Folder" then
							warn("[Resources] Make sure a Script in ServerScriptService calls `require(ReplicatedStorage:WaitForChild(\"Resources\"))`")
						end
					end

					Object = Folder:WaitForChild(InstanceName)
				end
			end

			Cache[InstanceName] = Object
		end

		return Object
	end

	Resources[MethodName] = GetFunction
	return GetFunction
end

if not SERVER_SIDE then
	local LocalPlayer repeat LocalPlayer = game:GetService("Players").LocalPlayer until LocalPlayer or not wait()
	repeat LocalResourcesLocation = LocalPlayer:FindFirstChildOfClass("PlayerScripts") until LocalResourcesLocation or not wait()
else
	LocalResourcesLocation = game:GetService("ServerStorage")
	local LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository") or game:GetService("ServerScriptService"):FindFirstChild("Repository")

	local function CacheLibrary(Storage, Library, StorageName)
		if Storage[Library.Name] then
			error("[Resources] Duplicate " .. StorageName .. " Found:\n\t"
				.. Storage[Library.Name]:GetFullName() .. " and \n\t"
				.. Library:GetFullName()
				.. "\nOvershadowing is only permitted when a server-only library overshadows a replicated library"
			, 0)
		else
			Storage[Library.Name] = Library
		end
	end

	if LibraryRepository then
		-- If Folder `Repository` exists, move all Libraries over to ReplicatedStorage
		-- unless if they have "Server" in their name or in the name of a parent folder

		local ServerLibraries = {}
		local ReplicatedLibraries = Resources:GetLocalTable("Libraries")
		local FoldersToHandle = {}
		local FolderChildren, ExclusivelyServer = LibraryRepository:GetChildren(), false

		while FolderChildren do
			FoldersToHandle[FolderChildren] = nil

			for i = 1, #FolderChildren do
				local Child = FolderChildren[i]
				local ClassName = Child.ClassName
				local ServerOnly = ExclusivelyServer or (Child.Name:find("Server", 1, true) and true or false)

				if ClassName == "ModuleScript" then
					if ServerOnly then
						Child.Parent = Resources:GetLocalFolder("Libraries")
						CacheLibrary(ServerLibraries, Child, "ServerLibraries")
					else
						-- ModuleScripts which are not descendants of ServerOnly folders and do not have "Server" in name should be moved to Libraries
						--	if there are descendants of the ModuleScript with "Server" in the name, we should copy the original for use on the server
						--	and replicate a version with everything with "Server" in the name deleted

						local ModuleDescendants = Child:GetDescendants()
						local TemplateObject

						-- Iterate through the ModuleScript's Descendants, deleting those with "Server" in the Name

						for j = 1, #ModuleDescendants do
							local Descendant = ModuleDescendants[j]

							if Descendant.Name:find("Server", 1, true) then
								if not TemplateObject then -- Before the first deletion, clone Child
									TemplateObject = Child:Clone()
								end

								Descendant:Destroy()
							end
						end

						if TemplateObject then -- If we want to replicate an object with Server descendants, move the server-version to LocalLibraries
							TemplateObject.Parent = Resources:GetLocalFolder("Libraries")
							CacheLibrary(ServerLibraries, TemplateObject, "ServerLibraries")
						end

						Child.Parent = Resources:GetFolder("Libraries") -- Replicate Child which may have had things deleted
						CacheLibrary(ReplicatedLibraries, Child, "ReplicatedLibraries")
					end
				elseif ClassName == "Folder" then
					FoldersToHandle[Child:GetChildren()] = ServerOnly
				else
					error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. ClassName .. " " .. Child:GetFullName(), 0)
				end
			end
			FolderChildren, ExclusivelyServer = next(FoldersToHandle)
		end

		for Name, Library in next, ServerLibraries do
			ReplicatedLibraries[Name] = Library
		end

		LibraryRepository:Destroy()
	end
end

local LoadedLibraries = Resources:GetLocalTable("LoadedLibraries")
local CurrentlyLoading = {} -- This is a hash which LoadLibrary uses as a kind of linked-list history of [Script who Loaded] -> Library

function Resources:LoadLibrary(LibraryName)
	LibraryName = self ~= Resources and self or LibraryName
	local Data = LoadedLibraries[LibraryName]

	if Data == nil then
		local Caller = getfenv(0).script or {Name = "Command bar"} -- If called from command bar, use table as a reference (never concatenated)
		local Library = Resources:GetLibrary(LibraryName)

		CurrentlyLoading[Caller] = Library

		-- Check to see if this case occurs:
		-- Library -> Stuff1 -> Stuff2 -> Library

		-- WHERE CurrentlyLoading[Library] is Stuff1
		-- and CurrentlyLoading[Stuff1] is Stuff2
		-- and CurrentlyLoading[Stuff2] is Library

		local Current = Library
		local Count = 0

		while Current do
			Count = Count + 1
			Current = CurrentlyLoading[Current]

			if Current == Library then
				local String = Current.Name -- Get the string traceback

				for _ = 1, Count do
					Current = CurrentlyLoading[Current]
					String = String .. " -> " .. Current.Name
				end

				error("[Resources] Circular dependency chain detected: " .. String)
			end
		end

		Data = require(Library)

		if CurrentlyLoading[Caller] == Library then -- Thread-safe cleanup!
			CurrentlyLoading[Caller] = nil
		end

		if Data == nil then
			error("[Resources] " .. LibraryName .. " must return a non-nil value. Return false instead.")
		end

		LoadedLibraries[LibraryName] = Data -- Cache by name for subsequent calls
	end

	return Data
end

Metatable.__call = Resources.LoadLibrary
return Resources
