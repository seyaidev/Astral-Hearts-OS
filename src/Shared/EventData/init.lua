-- Event Data
-- Username
-- February 25, 2020



local EventData = {
    ["EH20Alice"] = {
        Appearance = {
            Slot = 0;
            CharacterId = "EH20Alice";
            BodyType = "f";
            Tone = {r = 255/255, g = 204/255, b = 153/255};
            Class = "BladeDancer";
            HairStyle = "Silk Hair";
            HairColor = {r = 1, g = 0.933, b = 0.431};
            Shirt = "EH20_Alice";
            Pants = "EH20_Alice";
            Proportions = {
                Height = 0.65;
                Width = 0.22;
                Depth = 0;
                Head = 0;
            };
        };

        PlayerData = {
            S = "";
            DataId = 0;
            Stats = {
                -- SayoCredits = 0;
                Munny = 0;
                EXP = 0;
                Level = 30;
                -- EXPVault = 0;

                AbilityPoints = 0;
                SkillPoints = 0;
        
                Class = "BladeDancer";
                ClassPromotion = 1;


                STR = 122; --auto-assigned level 30 stats
                DEX = 35;
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
                ["Slot1"] = "Sweep1";
                ["Slot2"] = "Slash1";
                ["Slot3"] = "FallingAether1";

            };

            StarterEquipment = {
                Head = "BabyBlueBow";
                PrimaryWeapon = "BunnyFlux"
            };
        
            SkillInfo = {
                ["Sweep1"] = 10;
                ["Slash1"] = 10;
                ["FallingAether1"] = 10;
            };
        }
    };

    ["EH20Hatter"] = {
        Appearance = {
            Slot = 0;
            CharacterId = "EH20Hatter";
            BodyType = "m";
            Tone = {r = 255/255, g = 204/255, b = 153/255};
            Class = "Reaper";
            HairStyle = "Floof Hair";
            HairColor = {r = 0.631, g = 0.412, b = 0.259};
            Shirt = "EH20_Hatter";
            Pants = "EH20_Hatter";
            Proportions = {
                Height = 0.75;
                Width = 0.25;
                Depth = 0;
                Head = 0;
            };
        };

        PlayerData = {
            S = "";
            DataId = 0;
            Stats = {
                -- SayoCredits = 0;
                Munny = 0;
                EXP = 0;
                Level = 30;
                -- EXPVault = 0;

                AbilityPoints = 0;
                SkillPoints = 0;
        
                Class = "Reaper";
                ClassPromotion = 1;


                STR = 1; --auto-assigned level 30 stats
                DEX = 138;
                LCK = 35;
                INT = 1;
        
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
                ["Slot1"] = "Rend";
                ["Slot2"] = "SpinSlash";
                ["Slot3"] = "DeathSentence";

            };

            StarterEquipment = {
                Head = "TeaTime";
                PrimaryWeapon = "EggScythe1"
            };
        
            SkillInfo = {
                ["Rend"] = 10;
                ["SpinSlash"] = 10;
                ["DeathSentence"] = 10;
            };
        }
    };

}


return EventData