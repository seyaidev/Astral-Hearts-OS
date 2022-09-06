return {
    Name = "Death Sentence";
    Max = 15;
    UpgradeCost = 3;

    Stats = {
        Cooldown = 24;
        BaseDamage = 24;
        Multiplier = 0.5;
    };
    
    Levels = {
        BaseDamage = {
            15, 15, 15, 15, 16, 16, 20, 30, 30, 30, 35, 35, 50, 50
        };
        Cooldown = {
            -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, -2, 0, 0, -2
        }
    };

    Promotions = {
        3,
        5
    };

    Class = "Reaper";
    Promotion = 1;

	Image = 2131920203;
    Description = "Reaper throws their scythe forward then calls it back, dealing damage both ways. Reaper then deals 3 additional hits to near enemies upon catching their scythe.";
    
    LocalInfo = {
        hits = 6;
        skilltype = "attack_melee",
        activef = 4,
        size = Vector3.new(10, 4, 20),
        range = 20,
        SkillId = "DeathSentence"
    }
}