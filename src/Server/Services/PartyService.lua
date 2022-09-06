local Players = game:GetService("Players")
local PartyService = {Client = {}}
local Parties = {}

local Invites = {}

function PartyService:findParty(player)
    if typeof(player) == "number" then
        player = Players:GetPlayerByUserId(player)
    end

    for Leader, Members in pairs(Parties) do
        if playerInstance == Leader or table.find(Members, player) then
            return Members, Leader
        end
    end
    return nil, nil
end

function PartyService.Client:findParty(player)
    return self.Server:findParty(player)
end

function PartyService:Start()

    self.Services.PlayerService:ConnectEvent("PLAYER_ADDED_EVENT", function(player)
        Invites[player.UserId] = {}
    end)

    self:ConnectClientEvent("CreateParty", function(newLeader)
        --check if player is already in a party/owns
            --is a leader or is a member, then return false

        for Leader, Members in pairs(Parties) do
            if Leader == newLeader then --found in player
                return false, "Already leading a party."
            elseif table.find(Members, newLeader.UserId) then --found in another party
                return false, "Already a member of another party."
            end
        end
        Parties[leader] = {}
    end)

    self:ConnectClientEvent("InviteToParty", function(invitingMember, invitedUserId)
        local Members, Leader = self:findParty(invitingMember)
        if invitingMember ~= Leader then return end


        if not Invites[invitedUserId] then return end
        table.insert(Invites[invitedUserId], invitingMember)
    end)

    self:ConnectClientEvent("JoinParty", function(newMember, leader)
        if table.find(Invites[newMember], leader) then
            Invites[newMember] = nil

            local Members = self:findParty(leader)
            if Members then
                table.insert(Members, newMember.UserId)
                Parties[leader] = Members
            end
        end
    end)

    self:ConnectClientEvent("LeaveParty", function(leavingMember)
        --check to see if they're in a party
        local Members, Leader = self:findParty(leavingMember)
        if Members and Leader then
            table.remove(Members, TableUtil.IndexOf(Members, leavingMember.UserId))
            Parties[Leader] = Members
            Invites[leavingMember.UserId] = {}
        end
    end)
end

function PartyService:Init()
    self:RegisterClientEvent("CreateParty")
    self:RegisterClientEvent("InviteToParty")
    self:RegisterClientEvent("JoinParty")
    self:RegisterClientEvent("LeaveParty")
    
    PlayerService = self.Services.PlayerService

    TableUtil = self.Shared.TableUtil
end

return PartyService