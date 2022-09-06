local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local Attachments = require(ReplicatedStorage.Aero.Shared:FindFirstChild("Attachments"))

local WeaponManipulation = {}

-- local PlayerGroupId = GetRemoteFunction("GetPlayerGroup"):InvokeServer()

function WeaponManipulation:LoadWeapons(Player)
	local Disc = Player.Character:WaitForChild("Disc")
	for i, Base in pairs(Player:WaitForChild("pBackpack"):GetChildren()) do
		print('1')
		if CollectionService:HasTag(Base, "PrimaryWeapon") then
			print('2')
			local DiscWeld = Instance.new("WeldConstraint")
			if Disc:FindFirstChild("Handle") then
				DiscWeld.Part0 = Disc:FindFirstChild("Handle")
				DiscWeld.Name = "DiscWeld"

				local toCF = Attachments:getAttachmentWorldCFrame(Disc:FindFirstChild("weaponAttachment", true))

				if Player.Character:FindFirstChild("DiscWeapon") then
					Player.Character:FindFirstChild("DiscWeapon"):Destroy()
				end

				local DiscWeapon = Base:Clone()
				local OrigAtt = Base:FindFirstChild("HandleAttachment", true)
				if Base:FindFirstChild("discAttachment", true) then
					OrigAtt = Base:FindFirstChild("discAttachment", true)
				end
				
				DiscWeapon.Name = "DiscWeapon"
				DiscWeapon:FindFirstChild("Trail", true):Destroy()

				local ogmat = DiscWeapon.Material
				local ogt = DiscWeapon.Transparency
				

				local ogmatv = Instance.new("StringValue")
				ogmatv.Name = "OriginalMaterial"
				ogmatv.Value = tostring(ogmat.Name)

				local ogtv = Instance.new("NumberValue")
				ogtv.Name = "OriginalTransparency"
				ogtv.Value = ogt
				
				ogmatv.Parent = DiscWeapon
				ogtv.Parent = DiscWeapon

				local trail = DiscWeapon:FindFirstChild("Trail", true)
				if trail then trail:Destroy() end
				DiscWeapon.CastShadow = false
				DiscWeapon.Transparency = 1
				--original parenting here

				for i, v in ipairs(DiscWeapon:GetDescendants()) do
					if v:IsA("BasePart") then
						local vogmat = v.Material
						local vogt = v.Transparency
						-- v.Material = Enum.Material.Neon

						local vogmatv = Instance.new("StringValue")
						vogmatv.Name = "OriginalMaterial"
						vogmatv.Value = tostring(vogmat.Name)

						local vogtv = Instance.new("NumberValue")
						vogtv.Name = "OriginalTransparency"
						vogtv.Value = vogt
						
						vogmatv.Parent = v
						vogtv.Parent = v

						v.CastShadow = false
						v.Transparency = 1
					end
				end

				if DiscWeapon:FindFirstChild("discAttachment", true) then
					print("disc attachment")
					Attachments:setAttachmentWorldCFrame(DiscWeapon:FindFirstChild("discAttachment", true), toCF)
				else
					Attachments:setAttachmentWorldCFrame(DiscWeapon:FindFirstChild("HandleAttachment", true), toCF)
				end
				local sign = 1
				local offsetCF = CFrame.new()
				if CollectionService:HasTag(OrigAtt, "Equip Inverse") then
					sign = -1
				end

				offsetCF = CFrame.new(OrigAtt.Position.X*sign, OrigAtt.Position.Y*sign, OrigAtt.Position.Z*sign)


				local angleCF = CFrame.Angles(math.rad(OrigAtt.Orientation.X), math.rad(OrigAtt.Orientation.Y), math.rad(OrigAtt.Orientation.Z))
				if OrigAtt:FindFirstChild("Rotation") ~= nil then
					local ext = OrigAtt:FindFirstChild("Rotation")
					angleCF = CFrame.Angles(math.rad(ext.Value.X), math.rad(ext.Value.Y), math.rad(ext.Value.Z))
				end

				if DiscWeapon:FindFirstChild("discAttachment", true) then
					DiscWeapon.CFrame = (DiscWeapon.CFrame * (DiscWeapon:FindFirstChild("discAttachment", true).CFrame)* angleCF) * offsetCF
				else
					DiscWeapon.CFrame = (DiscWeapon.CFrame * (DiscWeapon:FindFirstChild("HandleAttachment", true).CFrame)* angleCF) * offsetCF
				end
				DiscWeld.Part1 = DiscWeapon
				DiscWeld.Parent = DiscWeapon
				DiscWeapon.Parent = Player.Character
			end

			--CREATE HAND WEAPONS
			local rh = Player.Character:WaitForChild("RightHand")
			local PrimaryWeld = Instance.new("WeldConstraint")
			PrimaryWeld.Part0 = Player.Character:WaitForChild("WeaponWeld")
			PrimaryWeld.Name = "PrimaryWeld"

			local toCF = Attachments:getAttachmentWorldCFrame(rh:FindFirstChild("RightGripAttachment", true))

			if Player.Character:FindFirstChild("PrimaryWeapon") then
				Player.Character:FindFirstChild("PrimaryWeapon"):Destroy()
			end

			local NewWeapon = Base:Clone()
			NewWeapon.Name = "PrimaryWeapon"
			local OrigAtt = Base:FindFirstChild("HandleAttachment", true)
			-- local NewAcc = Instance.new("Accessory")
			

			local ogmat = NewWeapon.Material
			local ogt = NewWeapon.Transparency

			local ogmatv = Instance.new("StringValue")
			ogmatv.Name = "OriginalMaterial"
			ogmatv.Value = tostring(ogmat.Name)

			local ogtv = Instance.new("NumberValue")
			ogtv.Name = "OriginalTransparency"
			ogtv.Value = ogt
			
			ogmatv.Parent = NewWeapon
			ogtv.Parent = NewWeapon

			NewWeapon.CastShadow = false
			NewWeapon.Transparency = 1
			--original parenting here


			for i, v in ipairs(NewWeapon:GetDescendants()) do
				if v:IsA("BasePart") then
					local vogmat = v.Material
					local vogt = v.Transparency

					local vogmatv = Instance.new("StringValue")
					vogmatv.Name = "OriginalMaterial"
					vogmatv.Value = tostring(vogmat.Name)

					local vogtv = Instance.new("NumberValue")
					vogtv.Name = "OriginalTransparency"
					vogtv.Value = vogt
					
					vogmatv.Parent = v
					vogtv.Parent = v

					v.Material = Enum.Material.Neon
					v.CastShadow = false
					v.Transparency = 1
				end
			end

			PrimaryWeld.Parent = NewWeapon

			Attachments:setAttachmentWorldCFrame(NewWeapon:FindFirstChild("HandleAttachment", true), toCF)

			local sign = 1
			local offsetCF = CFrame.new()
			if CollectionService:HasTag(OrigAtt, "Equip Inverse") then
				sign = -1
			end
			
			offsetCF = CFrame.new(OrigAtt.Position.X*sign, OrigAtt.Position.Y*sign, OrigAtt.Position.Z*sign)

			local angleCF = CFrame.Angles(math.rad(OrigAtt.Orientation.X), math.rad(OrigAtt.Orientation.Y), math.rad(OrigAtt.Orientation.Z))
			if OrigAtt:FindFirstChild("Rotation") ~= nil then
				local ext = OrigAtt:FindFirstChild("Rotation")
				angleCF = CFrame.Angles(math.rad(ext.Value.X), math.rad(ext.Value.Y), math.rad(ext.Value.Z))
			end

			NewWeapon.CFrame = (NewWeapon.CFrame * (NewWeapon:FindFirstChild("HandleAttachment", true).CFrame)* angleCF) * offsetCF
			PrimaryWeld.Part1 = NewWeapon
			PrimaryWeld.Parent = NewWeapon
			NewWeapon.Parent = Player.Character	
			
			local Particles = ReplicatedStorage.Assets.Particles:FindFirstChild("WeaponSpawn")
			local NewParticles = Particles.SpawnParticles:Clone()
			Debris:AddItem(NewParticles, 10)
			NewParticles.Parent = NewWeapon
			NewParticles.Enabled = true
			delay(0.4, function()
				NewParticles.LockedToPart = false
				NewParticles.VelocityInheritance = 0.2
				wait(0.1)
				NewParticles.Enabled = false
			end)

			if CollectionService:HasTag(Base, "DualWield") then
				local rh = Player.Character:WaitForChild("LeftHand")
				local PrimaryWeld = Instance.new("WeldConstraint")
				PrimaryWeld.Part0 = rh
				PrimaryWeld.Name = "PrimaryWeld"

				local toCF = Attachments:getAttachmentWorldCFrame(rh:FindFirstChild("LeftGripAttachment", true))

				local NewWeapon = Base:Clone()
				local OrigAtt = Base:FindFirstChild("HandleAttachment", true)

				-- local NewAcc = Instance.new("Accessory")
				-- for i, v in pairs(NewWeapon:GetDescendants()) do
				-- 	if v:IsA("BasePart") then
				-- 		v.CollisionGroupId = PlayerGroupId
				-- 	end
				-- end
				NewWeapon.Parent = Player.Character

				PrimaryWeld.Parent = NewWeapon
				-- NewAcc.Parent = Player.Character


				Attachments:setAttachmentWorldCFrame(NewWeapon:FindFirstChild("HandleAttachment", true), toCF)

				local sign = 1
				local offsetCF = CFrame.new()
				if CollectionService:HasTag(OrigAtt, "Equip Inverse") then
					sign = -1
				end
				-- if CollectionService:HasTag(OrigAtt, "Equip OffsetX") then
				-- 	offsetCF = CFrame.new(OrigAtt.Position.X*sign, 0, OrigAtt.Position.Z*sign)
				-- else
					offsetCF = CFrame.new(OrigAtt.Position.X*sign, OrigAtt.Position.Y*sign, OrigAtt.Position.Z*sign)
					--print(OrigAtt.Position.X)
				-- end

				--local angleCF = CFrame.Angles(0,0,-90)
				-- local angleCF = CFrame.Angles(math.rad(270), 0, math.rad(90))
				local angleCF = CFrame.Angles(math.rad(OrigAtt.Orientation.X), math.rad(OrigAtt.Orientation.Y), math.rad(OrigAtt.Orientation.Z))
				if OrigAtt:FindFirstChild("Rotation") ~= nil then
					local ext = OrigAtt:FindFirstChild("Rotation")
					angleCF = CFrame.Angles(math.rad(ext.Value.X), math.rad(ext.Value.Y), -math.rad(ext.Value.Z))
				end

				NewWeapon.Handle.CFrame = (NewWeapon.Handle.CFrame * (NewWeapon:FindFirstChild("HandleAttachment", true).CFrame)* angleCF) * offsetCF
				PrimaryWeld.Part1 = NewWeapon.Handle
				NewWeapon.Handle.Anchored = false
				PrimaryWeld.Parent = NewWeapon
			end
		end
	end
end

function WeaponManipulation:ViewportEquip(ItemData)
	local Player = game.Players.LocalPlayer
	local Base = ReplicatedStorage.Assets.Weapons:FindFirstChild(ItemData.ItemId, true)
	--create viewport clone


	local origViewportClone = Player.ViewportClone

	for i, v in pairs(origViewportClone:GetChildren()) do
		if CollectionService:HasTag(v, "PrimaryWeapon") then
			v:Destroy()
		end
	end

	local newViewportClone = origViewportClone:Clone()

	newViewportClone.PrimaryPart.Anchored = true
	newViewportClone.Parent = workspace
	newViewportClone:SetPrimaryPartCFrame(CFrame.new(0, 1000, 0))

	local rh = newViewportClone:WaitForChild("Disc")
	local PrimaryWeld = Instance.new("WeldConstraint")
	PrimaryWeld.Part0 = rh.Handle
	PrimaryWeld.Name = "PrimaryWeld"

	local toCF = Attachments:getAttachmentWorldCFrame(rh:FindFirstChild("weaponAttachment", true))

	local NewWeapon = Base:Clone()
	local OrigAtt = Base:FindFirstChild("HandleAttachment", true)
	CollectionService:AddTag(NewWeapon, "PrimaryWeapon")
	-- local NewAcc = Instance.new("Accessory")
	NewWeapon.Parent = newViewportClone

	-- for i, v in pairs(NewWeapon:GetDescendants()) do
	-- 	if v:IsA("BasePart") then
	-- 		v.CollisionGroupId = PlayerGroupId
	-- 	end
	-- end

	PrimaryWeld.Parent = NewWeapon
	-- NewAcc.Parent = newViewportClone
	Attachments:setAttachmentWorldCFrame(NewWeapon:FindFirstChild("HandleAttachment", true), toCF)

	local sign = 1
	local offsetCF = CFrame.new()
	if CollectionService:HasTag(OrigAtt, "Equip Inverse") then
		sign = -1
	end
			-- if CollectionService:HasTag(OrigAtt, "Equip OffsetX") then
			-- 	offsetCF = CFrame.new(OrigAtt.Position.X*sign, 0, OrigAtt.Position.Z*sign)
			-- else
	offsetCF = CFrame.new(OrigAtt.Position.X*sign, OrigAtt.Position.Y*sign, OrigAtt.Position.Z*sign)
				--print(OrigAtt.Position.X)
			-- end

			--local angleCF = CFrame.Angles(0,0,-90)
			-- local angleCF = CFrame.Angles(math.rad(270), 0, math.rad(90))
	local angleCF = CFrame.Angles(math.rad(OrigAtt.Orientation.X), math.rad(OrigAtt.Orientation.Y), math.rad(OrigAtt.Orientation.Z))
	if OrigAtt:FindFirstChild("Rotation") ~= nil then
		local ext = OrigAtt:FindFirstChild("Rotation")
		angleCF = CFrame.Angles(math.rad(ext.Value.X), math.rad(ext.Value.Y), math.rad(ext.Value.Z))
	end

	NewWeapon.CFrame = (NewWeapon.CFrame * (NewWeapon:FindFirstChild("HandleAttachment", true).CFrame)* angleCF) * offsetCF
	PrimaryWeld.Part1 = NewWeapon
	PrimaryWeld.Parent = NewWeapon

	origViewportClone:Destroy()
	newViewportClone.Parent = game.Players.LocalPlayer
end

function WeaponManipulation:SetupDisc(Player)

	if Player == nil then return end
	if Player.Character == nil then return end
	if Player.Character:FindFirstChild("Humanoid") then
		if Player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
	end

	-- wait(0.1)

	local Disc = Player.Character:WaitForChild("Disc")

	for i, v in ipairs(Disc.Visual:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = v:FindFirstChild("OriginalTransparency").Value
		end
	end

	local DiscWeapon = Player.Character:FindFirstChild("DiscWeapon")
	if DiscWeapon ~= nil then
		if Player == game.Players.LocalPlayer then
			DiscWeapon.Material = Enum.Material.Neon
			Player.Character.PrimaryPart:FindFirstChild("Sheathe"):Play()
		end
		DiscWeapon.Transparency = DiscWeapon:FindFirstChild("OriginalTransparency").Value

		delay(0.5, function()
			DiscWeapon.Transparency = DiscWeapon:FindFirstChild("OriginalTransparency").Value
			DiscWeapon.Material = DiscWeapon.OriginalMaterial.Value
			DiscWeapon.CastShadow = true
		end)

		local Particles = ReplicatedStorage.Assets.Particles:FindFirstChild("WeaponSpawn")
		local NewParticles = Particles.SpawnParticles:Clone()
		Debris:AddItem(NewParticles, 10)
		NewParticles.Parent = DiscWeapon
		NewParticles.Enabled = true
		delay(0.4, function()
			NewParticles.LockedToPart = false
			wait(0.1)
			NewParticles.Enabled = false
		end)

		for i, v in ipairs(DiscWeapon:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Neon
				v.CastShadow = false
				v.Transparency = 1
				
				v.Transparency = v:FindFirstChild("OriginalTransparency").Value


				delay(0.5, function()
					v.Transparency = v:FindFirstChild("OriginalTransparency").Value
					v.Material = v.OriginalMaterial.Value
					v.CastShadow = true
				end)
			end

			
		end
	end
end

function WeaponManipulation:Equip(Player)
	if Player == nil then return end
	if Player.Character == nil then return end
	if Player.Character:FindFirstChild("Humanoid") then
		if Player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
	end

	local Disc = Player.Character:WaitForChild("Disc")
	local DW = Player.Character:FindFirstChild("DiscWeapon")
	if DW ~= nil then
		DW.Material = Enum.Material.Neon
		DW.CastShadow = false
		if Player == game.Players.LocalPlayer then
			Player.Character.PrimaryPart:FindFirstChild("Unsheathe"):Play()
		end
		DW.Transparency = 1
		
		for i, v in ipairs(DW:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Neon
				v.CastShadow = false
				v.Transparency = 1
			end
		end


		local Particles = ReplicatedStorage.Assets.Particles:FindFirstChild("WeaponSpawn")
		local NewParticles = Particles.SpawnParticles:Clone()
		Debris:AddItem(NewParticles, 10)
		NewParticles.Parent = DW
		NewParticles.Enabled = true
		delay(0.4, function()
			NewParticles.LockedToPart = false
			wait(0.1)
			NewParticles.Enabled = false
		end)

		for i, v in ipairs(Disc.Visual:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
		end
	end

	local PrimaryWeapon = Player.Character:FindFirstChild("PrimaryWeapon")
	PrimaryWeapon.Transparency = PrimaryWeapon:FindFirstChild("OriginalTransparency").Value
	delay(0.5, function()
		if PrimaryWeapon:FindFirstChild("OriginalTransparency") then
			PrimaryWeapon.Transparency = PrimaryWeapon:FindFirstChild("OriginalTransparency").Value
		end
		PrimaryWeapon.Material = PrimaryWeapon.OriginalMaterial.Value
		PrimaryWeapon.CastShadow = true
	end)

	local Particles = ReplicatedStorage.Assets.Particles:FindFirstChild("WeaponSpawn")
	local NewParticles = Particles.SpawnParticles:Clone()
	Debris:AddItem(NewParticles, 10)
	NewParticles.Parent = PrimaryWeapon
	NewParticles.Enabled = true
	delay(0.4, function()
		NewParticles.LockedToPart = false
		wait(0.1)
		NewParticles.Enabled = false
	end)

	for i, v in ipairs(PrimaryWeapon:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Material = Enum.Material.Neon
			v.CastShadow = false
			v.Transparency = 1
			if v:FindFirstChild("OriginalTransparency") then
				v.Transparency = v:FindFirstChild("OriginalTransparency").Value
			end


			delay(0.5, function()
				v.Transparency = v:FindFirstChild("OriginalTransparency").Value
				v.Material = v.OriginalMaterial.Value
				v.CastShadow = true
			end)
		end

		
	end
end

function WeaponManipulation:Unequip(Player)
	if Player == nil then return end
	if Player.Character == nil then return end
	if Player.Character:FindFirstChild("Humanoid") then
		if Player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
	end
	
	local PrimaryWeapon = Player.Character:FindFirstChild("PrimaryWeapon")
	if PrimaryWeapon ~= nil then
		PrimaryWeapon.Material = Enum.Material.Neon
		PrimaryWeapon.CastShadow = false
		if Player == game.Players.LocalPlayer then

			Player.Character.PrimaryPart:FindFirstChild("Shatter"):Play()
		end

		PrimaryWeapon.Transparency = 1
		for i, v in ipairs(PrimaryWeapon:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Neon
				v.CastShadow = false
				v.Transparency = 1
			end
		end


		local Particles = ReplicatedStorage.Assets.Particles:FindFirstChild("WeaponSpawn")
		local NewParticles = Particles.SpawnParticles:Clone()
		Debris:AddItem(NewParticles, 10)
		NewParticles.Parent = PrimaryWeapon
		NewParticles.Enabled = true
		delay(0.4, function()
			NewParticles.LockedToPart = false
			wait(0.1)
			NewParticles.Enabled = false
		end)
	end
end

return WeaponManipulation