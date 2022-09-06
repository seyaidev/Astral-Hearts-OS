local function findModelCentre(paramModel)
    local prim = paramModel:GetPrimaryPartCFrame().p;
    local minX, minY, minZ, maxX, maxY, maxZ;
    for _,value in pairs(paramModel:GetDescendants()) do
        if (value:IsA("BasePart")
            and value ~= paramModel.PrimaryPart
        --[[	and value.Parent.ClassName ~= "Accessory"
            and value.Parent.ClassName ~= "Accoutrement"]]) then
            local position, size, mesh = value.Position, value.Size, value:FindFirstChildWhichIsA("SpecialMesh");
            if (mesh) then position = position + mesh.Offset; size = mesh.Scale; end;
            -- Using CFrames to simply apply offsets on an angle.
            local high = 
                (CFrame.new(position) * 
                CFrame.Angles(math.rad(value.Orientation.X), math.rad(value.Orientation.Y), math.rad(value.Orientation.Z))) *
                CFrame.new((size/2));
            local low = (CFrame.new(position) *
                CFrame.Angles(math.rad(value.Orientation.X), math.rad(value.Orientation.Y), math.rad(value.Orientation.Z))) *
                CFrame.new(-(size/2));
            -- Calculate local highs and lows.
            local max, min = high.p, low.p;
            local hiX, hiY, hiZ = math.max(max.X,min.X), math.max(max.Y,min.Y), math.max(max.Z,min.Z);
            local loX, loY, loZ = math.min(max.X,min.X), math.min(max.Y,min.Y), math.min(max.Z, min.Z);
            -- Fix global highs and lows.
            if (minX == nil or minX > loX) then minX = loX; end;
            if (maxX == nil or maxX < hiX) then maxX = hiX; end;
            if (minY == nil or minY > loY) then minY = loY; end;
            if (maxY == nil or maxY < hiY) then maxY = hiY; end;
            if (minZ == nil or minZ > loZ) then minZ = loZ; end;
            if (maxZ == nil or maxZ < hiZ) then maxZ = hiZ; end;	
        end;							
    end;
    local min, max = Vector3.new(minX,minY,minZ), Vector3.new(maxX, maxY,maxZ);
    local result = min:Lerp(max, 0.5);
    local offset = (result) - prim;
    return result, max-min, offset;
end;

return findModelCentre