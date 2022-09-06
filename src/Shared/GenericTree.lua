local GenericTree = {}

local BehaviorTree = require(script.Parent:WaitForChild("behavior_tree"))
local TableUtil = require(script.Parent:WaitForChild("TableUtil"))

local function MoveObject(object, position)
	object.Model.Humanoid:MoveTo(position)
	if not object.Animations:GetTrack("Walk").IsPlaying and not object.Animations:GetTrack("Stagger").IsPlaying then
		object.Animations:PlayTrack("Walk")
	end
end

local function StopObject(object)
	object.Model.Humanoid:MoveTo(object.Model:GetPrimaryPartCFrame().p)
	object.Animations:StopTrack("Walk")
end


function GenericTree:Create(newobject)
	local hasTarget_check = BehaviorTree.Task:new({
		run = function(task, object)
			if object.Target ~= nil then
				task:success()
				return
			else
				task:fail()
				-- print("shoots")
			end
		end
	})

	local IsAttacking_check = BehaviorTree.Task:new({
 		run = function(task, object)
 			if object.IsAttacking or object.KNOCKBACK then
 				task:fail()
 				return
 			else
 				task:success()
 			end
 		end
	})

	newobject.canCHECK_endanger = true
	local pathing_to_Target = BehaviorTree.Task:new({
		name = "pathing_to",
		start = function(task, object)
			local MobPos = object.Model.PrimaryPart.Position
			local TargetPos = object.Target.Character.PrimaryPart.Position

			if object.Model.Humanoid and object.Target.Character then
				if object.State.is("safe") then
					MoveObject(object, object.Target.Character:GetPrimaryPartCFrame().p)
				elseif (MobPos-TargetPos).magnitude > object.MobData.CircleRange then
					if not object.State.is("safe") then
						object.State.recover()
					end
					object.canCHECK_endanger = true
				end
			else
				object.canCHECK_endanger = false
			end
		end,
		run = function(task, object)

			-- print('wutt')
			if object.canCHECK_endanger == false then print('oml') task:fail() return end
			if object.State.is("danger") then
				task:success()
				StopObject(object)
				return
			end


			local MobPos = object.Model.PrimaryPart.Position
			local TargetPos = object.Target.Character.PrimaryPart.Position

			print((MobPos-TargetPos).magnitude > object.MobData.CircleRange, not object.State.is("safe"))
			if (MobPos-TargetPos).magnitude <= object.MobData.CircleRange and object.State.is("safe") then
				object.State.endanger()
				StopObject(object)
				-- print('uwu')
				task:success()
				return
			elseif (MobPos-TargetPos).magnitude > object.MobData.CircleRange then
				if not object.State.is("safe") then
					object.State.recover()
				end
				MoveObject(object, object.Target.Character:GetPrimaryPartCFrame().p)
				-- print('owo')
			end

			-- print('gosh darnit')
			task:running()
		end,
		finish = function(task, object)
			object.canCHECK_endanger = true
			print('moved to it boi')
		end
	})
	local avoid_others = BehaviorTree.Task:new({
		name = "avoid_others",
		start = function(task, object)
			--get list of endangered units via Mobs con troller
			--units to avoid
			--[[
					-attempt to move to Target
					-transform that vector in a direction away from other mobs

						-get negative lookVector from CFrame.new(this, that)
						-multiply this to the final CFrame with magnitude (AvoidRadius-(this-that).magnitude)
					-repeat this for any mobs within hitbox range,
					-return final vector transform

			]]

		end,
		run = function(task, object)
			-- if object.State.is("safe") then task:success() return end
			local EndangeredMobs = self:GetEndangered()

			--if not enough mobs to run from, dont do anythings
			if #EndangeredMobs < 2 then task:success() return end


			--sort, move away from closest mob
			TableUtil.FastRemoveFirstValue(EndangeredMobs, object.Id)
			if #EndangeredMobs > 1 then
				table.sort(EndangeredMobs, function(a, b)
					local adata = self:Get(a)
					local bdata = self:Get(b)

					local apos = adata.Model.PrimaryPart.Position
					local bpos = adata.Model.PrimaryPart.Position
					local opos = object.Model.PrimaryPart.Position
					if (opos-apos).magnitude < (opos-bpos).magnitude then
						return true
					else
						return false
					end
				end)
			end

			--get negative vector while moving towards Target lmaoo
			local random = math.random(-1, 2)
			if random <= 0 then
				random = -1
			else
				random = 1
			end
			local AwayMob = self:Get(EndangeredMobs[1])
			local poscf = CFrame.new(object.Model.PrimaryPart.Position, AwayMob.Model.PrimaryPart.Position) * CFrame.Angles(0, random*math.rad(45), 0)
			local negvec = -poscf.lookVector
			local extents = object.Model:GetExtentsSize()
			local size = Vector3.new(
				extents.X, 0, extents.Z
			)
			if (object.Model:GetPrimaryPartCFrame().p-AwayMob.Model:GetPrimaryPartCFrame().p).magnitude < extents.X+4 then
				object.Model.Humanoid:Move(negvec)
				print('avoiding . . .')
			else
				object.Model.Humanoid:Move(Vector3.new(0, 0, 0))
				task:success()
				return
			end

			task:running()
		end,

		finish = function(task, object)
		end
	})

	--sequence...
	--add to list of attackers if not full
	--attack if in turn, and allowed to be attacked

	local is_attacker = BehaviorTree.Task:new({
		start = function(_, object)
			if #self[object.Target.UserId].Attackers < self.AttackerLimit and object.State.is('danger') then
				delay(self.BrainRate, function()
					table.insert(self.Attackers, object.Id)
				end)
			end
		end,
		run = function(task, object)
			if TableUtil.IndexOf(self.Attackers, object.Id) ~= nil then
				task:success()
				return
			else
				task:fail()
				return
			end
			task:running()
		end
	})

	local wander = BehaviorTree.Task:new({
		start = function(task, object)
		--add strafing around Target
			--get position of Target
			--get angle of Target based on lookVector to Target
			--add 15deg to Target-mob CFrame * attack range magnitude to get point
			if object.IsAttacking then return end
			local rand = math.random(-1, 2)
			if rand < 1 then
				rand = -1
			else
				rand = 1
			end

			local TargetLookCF = CFrame.new(object.Target.Character:GetPrimaryPartCFrame().p, object.Model:GetPrimaryPartCFrame().p)
			TargetLookCF = TargetLookCF * CFrame.Angles(0, rand*math.rad(math.random(45, 60)), 0)

			local calcray = Ray.new(TargetLookCF.p, TargetLookCF.lookVector*object.MobData.CircleRange)
			local _, newpos = workspace:FindPartOnRayWithWhitelist(calcray, {})

			object.wanderpos = newpos
			MoveObject(object, object.wanderpos)
		end,
		run = function(task, object)
			if object.IsAttacking then task:success() return end
			if (object.Model:GetPrimaryPartCFrame().p-object.wanderpos).magnitude > 1.5 then
				MoveObject(object, object.wanderpos)
				task:running()
			else
				StopObject(object)
				task:success()
				return
			end
		end
	})

	local can_attack = BehaviorTree.Task:new({
		run = function(task, object)
			--check if attacker, if number 1 of attacker, and if last attack was long ago
			if TableUtil.IndexOf(self.Attackers, object.Id) == 1 and self.LastAttack >= self.TimePerAttack then
				StopObject(object)
				print('attacked!')

				table.remove(self.Attackers, 1)
				object.LastAttack = 0
				self.LastAttack = 0

				object.IsAttacking = true
				object.Animations:PlayTrack("Attack")
				delay(object.Animations:GetTrack("Attack").Length+0.3, function()
					object.IsAttacking = false
				end)
				-- local s
				-- s = object.Animations:GetTrack("Attack").Stopped:Connect(function()
				-- 	object.IsAttacking = false
				-- 	s:Disconnect()
				-- end)
				task:success()
				return
			else
				task:fail()
				return
			end

			task:running()
		end
	})

	--wrap all movement based tasks in a check to whether or not the object is:
		-- * moving
		-- * in hitstun
	local NewTree = BehaviorTree:new({
		tree = BehaviorTree.Sequence:new({
			nodes = {
				hasTarget_check,
				BehaviorTree.AlwaysSucceedDecorator:new({
					node = BehaviorTree.Sequence:new({
						nodes = {
							IsAttacking_check,
							pathing_to_Target --wrapped pathing to Target
						}
					})
				}),

				BehaviorTree.AlwaysSucceedDecorator:new({
					node = BehaviorTree.Sequence:new({
						nodes = {
							IsAttacking_check,
							-- avoid_others, --wrapped avoidance
						}
					})
				}),

				BehaviorTree.AlwaysSucceedDecorator:new({
					node = BehaviorTree.Sequence:new({
						nodes = {
							is_attacker,
							BehaviorTree.Priority:new({
								nodes = {
									can_attack,
									BehaviorTree.Priority:new({
										nodes = {
											BehaviorTree.AlwaysFailDecorator:new({
												node = BehaviorTree.AlwaysSucceedDecorator:new({
													node = BehaviorTree.Sequence:new({
														nodes = {
															IsAttacking_check,
															avoid_others, --wrapped avoidance
														}
													})
												}),
											}),
											BehaviorTree.AlwaysSucceedDecorator:new({
												node = BehaviorTree.Sequence:new({
													nodes = {
														IsAttacking_check,
														wander, --wrapped wander
													}
												})
											}),
										}
									})
								}
							})
						}
					})
				})
			}
		})
	})

	NewTree:setObject(newobject)
	return NewTree
end

return GenericTree