return {
    Name = "Rend";
    Max = 20;
    UpgradeCost = 2;

    Stats = {
        Cooldown = 17;
        BaseDamage = 16;
        Multiplier = 0.20;
    };
    
    Levels = {
        BaseDamage = {
            7, 7, 7, 7, 7, 7, 14, 14, 14, 14, 14, 20, 30, 40, 40, 40, 40, 40, 40
        };
        Cooldown = {
            -1, -1, -1, -1, -1, -0, -0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, -1, -1
        }
    };

    Promotions = {
        Max = {4,8}
    };

    Class = "Reaper";
    Promotion = 1;

	Image = 2131920203;
    Description = "Reaper swings twice in succession. The second hit has a chance to stun.";
    
    LocalInfo = {
        hits = 2;
        skilltype = "attack_melee",
        activef = 4,
        size = Vector3.new(10, 4, 20),
        range = 20,
        SkillId = "Rend"
    }
}