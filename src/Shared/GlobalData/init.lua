local Data = {
    DATA_VERSION = "v020";
    TEST_VERSION = "t002";
    GAME_VERSION = "v0.13.2";
    
    Levels = {
        30, 50, 70, 90, 110, 150, 190,
        230,270,310,380,450,520,590,660,780,
        900,1020,1140,1260,1510,1760,2010,2260,
        2510,3010,3510,4010,4510,5010,5760,6510,
        7260,8010,8760,9510,10260,11010,11760,
        12510,13260,14010,14760,15510,16260,17010,
        17760,18510,19260,20010,20760,21510,22260,23010,
        23760,24510,25260,26010,26760,27510,32600,32800,
        33000,33200,33400,33600,33200,34000,34200,34400,
        34600,34800,35000,35200,35400,35600,35800,
        36000,36200
    };

    DefaultStats = {
        ["BladeDancer"] = {
            STR = 12;
            DEX = 5;
            LCK = 4;
            INT = 4;
        };

        ["Reaper"] = {
            STR = 1;
            DEX = 18;
            LCK = 5;
			INT = 1;
        }
    };

    Spawns = {
        "CecilCottage",
        "KaranthaVillage",
        "MistilSquare"
    };

    SubclassToClass = {
        ["Scythe"] = "Reaper";
        ["Blade"] = "BladeDancer";
    }

    DEFAULT_DATA = {
        S = "";
        DataId = 0;
        Stats = {
            -- SayoCredits = 0;
            Munny = 0;
            EXP = 0;
            Level = 1;
            -- EXPVault = 0;

            AbilityPoints = 0;
            SkillPoints = 0;
    
            -- Class = "BladeDancer";
            ClassPromotion = 1;
    
            --Stats
            -- Attack = 10;
            -- Defense = 10;

            STR = 4;
            DEX = 12;
            LCK = 5;
            INT = 4;
    
            --Secondary Stats
            -- Accuracy = 0;
            CriticalRate = 5;
            CriticalDamage = 20;
            DamageBonus = 0;
            BonusHealth = 100;
            
            -- LastTime = os.time();
            -- PlayTime = 0;
        };
    
        QuestData = {
            InitData = {},
            CompletedId = {},
            InProgress = {},
            Completed = {},
        };
    
        Inventory = {};
        Equipment = {
            PrimaryWeapon = "";
            SecondaryWeapon = "disabled";
            Head = "";
            UpperArmor = "";
            LowerArmor = "";
        };

        Skins = {
            PrimarySkin = "";
            SecondarySkin = "disabled";
            Head = "";
            UpperArmor = "";
            LowerArmor = "";
        };
    
        ActiveSkills = {
            ["Slot1"] = "";
            ["Slot2"] = "";
            ["Slot3"] = "";

        };
    
        SkillInfo = {};
    };
}

return Data