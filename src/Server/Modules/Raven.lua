--[[
	Raven-RBXLua by nomer888
	August 22nd, 2017

	Remember to enable HttpService.


	This module should only be used on the server to prevent clients spamming requests
	to your Sentry project and potentially risking your account/project being blacklisted.

	Clients should send errors to the server, which the server will then report to Sentry.
	This functionality is built into this module.  To use it, call
	RavenClient:ConnectRemoteEvent(remoteEvent) with a RemoteEvent not in use by anything
	else other than clients.

	For client > server error reporting, clients may only report exceptions (with or
	without traceback), with a limit number of events (default 5) per player per server.
	This module	will attempt to group and anonymize data to reduce unique event generation.

	If players try to send spoofed data, they will no longer be able to report any
	errors at all in that server.



	API:

	Raven:Client(string dsn[, table config])
		Creates a new Raven client used to send events.

		@dsn: the DSN located in your Sentry project.  Do not share this.
		(https://sentry.io/<user>/<project>/settings/keys/)

		@config: a table of attributes applied to all events before being sent to Sentry.
		See list of relevant attributes.



	Raven:SendMessage(string message[, string level = Raven.EventLevel.Info][, table config])
		Sends plain message event to Sentry.

		@level: a string describing the severity level of the event
		Valid levels (in Raven.EventLevel):
			Fatal
			Error
			Warning
			Info
			Debug

		@config: a table of attributes applied to this event before being sent to Sentry.
		Overrides default attributes of client, if set.
		See list of relevant attributes.



	Raven:SendException(string ExceptionType, string errorMessage[, <string, table> traceback][, table config])
		Send exception event to Sentry.

		@ExceptionType: a string describing the type of exception.
		Provided exception types (in Raven.ExceptionType):
			Server (for errors on the server)
			Client (for errors on the client)

		@errorMessage: a string describing the error.  Typically the second argument returned from pcall
		or an error message from LogService.

		@traceback: a string returned by debug.traceback() OR a premade stacktrace, used to add stacktrace
		information to the event.

		@config: a table of attributes applied to this event before being sent to Sentry.
		Overrides default attributes of client, if set.
		See list of relevant attributes.



	List of relevant attributes:
	(from https://docs.sentry.io/clientdev/attributes/#attributes)

	logger
    	The name of the logger which created the record.

	level
		The record severity.
		Enumeration of valid levels in Raven.EventLevel

	culprit
    	The name of the transaction (or culprit) which caused this exception.

	release
		The release version of the application.

	tags
		A hash array of tags for this event.
		Merges with client's list of tags, if set.

	environment
		The environment name, such as ‘production’ or ‘staging’.

	extra
		An arbitrary mapping of additional metadata to store with the event.

	message
		Human-readable message to store with the event.



	Example, server:

	local raven = require(script.Raven)
	local client = raven:Client("DSN here")

	client:ConnectRemoteEvent(Instance.new("RemoteEvent", game.ReplicatedStorage))

	local success, err = pcall(function() error("test server error") end)
	if (not success) then
		client:SendException(raven.ExceptionType.Server, err, debug.traceback())
	end

	client:SendMessage("Fatal error", raven.EventLevel.Fatal)
	client:SendMessage("Basic error", raven.EventLevel.Error)
	client:SendMessage("Warning message", raven.EventLevel.Warning)
	client:SendMessage("Info message", raven.EventLevel.Info)
	client:SendMessage("Debug message", raven.EventLevel.Debug)

	local LogService = game:GetService("LogService")
	LogService.MessageOut:Connect(function(message, messageType)
		if (messageType == Enum.MessageType.MessageError) then
			client:SendException(raven.ExceptionType.Server, message)
		end
	end



	Example, client:

	local success, err = pcall(function() error("test client error") end)
	if (not success) then
		game.ReplicatedStorage.RemoteEvent:FireServer(err, debug.traceback())
	end
--]]
local logWarnings = true
local maxClientErrorCount = 5

local Http = game:GetService("HttpService")

local GenerateUUID
do
	math.randomseed(tick())

	-- Generate entropy to keep UUIDs as random as possible
	for i = 1, 238 do
		math.random()
	end

	local hexTable = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f'}

	local function RandomHex(length)
		local s = ""
		for i = 1, length do
			s = s .. hexTable[math.random(16)]
		end
		return s
	end

	function GenerateUUID()
		return string.format("%s4%s8%s%s", RandomHex(12), RandomHex(3), RandomHex(3), RandomHex(12))
	end
end

local function GetTimestamp()
	local t = os.date("!*t")
	return ("%04d-%02d-%02dT%02d:%02d:%02d"):format(t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function TrySend(client, rawData, headers)
	if (client.enabled) then
		local succeed, err = pcall(Http.JSONEncode, Http, rawData)
		if (succeed) then
			local packetJSON = err
			local succeed, err = pcall(Http.PostAsync, Http, client.requestUrl, packetJSON, Enum.HttpContentType.ApplicationJson, true, headers)
			if (succeed) then
				local responseJSON = err
				local succeed, err = pcall(Http.JSONDecode, Http, responseJSON)
				if (succeed) then
					return true, err
				else
					return false, err
				end
			else
				local status = tonumber(err:match("^HTTP (%d+)"))
				if (status) then
					if (status >= 400 and status < 500) then
						if (logWarnings) then
							warn(("Raven: HTTP %d in TrySend, JSON packet:"):format(status))
							warn(packetJSON)
							warn("Headers:")
							for i, v in pairs(headers) do
								warn(i.." "..v)
							end
							warn("Response:")
							warn(err)
							if (status == 401) then
								warn("Please check the validity of your DSN.")
							end
						end
					elseif (status == 429) then
						if (logWarnings) then
							warn("Raven: HTTP 429 Retry-After in TrySend, disabling SDK for this server.")
						end
						client.enabled = false
					end
				end
				return false, err
			end
		else
			return false, err
		end
	else
		return false, "SDK disabled."
	end
end

local sentryVersion = "7"
local sdkName = "raven-rbxlua"
local sdkVersion = "1.0"

local function SendEvent(client, packet, config)
	assert(type(packet) == "table")

	local timestamp = GetTimestamp()

	packet.event_id = GenerateUUID()
	packet.timestamp = timestamp
	packet.logger = "server"
	packet.platform = "other"
	packet.sdk = {
		name = sdkName;
		version = sdkVersion;
	}



	for i, v in pairs(client.config) do
		packet[i] = v
	end

	for i, v in pairs(config) do
		if (i == "tags" and type(packet[i]) == "table") then
			for k, c in pairs(v) do
				packet[i][k] = c
			end
		else
			packet[i] = v
		end
	end

	local headers = {
		Authorization = client.authHeader:format(timestamp)
	}

	local succeed, response = TrySend(client, packet, headers)
	return succeed, response
end

local function StringTraceToTable(trace)
	local stacktrace = {}
	
	for line in trace:gmatch("[^\n\r]+") do
		-- print(line)
		local path, lineNum, value = line:match("(.-):(%d+)(.*)")
		-- print(path, lineNum, value)
		if (path and lineNum and value) then
			stacktrace[#stacktrace + 1] = {
				filename = path;
				["function"] = value or "nil";
				lineno = lineNum;
			}
		else
			return false, "invalid traceback"
		end
	end
	
	if (#stacktrace == 0) then
		-- print('no lines')
		return false, "invalid traceback"
	end
	
	local sorted = {}
	for i = #stacktrace, 1, -1 do
		sorted[i] = stacktrace[i]
	end
	
	return true, sorted
end


local Raven = {}

Raven.EventLevel = {
	Fatal = "fatal";
	Error = "error";
	Warning = "warning";
	Info = "info";
	Debug = "debug";
}

Raven.ExceptionType = {
	Server = "ServerError";
	Client = "ClientError";
}

function Raven:Client(dsn, config)
	local client = {}

	client.DSN = dsn

	local protocol,
	publicKey,
	secretKey,
	host,
	path,
	projectId = dsn:match("^([^:]+)://([^:]+):([^@]+)@([^/]+)(.*/)(.+)$")

	assert(protocol and protocol:lower():match("^https?$"), "invalid DSN: protocol not valid")
	assert(publicKey, "invalid DSN: public key not valid")
	assert(secretKey, "invalid DSN: secret key not valid")
	assert(host, "invalid DSN: host not valid")
	assert(path, "invalid DSN: path not valid")
	assert(projectId, "invalid DSN: project ID not valid")

	client.requestUrl = ("%s://%s%sapi/%d/store/"):format(protocol, host, path, projectId)
	client.authHeader = ("Sentry sentry_version=%d,sentry_timestamp=%s,sentry_key=%s,sentry_secret=%s,sentry_client=%s"):format(
		sentryVersion,
		"%s",
		publicKey,
		secretKey,
		("%s/%s"):format(sdkName, sdkVersion)
	)

	client.config = config or {}
	client.enabled = true

	return setmetatable(client, {__index = self})
end

function Raven:SendMessage(message, level, config)
	config = config or {}

	local packet = {
		level = level or self.EventLevel.Info;
		message = message;
	}

	return SendEvent(self, packet, config)
end

function Raven:SendException(eType, errorMessage, traceback, config)
	assert(type(eType) == "string", "invalid exception type")
	config = config or {}

	local exception = {
		type = eType;
		value = errorMessage;
	}

	local culprit

	if (type(traceback) == "string") then
		local success, frames = StringTraceToTable(traceback)
		if (success) then
			exception.stacktrace = {frames = frames}
			culprit = frames[#frames].filename
		else
			if (logWarnings) then
				warn(("Raven: Failed to convert string traceback to stacktrace: %s"):format(frames))
				warn(traceback)
			end
		end
	elseif (type(traceback) == "table") then
		exception.stacktrace = {frames = traceback}
		culprit = traceback[#traceback].filename
	end

	local packet = {
		level = Raven.EventLevel.Error;
		exception = {exception};
		culprit = culprit;
	}

	return SendEvent(self, packet, config)
end

local function ScrubData(playerName, errorMessage, traceback)
	-- print(playerName, errorMessage, traceback)
	errorMessage = errorMessage:gsub(playerName, "<Player>")

	local success, stacktrace
	if (traceback ~= nil) then
		success, stacktrace = StringTraceToTable(traceback)
		-- print(success, stacktrace)
		if (success) then
			for i, frame in pairs(stacktrace) do
				frame.filename = frame.filename:gsub(playerName, "<Player>")
			end
		end
	else
		success = true
	end

	-- print(success, errorMessage)
	if (success and errorMessage ~= "") then
		return true, errorMessage, stacktrace
	end
	return false, "invalid exception"
end

local errorCount = setmetatable({}, {__mode = "k"})

function Raven:ConnectRemoteEvent(player, errorMessage, traceback, rtype)
	local count = errorCount[player]
	if (not count) then
		count = maxClientErrorCount
	end

	if (count > 0) then
		if (type(errorMessage) == "string" and (type(traceback) == "string" or traceback == nil)) then
			local success, scrubbedErrorMessage, scrubbedTraceback = ScrubData(player.Name, errorMessage, traceback)
			if (success) then
				count = count - 1
				if rtype == nil then
					self:SendException(Raven.ExceptionType.Client, scrubbedErrorMessage, scrubbedTraceback)
				elseif rtype == "warn" then
					self:SendMessage(scrubbedErrorMessage .. " [trace]: " .. scrubbedTraceback, Raven.EventLevel.Warning)
				end
			else
				if (logWarnings) then
					warn(("Raven: Player '%s' tried to send spoofed data, their ability to report errors has been disabled."):format(player.Name))
					warn("errorMessage:")
					warn(errorMessage)
					warn("traceback:")
					warn(traceback)
				end
				count = 0
			end
		else
			if (logWarnings) then
				warn(("Raven: Player '%s' tried to send spoofed data, their ability to report errors has been disabled."):format(player.Name))
				warn("errorMessage:")
				warn(errorMessage)
				warn("traceback:")
				warn(traceback)
			end
			count = 0
		end
	end

	errorCount[player] = count
end

return Raven