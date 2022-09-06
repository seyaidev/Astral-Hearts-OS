local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SPUtil = require(script.Parent:WaitForChild("SPUtil"))

local SPList = require(script.Parent:WaitForChild("SPList"))

local SPDict = {}

function SPDict:new()
	local self = {}

	local _count = 0
	self._table = {}

	function self:add(key, value)
		if self:contains(key) then
			self._table[key] = value
			return
		end
		self._table[key] = value
		_count = _count + 1
	end
	function self:remove(key)
		if not self:contains(key) then
			return false
		end
		self._table[key] = nil
		_count = _count - 1

		return true
	end
	function self:get(key)
		return self._table[key]
	end
	function self:contains(key)
		return self._table[key] ~= nil
	end
	function self:count()
		return _count
	end
	function self:clear()
		_count = 0
		SPUtil:table_clear(self._table)
	end
	function self:key_itr()
		return pairs(self._table)
	end
	function self:key_list()
		local rtv = SPList:new()
		for k,v in self:key_itr() do
			rtv:push_back(k)
		end
		return rtv
	end

	return self
end

return SPDict
