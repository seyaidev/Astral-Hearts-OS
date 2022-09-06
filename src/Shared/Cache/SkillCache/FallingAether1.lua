return {
    Name = "Falling Aether";
    Max = 15;
    UpgradeCost = 2;

    Stats = {
        Cooldown = 16;
        BaseDamage = 24;
        Multiplier = 0.3;
    };
    
    Levels = {
        BaseDamage = {
            10, 10, 10, 10, 12, 12, 12, 12, 14, 14, 14, 14, 15, 15
        };
        Cooldown = {
            -1, 0, 0, 0, -2, 0, 0, 0, -2, 0, 0, -2, 0, -2
        }
    };

    Class = "BladeDancer";
    Promotion = 1;

	Image = 2131920203;
    Description = "This move just looks really good. Deals 11(+30% of Attack) physical damage per hit.";
    
    LocalInfo = {
        hits = 4;
        skilltype = "attack_melee",
        activef = 4,
        size = Vector3.new(10, 7, 15),
        range = 12,
        SkillId = "FallingAether1"
    }
}