local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SSort = require(script.Parent:WaitForChild("SSort"))
local RandomLua = require(script.Parent:WaitForChild("RandomLua"))

local SPList = {}

local rand = nil
function SPList:new()
	local self = {}
	self._table = {}

	function self:push_back(element)
		self._table[#self._table+1] = element
		return #self._table
	end
	function self:push_front(element)
		table.insert(self._table, 1, element)
		return #self._table
	end
	function self:push_back_table_list(arr)
		assert(type(arr) == "table")
		for i=1,#arr do
			self:push_back(arr[i])
		end
		return self
	end
	function self:push_back_from_list(list)
		for i=1,list:count() do
			self:push_back(list:get(i))
		end
		return self
	end
	function self:find(val,fncmp)
		for i=1,#self._table do
			if fncmp then
				if fncmp(self._table[i],val) then
					return i
				end
			else
				if self._table[i] == val then
					return i
				end
			end
		end
		return -1
	end
	function self:remove(element,fncmp)
		local i = self:find(element,fncmp)
		if i ~= -1 then
			self:remove_at(i)
			return true
		end
		return false
	end
	function self:contains(val)
		local find = self:find(val,function(a,b) return a == b end)
		return find ~= -1
	end
	function self:back()
		return self._table[#self._table]
	end
	function self:pop_back()
		local rtv = self._table[#self._table]
		self._table[#self._table] = nil
		return rtv
	end
	function self:pop_front()
		local rtv = self:get(1)
		self:remove_at(1)
		return rtv
	end
	function self:get(i)
		return self._table[i]
	end
	function self:count()
		return #self._table
	end
	function self:remove_at(i)
		table.remove(self._table, i)
	end
	function self:clear()
		while self:count() > 0 do
			self:pop_back()
		end
	end
	function self:sort(sortfn)
		SSort:sort(self._table,function(a,b)
			local rtv = sortfn(a,b)
			if type(rtv) == "number" then
				if rtv > 0 then
					return true
				else
					return false
				end
			end
			return rtv
		end)
	end

	function self:random()
		if rand == nil then
			rand = RandomLua.mwc(os.time())
		end

		local i = rand:rand_rangei(1,self:count()+1)
		return self:get(i)
	end

	local function deepcopy(orig)
	    local orig_type = type(orig)
	    local copy
	    if orig_type == 'table' then
	        copy = {}
	        for orig_key, orig_value in next, orig, nil do
	            copy[deepcopy(orig_key)] = deepcopy(orig_value)
	        end
	        setmetatable(copy, deepcopy(getmetatable(orig)))
	    else -- number, string, boolean, etc
	        copy = orig
	    end
	    return copy
	end
	function self:table_copy()
		return deepcopy(self._table)
	end

	return self
end

return SPList
