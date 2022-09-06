-- Message Service
-- oniich_n
-- July 16, 2019



local MessageService = {Client = {}}

local HttpService = game:GetService("HttpService")
local SEND_MESSAGE = "SEND_MESSAGE_CLIENT_EVENT"
local RECEIVED_MESSAGE = "RECEIVED_MESSAGE_CLIENT_EVENT"

function MessageService:Start()
    self:ConnectClientEvent(RECEIVED_MESSAGE, function(Player, MessageId)
        --mark message as received
        print(Player.Name .. " read message: " .. MessageId)
    end)

    
    self:ConnectClientEvent('LOADED_CLIENT', function(Player)
        wait()
--         self:FireClientEvent(SEND_MESSAGE, Player, {
--             Id = HttpService:GenerateGUID(false);
--             Pages = {
--                 {
--                     Title = "Mission E.G.G.!";
--                     Image = 4865547055;
--                     Boxes = {
--                         {
--                             Subtitle = "Wonderland(?)!!";
--                             SubtitleColor = Color3.fromRGB(255, 239, 147);
--                             Description = "Welcome to Wonderland(?), the Dark Forest of it at least. If you're here in search of an Egg, talk to Cheshy. She's a mischevious cat that's probably hidden it somewhere.";
--                         },
--                         {
--                             Subtitle = "Controls (for keyboard)";
--                             SubtitleColor = Color3.fromRGB(147, 232, 255);
--                             Description = [[
-- You now have to manually equip your weapon!

-- Q: Equip weapon
-- Left control: Lock/unlock camera
-- Left Shift: Dodge
--                             ]];
--                         }
--                     }
--                 },

--                 {
--                     Title = "More Info";
--                     Image = 4865547169;
--                     Boxes = {
--                         {
--                             Subtitle = "Wonderland(?) pt. 2!!";
--                             SubtitleColor = Color3.fromRGB(255, 239, 147);
--                             Description = 'This is only part 1 of the Astral Hearts "Wonderland(?)!!" event. Expect to see the rest of it later this month!';
--                         },

--                         {
--                             Subtitle = "Will I keep this character?";
--                             SubtitleColor = Color3.fromRGB(147, 232, 255);
--                             Description = "You're playing as a limited-time Heart right now, either Alice or Hatter. Their gear will be made available for Standard mode in part 2 of the event!";
--                         }
--                     }
--                 }
--             }
--         })
--     end)
end


function MessageService:Init()
    self:RegisterClientEvent(SEND_MESSAGE)
    self:RegisterClientEvent(RECEIVED_MESSAGE)
    self:RegisterClientEvent("LOADED_CLIENT")
end


return MessageService