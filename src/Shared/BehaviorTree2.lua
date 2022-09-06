local BehaviorTree = {} do
    
	local function ProcessNode(node, nodes)
		if node.type == "task" then
			local task = {
				type = "task",
				status = nil,
				
				start = node.params.start,
				run = node.params.run,
				finish = node.params.finish,
				
				onsuccess = true,
				onfail = false
			}

			--decorators
			if node.params.decorator ~= nil then
				if node.params.decorator == "always_succeed" then
					task.task = {
						running = function(self) task.status = "running" end,
						success = function(self) task.status = "success" end,
						fail = function(self) task.status = "success" end
					}
				
				elseif node.params.decorator == "always_fail" then
					task.task = {
						running = function(self) task.status = "running" end,
						success = function(self) task.status = "fail" end,
						fail = function(self) task.status = "fail" end
					}

				elseif node.params.decorator == "invert" then
					task.task = {
						running = function(self) task.status = "running" end,
						success = function(self) task.status = "fail" end,
						fail = function(self) task.status = "success" end
					}

				end
			else
				task.task = {
					running = function(self) task.status = "running" end,
					success = function(self) task.status = "success" end,
					fail = function(self) task.status = "fail" end
				}
			end
			
			nodes[#nodes + 1] = task


		elseif node.type == "decorator" then

			node.params.node.params.decorator = node.params.decorator
			ProcessNode(node.params.node, nodes)

		elseif node.type == "sequence" then
			-- child.success = final ? parent.success : parent.next
			-- child.fail = parent.fail (default)
				
			for i,childNode in pairs(node.params.nodes) do
				local final = i == #node.params.nodes
				local start = #nodes + 1
				
				ProcessNode(childNode, nodes)
				
				for i = start, #nodes do
					local node = nodes[i]
					
					-- on child.success, !final ? parent.next : parent.success
					if node.onsuccess == true then
						node.onsuccess = not final and #nodes + 1 or true
					end
					
					if node.onfail == true then
						node.onfail = not final and #nodes + 1 or true
					end
				end
			end
		elseif node.type == "priority" then
			-- child.success = parent.success (default)
			-- child.fail = final ? parent.fail : parent.next
			
			for i,childNode in pairs(node.params.nodes) do
				local final = i == #node.params.nodes
				local start = #nodes + 1
				
				ProcessNode(childNode, nodes)
				
				for i = start, #nodes do
					local node = nodes[i]
					
					-- on child.fail, !final ? parent.next : parent.fail
					if node.onsuccess == false then
						node.onsuccess = not final and #nodes + 1 or false
					end
					
					if node.onfail == false then
						node.onfail = not final and #nodes + 1 or false
					end
				end
			end
		elseif node.type == "random" then
			-- child.success = parent.success (default)
			-- child.fail = parent.fail (default)
			
			local random = {
				type = "random",
				indices = {}
			}
			
			nodes[#nodes + 1] = random
			
			for _,childNode in pairs(node.params.nodes) do
				random.indices[#random.indices + 1] = #nodes + 1
				ProcessNode(childNode, nodes)
			end
		elseif node.type == "tree" then
			local start = #nodes + 1
			
			ProcessNode(node.tree, nodes)
			
			for i = start, #nodes do
				local node = nodes[i]
				
				if node.onsuccess == true or node.onsuccess == false then
					node.onsuccess = #nodes + 1
				end
				
				if node.onfail == true or node.onfail == false then
					node.onfail = #nodes + 1
				end
			end
		else
			error("ProcessNode: bad node.type " .. tostring(node.type))
		end
	end
	
	
	
	local TreeProto = {}
	
	function TreeProto:run(dt)
		if self.running then
			-- warn(debug.traceback("Tried to run BehaviorTree while it was already running"))
			return
		end
		
		local nodes = self.nodes
		local obj = self.object
		local i = self.index
		local nodeCount = #nodes
		
		local didResume = self.paused
		self.paused = false
		self.running = true
	
		while i <= nodeCount do
			local node = nodes[i]
			
			if node.type == "task" then
				local task = node.task
				
				if didResume then
					didResume = false
				elseif node.start then
					node.start(task, obj, dt)
				end
				
				node.status = nil
				node.run(task, obj, dt)
				
				if not node.status then
					warn("node.run did not call success, running or fail, acting as fail")
					node.status = "fail"
				end
				
				if node.status == "running" then
					self.paused = true
					break
				elseif node.status == "success" then
					if node.finish then
						node.finish(task, obj, dt)
					end
					
					i = node.onsuccess
				elseif node.status == "fail" then
					if node.finish then
						node.finish(task, obj, dt)
					end
					
					i = node.onfail
				else
					error("bad node.status")
				end
			elseif node.type == "random" then
				i = node.indices[math.random(1, #node.indices)]
			else
				error("bad node.type")
			end
		end
		
		self.index = i <= nodeCount and i or 1
		self.running = false
	end
			
	function TreeProto:setObject(object)
	 	self.object = object
	end
	
	function TreeProto:clone()
		return setmetatable({
			nodes = self.nodes,
			index = self.index,
			object = self.object
		}, { __index = TreeProto })
	end
	
	
	
	function BehaviorTree:new(params)
		local tree = params.tree
		local nodes = {}
		
		ProcessNode({ type = "tree", tree = tree }, nodes)
		
		return setmetatable({
			nodes = nodes,
			index = 1,
			object = nil
		}, { __index = TreeProto })
	end
	
	BehaviorTree.Task = {
		new = function(_, params)
			return {
				type = "task",
				params = params
			}
		end
	}
	
	BehaviorTree.Sequence = {
		new = function(_, params)
			return {
				type = "sequence",
				params = params
			}
		end
	}
	
	BehaviorTree.Priority = {
		new = function(_, params)
			return {
				type = "priority",
				params = params
			}
		end
	}
	
	BehaviorTree.Random = {
		new = function(_, params)
			return {
				type = "random",
				params = params
			}
		end
	}

	--Decorators
	BehaviorTree.AlwaysSucceedDecorator = {
		new = function(_, params)
			params.decorator = "always_succeed"
			return {
				type = "decorator",
				params = params
			}
		end
	}

	BehaviorTree.AlwaysFailDecorator = {
		new = function(_, params)
			params.decorator = "always_fail"
			return {
				type = "decorator",
				params = params
			}
		end
	}

	BehaviorTree.InvertDecorator = {
		new = function(_, params)
			params.decorator = "invert"
			return {
				type = "decorator",
				params = params
			}
		end
	}
end

return BehaviorTree