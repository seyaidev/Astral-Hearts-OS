-- Stance
-- oniich_n
-- December 27, 2018

--[[


--]]



local Stance = {}
local Player = game.Players.LocalPlayer
local FSM

function Stance:Start()
	self.Controllers.Character:ConnectEvent("CHARACTER_ADDED_EVENT", function(Character)
		self.Stance = FSM.create({
			initial = "passive",
			events = {
				{ name = "sheath", from = "active", to = "passive" },
				{ name = "activate", from = "passive", to = "active" }
			},
			callbacks = {
				on_after_event = function(s_fsm, event, from, to)
					self.Changed:Fire(to)
				end
			}
		})
		print("Create stance")
	end)
end


function Stance:Init()
	self.Changed = self.Shared.Event.new()
	FSM = self.Shared.FSM
end


return Stance