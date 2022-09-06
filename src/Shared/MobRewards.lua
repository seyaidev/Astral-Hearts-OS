-- Mob Rewards
-- Username
-- August 19, 2019

function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local MobRewards = {
    ["Cabber"] = {
        EXP = 2;
        Munny = 3;
    };

    ["SapphireGolem"] = {
        EXP = 7;
        Munny = 7;
    };

    ["RubyGolem"] = {
        EXP = 17;
        Munny = 18;
    };

    ["DiamondGolem"] = {
        EXP = 22;
        Munny = 22;
    };

    ["ForestSentinel"] = {
        EXP = 37;
        Munny = 37;
    };

    ["AbyssSentinel"] = {
        EXP = 28;
        Munny = 27;
    };

    ["SpikedFrog"] = {
        EXP = 12;
        Munny = 14;
    };

    ["EtherWraith"] = {
        EXP = 51;
        Munny = 52;
    };
}

setDefault(MobRewards, {
    EXP = 10;
    Munny = 15;
})

return MobRewards