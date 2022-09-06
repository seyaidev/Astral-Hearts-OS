-- Perk Service
-- Username
-- September 9, 2019


local MarketplaceService = game:GetService("MarketplaceService")
local PerkService = {Client = {}}

local Developers = {
    [4338714] = true; --onii
    [186094] = true; --mukar
    [60476192] = true; --oi
    [46958348] = true; --lizz
    [20113483] = true; --chives
    [33906351] = true; --meien
}

local Mods = {
    [99297572] = true;
    [17185972] = true;
    [25356207] = true;
    [4337904] = true;
    [23622609] = true;
    [35936629] = true;
    [37032420] = true;
    [39340704] = true;
    [111221480] = true;
    [366472657] = true;
}

local Testers = {
    [3730389] = true;
    [28721009] = true;
    [6008603] = true;
    [58797374] = true;
    [16029208] = true;
    [116511190] = true;
    [6809102] = true;
    [62055220] = true;
    [26206990] = true;
}


function PerkService.Client:GetAllPerks(Player)
end

function PerkService:IsDev(Player)
    return Developers[Player.UserId]
end

function PerkService.Client:IsDev(Player)
    return Developers[Player.UserId]
end


function PerkService:IsFounder(Player)
    return self.Founders[Player.UserId]
end
function PerkService.Client:IsFounder(Player)
    return self.Server.Founders[Player.UserId]
end



function PerkService:IsHero(Player)
    return self.Heroes[Player.UserId]
end
function PerkService.Client:IsHero(Player)
    return self.Server.Heroes[Player.UserId]
end



function PerkService:IsCop(Player)
    return Mods[Player.UserId]
end
function PerkService.Client:IsCop(Player)
    return Mods[Player.UserId]
end



function PerkService:GetMaxSlots(Player)
    local Num = 2

    if self.Founders[Player.UserId] or self:IsDev(Player) then
        Num = 6
    elseif self.Heroes[Player.UserId] then
        Num = 4
    end

    if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 7403296) then
        Num = math.clamp(Num+1, 2, 6)
    end

    return Num
end
function PerkService.Client:GetMaxSlots(Player)
    if self.Server.Founders[Player.UserId] or self.Server:IsDev(Player) then
        print("Got 6 slots!")
        return 6
    elseif self.Server.Heroes[Player.UserId] then
        return 4
    elseif MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 7403296) then
        return 3
    end

    return 2
end

function PerkService:GetTester(Player)
    local is = self:IsCop(Player) or self:IsDev(Player) or self:IsFounder(Player) or self:IsHero(Player) or Testers[Player.UserId]
    return is
end


local Gamepasses = {
    Id = {
        [7445209] = "NewClass";
        [7403296] = "ExtraSlot";
        [7403297] = "AvatarAppearance";
        [7403291] = "10Bonus";
    };

    ["NewClass"] = {};
    ["ExtraSlot"] = {};
    ["AvatarAppearance"] = {};
    ["10Bonus"] = {};
}

function PerkService:HasPerk(Player, Perk)
    return self:IsDev(Player) or Gamepasses[Perk][Player]
end

function PerkService:PromptPass(Player, Perk)
    local pid

    for i,v in pairs(Gamepasses.Id) do
        if v == Perk then
            pid = i
        end
    end

    print('perk id:', pid)
    MarketplaceService:PromptGamePassPurchase(Player, pid)
end

function PerkService:Start()
    game.Players.PlayerAdded:Connect(function(Player)
        self.IndividualPerks[Player] = {}

        if not self.Heroes[Player.UserId] then
            self.Heroes[Player.UserId] = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 5015788)
        end

        if not self.Founders[Player.UserId] then
            self.Founders[Player.UserId] = MarketplaceService:PlayerOwnsAsset(Player, 1090923299) or MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 3463058)
        end

        for i,v in pairs(Gamepasses.Id) do
            Gamepasses[v][Player] = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, i)
        end

        print("PERK CHECK", self.Heroes[Player], self.Founders[Player])
        wait()
        if game.PlaceId == 1268365237 then
            if not self.Services.PerkService:GetTester(Player) then
                Player:Kick("You aren't a Preview tester.")
            end
        end
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, GamePassId, wasPurchased)
        if wasPurchased then
            if not Gamepasses[Gamepasses.Id[GamePassId]][Player] then
                Gamepasses[Gamepasses.Id[GamePassId]][Player] = true
            end
        end
    end)
end


function PerkService:Init()
    TableUtil = self.Shared.TableUtil
    
    self.Founders = {}
    self.Heroes = {
        [17437678] = true;
    }
    self.IndividualPerks = {}
end


return PerkService