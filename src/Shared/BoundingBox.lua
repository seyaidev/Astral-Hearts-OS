--[[ @brief Returns the bounding box for a group of parts.
	@param model The model to get the bounding box of, or a list of instances.
	@param cframe The orientation on which the bounding box should be aligned. If omitted, this will be axis-aligned.
	@return center The absolute center of the bounding box.
	@return size The size of the bounding box.
--]]
function GetBoundingBox(model, cframe)
	if type(model) == "userdata" then
		model = model:GetDescendants();
	end
	if not cframe then
		cframe = CFrame.new();
	end
	local ax, ay, az;
	local bx, by, bz;
	for i, v in pairs(model) do
        if v:IsA("BasePart") then
			if not ax then
				ax, ay, az = v.Position.X, v.Position.Y, v.Position.Z;
				bx, by, bz = ax, ay, az;
			end
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:toObjectSpace(v.CFrame):components();
			r00, r01, r02 = math.abs(r00), math.abs(r01), math.abs(r02);
			r10, r11, r12 = math.abs(r10), math.abs(r11), math.abs(r12);
			r20, r21, r22 = math.abs(r20), math.abs(r21), math.abs(r22);
			local sx, sy, sz = v.Size.x, v.Size.y, v.Size.z;
			local dx = r00 * sx + r01 * sy + r02 * sz;
			local dy = r10 * sx + r11 * sy + r12 * sz;
			local dz = r20 * sx + r21 * sy + r22 * sz;
			local lx = x - dx; if lx < ax then ax = lx; end
			local ly = y - dy; if ly < ay then ay = ly; end
			local lz = z - dz; if lz < az then az = lz; end
			local hx = x + dx; if hx > bx then bx = hx; end
			local hy = y + dy; if hy > by then by = hy; end
			local hz = z + dz; if hz > bz then bz = hz; end
		end
	end
	if ax then
		local center = cframe:toWorldSpace(CFrame.new((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2));
		local size = Vector3.new(bx - ax, by - ay, bz - az);
		return center, size;
	else
		return nil;
	end
end

return GetBoundingBox