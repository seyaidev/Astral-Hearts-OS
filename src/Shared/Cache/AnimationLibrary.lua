--Animation list.
--[[
	Light Attacks 1-4
	Heavy Attacks 1-3
	Light Aerials 1-4
	Heavy (finisher) Aerials 1-2
]]

local DefaultBlade = {
	["1"] = 4409012012;
	["2"] = 4409014379;
	["3"] = 4409015377;
	["4"] = 4409016950;
	["5"] = 4409018040;
}

-- local DefaultBlade = {
-- 	["1"]		= 2701967809;
-- 	["2"]		= 2701966976;
-- 	["3"]		= 2701966011;
-- 	["4"]		= 2701964818;
-- 	["H1"]		= 2125743007;
-- }

local DefaultStaff = {
	["1"]		= 2119482859;
	["2"]		= 2104993805;
	["3"] 		= 2119469916;
}

local DefaultShield = {
	["1"]		= 2176760519;
	["2"] 		= 2217863166;
	["3"] 		= 2217865509;
}

local DefaultGauntlet = {
	["1"]		= 2217872289;
	["2"]		= 2217874896;
	["3"]		= 2217876713;
	["4"]		= 2217879634;
	["5"] 		= 2225642893;
}

local DefaultScythe = {
	["1"]		= 4196294733;
	["2"]		= 4196295548;
	["3"]		= 4196296471;
	["4"]		= 4196297442;
}

local DefaultGolem = {
	["Walk"]	= 1262702701;
	["Attack"]	= 2272882300;
	["Idle"]	= 1262703914;
	["Stagger"]	= 2240735752;
}

local DefaultMagic = 1315615959;

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local Sentinel = {
	["Walk"]		= 2272984169;
	["Attack"]		= 2272985485;
	["Idle"]		= 2272986717;
	["Stagger"]		= 2273009253;
};

local Slime = {
	["Walk"]		= 4465699421;
	["Attack"]		= 4465753565;
	["Idle"]		= 4465747887;
	["Stagger"]		= 2273009253;
}


local AnimationLibrary = {
	["Weapon"] = {
		["Blade"]	= {Default = DefaultBlade};
		["Staff"]	= {Default = DefaultStaff};
		["Gauntlet"]	= {Default = DefaultGauntlet};
		["Shield"]	= {Default = DefaultShield};
		["Scythe"] = {Default = DefaultScythe};
	};

	["Mob"]	= {
		--Echo mobs (identical animation rigs)
		["SapphireGolem"]	= DefaultGolem;
		["RubyGolem"]		= DefaultGolem;
		["DiamondGolem"]	= DefaultGolem;

		["Slime"]	= Slime;
		["Frozlime"] = Slime;
		["DarkSlime"] = Slime;

		--unique animations
		["EtherGuardian"]	= {
			["attack_Walk"]				= 1417223731; --gap closer
			["attack_FlipShockwave"]	= 4819796594; --sig gap closer
			["attack_Sweep"]			= 1417040725; --signature move
			["attack_VertSlam"] 		= 1417100739; --heavy attack
			["attack_Clap"]				= 1417048392; --quick attack
			
			["Attack"]					= 4820610618; --clap, but as a basic attack
			["Walk"]					= 1417223731; --same move as gap closer
			["Idle"]					= 1423461113;
			["IdleAction"]				= 1423451249;

			["Stagger_Start"]			= 2159693567;
			["Stagger_End"]				= 2159687118;
		};

		["EtherWraith"]		= {
			["Walk"] 		= 2231606879;
			["Attack"] 		= 2231608998;
			["Idle"] 		= 2231613182;
			["Stagger"]		= 2245409789;
		};

		["ForestSentinel"]	= Sentinel;
		["AbyssSentinel"] = Sentinel;
		
		["SpikedFrog"]		= {
			["Walk"]		= 2277118016;
			["Attack"]		= 2280196240;
			["Idle"]	= 2277127817;
			["Stagger"]		= 2280309435;
		};

		["Cabber"]			= {
			["Walk"]		= 3612574023;
			["Attack"]		= 3612576140;
			["Idle"]	= 3612578192;
			["Stagger"]		= 3612565128;
		};

		["IceGolem"]	= {
			["Attack"] = 4548101809;
			["Walk"] = 4548108965;
			["Idle"] = 4548111643;
		};

		["AetherOni"] = {
			["Attack"] = 4692143387;
			["Walk"] = 4692033084;
			["Idle"] = 4691944493;
		}
	};

	["Skill"] = {
		["Slash1"]			= 2133255723;
		["Sweep1"] 			= 2133435072;
		["FallingAether1"]	= 2149456615;

		["ShieldBash"]		= 2217866578;
		["Taunt1"]			= 2249096588;

		["DeathSentence"]	= 4196846843;
		["SpinSlash"]		= 4207146881;
		["Rend"]			= 4207147828;
	};

	["ReaperIdle"] = 4196845343;
	["ReaperRun"] = 4196846125;
	["BladeDancerRun"] = 4409641929;
    ["BladeDancerIdle"]	= 4409655783;
}

setDefault(AnimationLibrary["Weapon"]["Blade"], DefaultBlade)
setDefault(AnimationLibrary["Weapon"]["Staff"], DefaultStaff)
setDefault(AnimationLibrary["Weapon"]["Gauntlet"], DefaultGauntlet)
setDefault(AnimationLibrary["Weapon"]["Shield"], DefaultShield)
setDefault(AnimationLibrary["Weapon"]["Scythe"], DefaultScythe)
setDefault(AnimationLibrary["Skill"], DefaultMagic)

return AnimationLibrary