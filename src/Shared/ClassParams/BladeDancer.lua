local BladeDancer = {
	AttackSlide = 14;

	PrimaryStat = "STR";
	SecondaryStat = "DEX";

	Weapon = "Blade";
	MaxAttacks = 5;
	AttackSpeed = 0.3;

	BaseHealth = 100;
	HealthGrowth = 20;

	SkillTrees = {
		[1] = {
			"Slash1",
			"Sweep1",
			"FallingAether1"
		}
	};

	PerLevel = 0.3;
}

return BladeDancer