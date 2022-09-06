return {
    Name = "Blade Sweep";
	Max = 20;
    UpgradeCost = 1;

    Stats = {
        Cooldown = 11;
        BaseDamage = 18;
        Multiplier = 0.5;
    };

    Levels = {
        BaseDamage = {
            5, 3, 3, 3, 3, 10, 3, 3, 3, 3, 14, 3, 3, 3, 3, 17, 3, 3, 3, 20
        };
        Cooldown = {
            -1, 0, 0, 0, 0, -0.5, 0, 0, 0, 0, -0.5, 0, 0, 0, 0, -0.5, 0, 0, 0, -1
        }
    };
    
    Class = "BladeDancer";
    Promotion = 1;

	Image = 2131920203;
    Description = "Sweep your opponents off their feet with style. Deals 15(+50% of Attack Power) physical damage and has a (?%) chance to stun enemies hit.";
    
    LocalInfo = {
        hits = 1;
        skilltype = "attack_melee",
        activef = 10,
        size = Vector3.new(12, 5, 5),
        range = 10,
        SkillId = "Sweep1"
    }
}