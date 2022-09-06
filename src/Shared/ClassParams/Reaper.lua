local Reaper = {
	AttackSlide = 14;

	PrimaryStat = "DEX";
	SecondaryStat = "LCK";

	Weapon = "Scythe";
	MaxAttacks = 4;
	AttackSpeed = 0.3;

	BaseHealth = 90;
	HealthGrowth = 7;

	SkillTrees = {
		[1] = {
			"SpinSlash",
			"Rend",
			"DeathSentence"
		}
	};

	PerLevel = 0.3;
}

return Reaper