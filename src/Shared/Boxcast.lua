--credit to scarious for this god module

--t1, origin CFrame
--d, distance
--s, size (vector3, center based as the middle)
--l, ignore list (array)

local cf		=CFrame.new
local ray		=Ray.new
local raycast	=workspace.FindPartOnRayWithWhitelist
local insert	=table.insert
local pi		=math.pi

local function boxcast(t1,d,s,l, rep)
	--reuse rays if possible in the future
	if rep then return end
	local td=t1*d
	local m0=(t1.p-td).Magnitude
	local t2=t1*cf(0,0,-m0)
	local x0,y0=s.X,s.Y
	local x1,y1=x0/2,y0/2
	local n0,n1,n2,n3=cf(-x1,-y1,0),cf(-x1,y1,0),cf(x1,y1,0),cf(x1,y1,0)
	local b0,b1,b2,b3=cf(-x1,0,0),cf(0,y1,0),cf(-x1,0,0),cf(0,-y1,0)
	local i0,i1,i2,i3,i4,i5,i6,i7=t1*n0,t1*n1,t1*n2,t1*n3,t1*b0,t1*b1,t1*b2,t1*b3
	local c0,c1,c2,c3,c4,c5,c6,c7=t2*n0,t2*n1,t2*n2,t2*n3,t2*b0,t2*b1,t2*b2,t2*b3
	local ol={t1.p,i0.p,i1.p,i2.p,i3.p,i4.p,i5.p,i6.p,i7.p}
	local tl={t2.p,c0.p,c1.p,c2.p,c3.p,c4.p,c5.p,c6.p,c7.p}
	local a=t1.lookVector
	local ax,ay,az=a.x,a.y,a.z
	local il=l or {}
	local h,p,n,c
	local hs = {}
	local ps = {}
	local function checkHit(hit)
		for i, v in pairs(hs) do
			if v == hit or (hit:FindFirstAncestorOfClass("Model") == hit:FindFirstAncestorOfClass("Model")) then
				return false
			end
		end
		return true
	end
	for i=1,#ol do
		local o=ol[i]
		for j=1,#tl do
			local t=tl[j]
			local to=t-o
			local m,u=to.magnitude,to.unit
			local um=u*m
			local h0,p0,n0=raycast(workspace,ray(o,um),il)
			if h0 and p0 and n0 then
				local bx,by,bz=p0.x,p0.y,p0.z
				local ab=ax*bx+ay*by+az*bz
				local sc=(c and (c>ab and true or false)) or true
				if sc then
					if checkHit(h0) then
						table.insert(hs, h0)
						table.insert(ps, p0)
					end
				end
			end
		end
	end
	return hs,ps,n
end

return boxcast