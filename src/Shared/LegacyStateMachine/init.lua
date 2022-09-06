local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new(isp)
	local newmc = {
		Current 	= require(script.Blank);
		States 		= {};
		_Lockout 	= false;
		IsPlayer	= isp;
	}
	setmetatable(newmc, StateMachine)
	return newmc
end

function StateMachine:Change(stateName, enterParams)
	if self.Current.id == stateName then return end
	self.Current:Exit(enterParams["LocalServices"])
	self.Current = self.States[stateName]
	self.Current:Enter(enterParams)
end

function StateMachine:Update(dt, LocalServices)
	self.Current:Update(dt, LocalServices)
end

function StateMachine:HandleInput(Input)
	self.Current:HandleInput(Input)
end

function StateMachine:Add(id, state)
	self.States[id] = state
	--print("added",id)
end

function StateMachine:Remove(id)
	if self.Current == self.States[id] then
		self.Current = self.Empty
	end
	self.States[id] = nil
end

function StateMachine:clear()
	self.Current = nil
	self.States = {}
end

return StateMachine