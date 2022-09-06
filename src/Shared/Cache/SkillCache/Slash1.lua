return {
    Name = "Blade Slash";
    Max = 20;
    UpgradeCost = 1;


    Stats = {
        Cooldown = 10;
        BaseDamage = 19;
        Multiplier = 0.75;
    };

    Levels = {
        BaseDamage = {
            5, 5, 5, 5, 8, 8, 8, 8, 9, 9, 9, 9, 10, 10, 10, 20, 20, 20, 20
        };
        Cooldown = {
            -1, 0, 0, 0, 0, -2, 0, 0, 0, 0, -2, 0, 0, 0, 0, -2, 0, 0, 0, -1
        }
    };

    Class = "BladeDancer";
    Promotion = 1;

    Image = 2131920375;
    Description = "Slash through enemies with one of the most basic of blade arts. Deals 20(+75% of Attack Power) physical damage";

    LocalInfo = {
        hits = 1;
        skilltype = "attack_melee",
        activef = 10,
        size = Vector3.new(8, 5, 5),
        range = 9,
        SkillId = "Slash1"
    }
}