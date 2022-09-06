local DefaultSword = 10
local mob_Default = 12

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local AttackRanges = {
	__index = function() return DefaultSword end;
--Player ranges
	--Default ranges
	ScissorBlade = DefaultSword;
	Regalis = 16;
--Mob ranges
	--Default ranges
	SapphireGolem_Attack = Vector3.new(6, 7, 8.4);
	RubyGolem_Attack = Vector3.new(6, 7, 9);
	DiamondGolem_Attack = Vector3.new(12, 14, 14);
	ForestSentinel_Attack = Vector3.new(12, 14, 14);
	IceGolem_Attack = Vector3.new(13, 15, 16);
	AbyssSentinel_Attack = Vector3.new(12, 14, 14);
	Cabber_Attack = Vector3.new(4, 5, 8);
	EtherWraith_Attack = Vector3.new(20, 10, 15);
	SpikedFrog_Attack = Vector3.new(6, 7, 9);
	Slime_Attack = Vector3.new(7, 7, 10);
	Frozlime_Attack = Vector3.new(7, 7, 10);

	--Ether Guardian ranges
	EtherGuardian_attack_Clap = 30;
	EtherGuardian_attack_Sweep = 40;
	EtherGuardian_attack_FlipShockwave = 25;
}

setDefault(AttackRanges, DefaultSword)
return AttackRanges