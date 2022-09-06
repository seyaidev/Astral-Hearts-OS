return {
    Name = "Spin Slash";
    Max = 20;
    UpgradeCost = 1;

    Stats = {
        Cooldown = 12;
        BaseDamage = 20;
        Multiplier = 0.35;
    };
    
    Levels = {
        BaseDamage = {
            10, 10, 14, 17, 20, 20, 20, 14, 17, 20, 15, 20, 20, 20, 20, 15, 20, 35, 40, 45
        };
        Cooldown = {
            -1, 0, 0, 0, -1, -0, -0, 0, -1, 0, 0, -1, 0, 0, 0, 0, 0, -1, 0
        }
    };

    Class = "Reaper";
    Promotion = 1;

	Image = 2131920203;
    Description = "Reaper slashes through a spinning motion, dealing damage in a larger peripheral and vertical area.";
    
    LocalInfo = {
        hits = 1;
        skilltype = "attack_melee",
        activef = 4,
        size = Vector3.new(15, 7, 12),
        range = 12,
        SkillId = "SpinSlash"
    }
}