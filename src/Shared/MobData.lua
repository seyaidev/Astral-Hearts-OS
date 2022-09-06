 -- Mob Data
-- Username
-- August 19, 2019

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local MobData = {

    ["SapphireGolem"] = {
        Level = 5;
        MaxHealth = 770;
        Attack = 46;
        Speed = 4;
        Avoid = 5;

        Aggro = true;
        Stagger = 35;

        EXP = 10;
        Munny = 19;
        AttackBox = Vector3.new(6, 7, 8.4);
    };

    ["RubyGolem"] = {
        Level = 7;
        MaxHealth = 1425;
        Attack = 58;
        Speed = 4;
        Avoid = 4;

        Aggro = true;
        Stagger = 30;

        EXP = 17;
        Munny = 28;
        AttackBox = Vector3.new(6, 7, 9);
    };

    ["DiamondGolem"] = {
        Level = 12;
        MaxHealth = 2200;
        Attack = 98;
        Speed = 4;
        Avoid = 3;

        Aggro = true;
        Stagger = 35;

        EXP = 22;
        Munny = 32;
        AttackBox = Vector3.new(12, 14, 14);
    };


    ["ForestSentinel"] = {
        Level = 15;
        MaxHealth = 2190;
        Attack = 112;
        Speed = 8;
        Avoid = 4;

        Aggro = true;
        Stagger = 40;

        EXP = 30;
        Munny = 40;
        AttackBox = Vector3.new(12, 14, 14);
    };

    ["AbyssSentinel"] = {
        Level = 18;
        MaxHealth = 3930;
        Attack = 135;
        Speed = 6;
        Avoid = 4;

        Aggro = false;
        Stagger = 37;

        EXP = 33;
        Munny = 43;
        AttackBox = Vector3.new(12, 14, 14);
    };

    ["FallenSentinel"] = {
        Level = 36;
        MaxHealth = 8000;
        Attack = 230;
        Speed = 6;
        Avoid = 4;

        Aggro = false;
        Stagger = 37;

        EXP = 112;
        Munny = 164;
        AttackBox = Vector3.new(12, 14, 14);
    };

    ["SpikedFrog"] = {
        Level = 4;
        MaxHealth = 575;
        Attack = 21;
        Speed = 11;
        Avoid = 2;

        Aggro = true;
        Stagger = 8;

        EXP = 8;
        Munny = 16;
        AttackBox = Vector3.new(6, 7, 9);
    };

    ["EtherWraith"] = {
        Level = 23;
        MaxHealth = 12010;
        Attack = 312;
        Speed = 12;
        Avoid = 3;

        Stagger = 40;
        Aggro = true;

        EXP = 51;
        Munny = 62;
        AttackBox = Vector3.new(20, 10, 15);
    };

    ["Cabber"] = {
        Level = 2;
        MaxHealth = 110;
        Attack = 12;
        Speed = 8.5;
        Avoid = 3;

        Aggro = true;
        Stagger = 10;

        EXP = 4;
        Munny = 13;
        AttackBox = Vector3.new(4, 5, 8);
    };

    ["Slime"] = {
        Level = 3;
        MaxHealth = 144;
        Attack = 17;
        Speed = 12;
        Avoid = 3;

        Aggro = true;
        Stagger = 10;

        EXP = 6;
        Munny = 16;
        AttackBox = Vector3.new(7, 7, 10);
    };

    ["Frozlime"] = {
        Level = 18;
        MaxHealth = 3400;
        Attack = 75;
        Speed = 12;
        Avoid = 3;

        Aggro = true;
        Stagger = 15;

        EXP = 11;
        Munny = 23;
        AttackBox = Vector3.new(7, 7, 10);
    };

    ["DarkSlime"] = {
        Level = 31;
        MaxHealth = 9001;
        Attack = 155;
        Speed = 12;
        Avoid = 3;

        Aggro = true;
        Stagger = 35;

        EXP = 88;
        Munny = 89;
        AttackBox = Vector3.new(13, 13, 12);
    };

    ["IceGolem"] = {
        Level = 32;
        MaxHealth = 10100;
        Attack = 170;
        Speed = 10;
        Avoid = 4;

        Aggro = true;
        Stagger = 45;

        EXP = 140;
        Munny = 140;
        AttackBox = Vector3.new(13, 15, 16);
    };

    ["AetherOni"] = {
        Level = 45;
        MaxHealth = 10000;
        Attack = 354;
        Speed = 18;
        Avoid = 4;

        Aggro = true;
        Stagger = 320;

        EXP = 314;
        Munny = 100;
        AttackBox = Vector3.new(13, 15, 16);
    };

    ["EtherGuardian"] = {
        Level = 55;
        MaxHealth = 20000;
        Attack = 500;
        Speed = 24;
        Avoid = 20;

        Aggro = true;
        Stagger = 300;
        EXP = 1000;
        Munny = 850;
        AttackBox = Vector3.new(30, 15, 20)
    }
}

local s = {}
local d = {}
local j = 1 
for i, v in pairs(MobData) do
    s[j] = i
    d[i] = j
    j = j+1
end
MobData.Serial = s
MobData.DeSerial = d

setDefault(MobData, {
    Level = 1;
    MaxHealth = 100;
    Attack = 10;
    Speed = 4;
    Avoid = 6;
})

return MobData