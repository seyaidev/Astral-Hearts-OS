if true then return {} end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Attachments = require(script.Parent.Parent:WaitForChild("Attachments"))
local Boxcast = require(script.Parent.Parent:WaitForChild("Boxcast"))
local AttackRangeLibrary = require(script.Parent:WaitForChild("AttackRangeLibrary"))

--create library of status effects?
	--burn, deal 5% of base damage per second for 3 seconds

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

function MeleeSkill(activef, size, range, LocalServices, SkillId)
	local Hits = {}
	local bbox = LocalServices._Character:GetExtentsSize()
	for i = 1, activef do
		RunService.Stepped:wait()
		print("owo11!")
		local hits, pos, norm = Boxcast(
			LocalServices._Character:GetPrimaryPartCFrame(),
			LocalServices._Character:GetPrimaryPartCFrame().lookVector*range,
			size,
			{LocalServices._Character, workspace.Trash, workspace.Markers}
		)

		if #hits > 0 then
			local function checkHit(mobid)
				for i, v in pairs(Hits) do
				--	print(v, hit:FindFirstAncestorOfClass("Folder"))
					if v == mobid then
						return false
					end
				end
				return true
			end
			for i, hit in pairs(hits) do
				local tags = CollectionService:GetTags(hit)
				for j, tag in pairs(tags) do
					local id = tag:match("^({.+})")
					if id then
						local model = hit.Parent
						if model ~= nil and hit.Parent:IsA("Model") then
							-- print("OMO")
							if checkHit(id) then
								table.insert(Hits, id)
								for i, v in pairs(model:GetDescendants()) do
									if v:IsA("BasePart") then
										v.Color = Color3.new(1, v.Color.g, v.Color.b)
										TweenService:Create(v, TweenInfo.new(1.2), {Color = v.BaseColor.Value}):Play()
									end
								end
							end
						end
					end
				end
			end
		end
	end

	LocalServices._UI.Store:dispatch({
		type = RoduxActions.INCREMENT_COMBO,
		increment = #Hits
	})
	LocalServices._UI.ComboSignal:Fire()
	LocalServices._LastHit = 0
	print("skill hits",#Hits)

	GetRemoteEvent("MobQueueSpecial"):FireServer(Hits, SkillId)
	LocalServices._Mobs.ClientHit:Fire(Hits)
end

local default	= {
	Name = "none";
	BaseDamage 		= 0;
	UpgradeCost = 999;
	Cost	= 999;
	Max = 1;
	Cooldown = 0;
	Status 			= {};

	Image = 1565750474;
	Description = "Default skill. How did you find this??";

	Speed 			= 0;
	Range 			= 1; --range = time in seconds, distance = Range * Speed
	Callback 		=

	function(LocalServices)
		print("help, this is a bug")
	end
}

local SkillCache = {
	["Fire"]	= {
		Name = "Fire";
		BaseDamage 		= 12;
		Cost	= 12;
		UpgradeCost = 1;
		Max = 5;
		Status 			= {
			"burn";
		};
		Cooldown = 10;

		Image = 2131919919;
		Description = "A shot of fire created from Essence.";


		Speed 			= 65;
		Range 			= 1; --range = time in seconds, distance = Range * Speed
		Callback 		=

		function(LocalServices)
			if RunService:IsClient() then
				local CharPPCF = LocalServices._Character:GetPrimaryPartCFrame()
				local AttachCF = Attachments:getAttachmentWorldCFrame(LocalServices._Character:FindFirstChild("RightGripAttachment", true))
				local Info = {
					Position = AttachCF.p,
					Velocity = CharPPCF.lookVector * 65,
					Acceleration = Vector3.new(),
					Size = Vector3.new(3, 3, 3),
					Color = Color3.fromRGB(244, 179, 66),
					Range = 1,

					ProjType = "Fire"
				}

				LocalServices._Projectiles.Generate(Info, LocalServices)
				return
			end
		end
	};

	["Ice"]	= {
		Name = "Ice";
		BaseDamage 		= 12;
		Cost	= 12;
		UpgradeCost = 1;
		Max = 5;
		Status 			= {
			"freeze";
		};
		Cooldown = 10;

		Image = 2131920066;
		Description = "A shard of ice embued with Essence.";

		Speed 			= 25;
		Range 			= 1; --range = time in seconds, distance = Range * Speed
		Callback 		=

		function(LocalServices)
			if RunService:IsClient() then
				--get boxcast pos
				--hope for the best
				local CharPPCF = LocalServices._Character:GetPrimaryPartCFrame()
				local PosStart = CharPPCF*CFrame.new(0, 0, -18)
				local Info = {
					Position = PosStart.p+Vector3.new(0, 25, 0),
					Velocity = Vector3.new(0, -25, 0),
					Acceleration = Vector3.new(),
					Size = Vector3.new(3, 3, 3),
					Color = Color3.fromRGB(122, 173, 255),
					Range = 1,

					ProjType = "Ice"
				}

				LocalServices._Projectiles.Generate(Info, LocalServices)
				return
			end
		end
	};


	["Lightning"]	= {
		Name = "Lightning";
		BaseDamage 		= 22;
		Cost	= 12;
		UpgradeCost = 1;
		Status 			= {
			"freeze";
		};
		Max = 5;
		Cooldown = 10;

		Image = 2131920822;
		Description = "Essence-crafted thunder and lightning; Deals 22(+%?) damage within an area in front of the player.";

		Speed 			= 65;
		Range 			= 1; --range = time in seconds, distance = Range * Speed
		Callback 		=

		function(LocalServices)
			if RunService:IsClient() then
				--generate boxcast in front of player
				return
			end
		end
	};

	["Empower"]		= {
		Name = "Empower";
		Multiplier = 1.1;
		Cost	= 3;
		UpgradeCost = 1;
		Cooldown = 10;
		Max = 3;

		Image = 1565750474;
		Description = "Increases your own Power Level by 10% for 3 seconds.";

		Callback = function()
			print('empower skill')
			--remote event to trigger
		end
	};

	["Slash1"]		= {
		Name = "Blade Slash";
		Cost = 3;
		UpgradeCost = 1;
		Max = 5;

		Cooldown = 5;
		BaseDamage = 20;
		Multiplier = 0.75;

		Image = 2131920375;
		Description = "Slash through enemies with one of the most basic of blade arts. Deals 20(+75% of Attack Power) physical damage";

		Callback = function(LocalServices)
			print("testing melee attack D:")
			if RunService:IsClient() then
				MeleeSkill(10, Vector3.new(8,5,5), 9, LocalServices, "Slash1") --active frames, size
			end
		end
	};

	["Sweep1"]		= {
		Name = "Blade Sweep";
		Cost = 3;
		UpgradeCost = 1;
		Max = 5;

		Cooldown = 7;
		BaseDamage = 15;
		Multiplier = 0.5;

		Image = 2131920203;
		Description = "Sweep your opponents off their feet with style. Deals 15(+50% of Attack Power) physical damage and has a (?%) chance to stun enemies hit.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				MeleeSkill(10, Vector3.new(12,5,5), 10, LocalServices, "Sweep1") --active frames, size
			end
		end
	};

	["FallingAether1"]		= {
		Name = "Falling Aether";
		Cost = 6;
		UpgradeCost = 2;
		Max = 3;

		Cooldown = 12;
		BaseDamage = 11;
		Multiplier = 0.3;

		Image = 2131920203;
		Description = "This move just looks really good. Deals 11(+30% of Attack Power) physical damage per hit.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				MeleeSkill(4, Vector3.new(10,7,5), 12, LocalServices, "FallingAether1") --active frames, size
			end
		end
	};

	["ShieldBash"] 			= {
		Name = "Shield Bash";
		Cost = 6;
		UpgradeCost = 4;
		Max = 2;
		Status = {
			{"stun", 3} --status, duration
		};

		Cooldown = 7;
		BaseDamage = 9;
		Multiplier = 0.80;

		Image = 2131920203;
		Description = "Knock enemies silly with your rather large and mobile shield! Deals 9(+80% of Attack Power) and applies a stun.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				MeleeSkill(5, Vector3.new(10,7,5), 18, LocalServices, "ShieldBash") --active frames, size
			end
		end
	};

	["Taunt1"] 				= {
		Name = "Taunt";
		Cost = 6;
		UpgradeCost = 4;
		Max = 2;
		Status = {
			{"taunt", 3, 50}
		};
		RequireTarget = true;

		Cooldown = 14;
		BaseDamage = 10;
		Multiplier = 0.65;

		Image = 2131920203;
		Description = "Enrage targeted enemy by messing with their shoes, dealing 10(+65% of Attack Power) and increasing their enmity towards you by 50.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				-- print(LocalServices._Target)

				if LocalServices._Targeting._Target ~= nil then
					local tags = CollectionService:GetTags(LocalServices._Targeting._Target)
					for j, tag in pairs(tags) do
						local id = tag:match("^({.+})")
						if id then
							local model = LocalServices._Targeting._Target.Parent
							if model ~= nil and LocalServices._Targeting._Target.Parent:IsA("Model") then
								-- print("OMO")
								GetRemoteEvent("MobQueueSpecial"):FireServer({id}, "Taunt1")
							end
						end
					end
				end
			end
		end
	};

	["AtArms"]				= {
		Name = "At Arms";
		Cost = 12;
		UpgradeCost = 2;
		Max = 2;

		Cooldown = 35;
		BaseDamage = 0;
		Multiplier = 0.5;

		Image = 2131920203;
		Description = "Increase your defense power by 50% for 10 seconds. Affects damage reduction.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				GetRemoteEvent("PlayerSkill"):FireServer("AtArms")
			end
		end
	};

--martial artist skills
	["CycloneKick"]				= {
		Name = "Cyclone Kick";
		Cost = 6;
		UpgradeCost = 2;
		Max = 3;

		Cooldown = 8;
		BaseDamage = 18;
		Multiplier = 0.5;

		Image = 2131920203;
		Description = "Spin with the force of a thousand, dealing 18(+50% of Attack Power) damage per hit.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				MeleeSkill(5, Vector3.new(10,7,5), 15, LocalServices, "CycloneKick")
			end
		end
	};

	["Uppercut"]				= {
		Name = "Uppercut";
		Cost = 6;
		UpgradeCost = 2;
		Max = 3;
		Status = {
			{"stun", 2}
		};

		Cooldown = 10;
		BaseDamage = 16;
		Multiplier = 0.65;

		Image = 2131920203;
		Description = "Spin with the force of a thousand, dealing 18(+50% of Attack Power) damage per hit.";

		Callback = function(LocalServices)
			if RunService:IsClient() then
				MeleeSkill(5, Vector3.new(10,7,5), 10, LocalServices, "Uppercut")
			end
		end
	};
}

setDefault(SkillCache, default)

return SkillCache