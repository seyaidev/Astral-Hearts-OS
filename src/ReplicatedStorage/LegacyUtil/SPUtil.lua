local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RandomLua = require(script.Parent:WaitForChild("RandomLua"))

local SPUtil = {}

function SPUtil:rad_to_deg(rad)
	return rad * 180.0 / math.pi
end

function SPUtil:deg_to_rad(degrees)
	return degrees * math.pi / 180
end

function SPUtil:dir_ang_deg(x,y)
	return SPUtil:rad_to_deg(math.atan2(y,x))
end

function SPUtil:ang_deg_dir(deg)
	local rad = SPUtil:deg_to_rad(deg)
	return Vector2.new(
		math.cos(rad),
		math.sin(rad)
	)
end

function SPUtil:part_cframe_rotation(part)
	return CFrame.new(-part.CFrame.p) * (part.CFrame)
end

function SPUtil:table_clear(tab)
	for k,v in pairs(tab) do tab[k]=nil end
end

function SPUtil:table_to_string(tab)
	local rtv = "{"
	for k,v in pairs(tab) do
		rtv = rtv .. string.format("[%s] => [%s],",tostring(k),tostring(v))
	end
	rtv = rtv .. "}"
	return rtv
end

function SPUtil:vec3_lerp(a,b,t)
	return a:Lerp(b,t)
end

function SPUtil:valv3(v)
	return Vector3.new(v,v,v)
end

function SPUtil:table_clone(tab)
	if typeof(tab) ~= "table" then print("SPUtil:table_clone did not receive a table") return nil end
	local newTab = {}
	for i, v in pairs(tab) do
		newTab[i] = v
	end
	return newTab
end


local localplayer_id = 0
if game.Players.LocalPlayer ~= nil then
	localplayer_id = game.Players.LocalPlayer.UserId
end
local _seed = ((tick() * 10000 + localplayer_id * 3)) % 1000
local _rand = RandomLua.mwc(_seed)

function SPUtil:rand_rangef(min,max)
	return _rand:rand_rangef(min,max)
end

function SPUtil:rand_rangei(min,max)
	return _rand:rand_rangei(min,max)
end

function SPUtil:clamp(val,min,max)
	return math.min(max,math.max(min,val))
end

local SPARSE_CONVERT_PREFIX = "__"
local function sparse_num_to_str_format(num)
	return SPARSE_CONVERT_PREFIX .. tostring(num)
end

local function sparse_str_to_num_format(str)
	if string.sub(str,1,2) ~= SPARSE_CONVERT_PREFIX then
		return nil
	end
	return tonumber(string.sub(str,3))
end

local function sparse_array_convert(a)
	if typeof(a) ~= "table" then
		return a
	end

	local max_num_key = 0
	local has_num_key = false
	for k,v in pairs(a) do
		if typeof(k) == "number" then
			if has_num_key == true then
				max_num_key = math.max(k,max_num_key)
			else
				max_num_key = k
			end
			has_num_key = true
		end
	end

	if has_num_key == false then
		return a
	end

	local is_sparse = false
	for i=1,max_num_key do
		if a[i] == nil then
			is_sparse = true
			break
		end
	end

	if is_sparse then
		for i=1,max_num_key do
			local val = a[i]
			a[i] = nil
			a[sparse_num_to_str_format(i)] = val
		end
	end

	--[[
	local a1_nil = a[1] == nil
	local a2_nil = a[2] == nil
	local a3_nil = a[3] == nil
	local a4_nil = a[4] == nil
	local all_nil = a1_nil and a2_nil and a3_nil and a4_nil

	if (all_nil == false) and (a1_nil or a2_nil or a3_nil or a4_nil) then
		a["1"] = a[1]
		a["2"] = a[2]
		a["3"] = a[3]
		a["4"] = a[4]

		a[1] = nil
		a[2] = nil
		a[3] = nil
		a[4] = nil
	end
	]]--
	return a
end

local function sparse_array_deconvert(a)
	if typeof(a) ~= "table" then
		return a
	end

	local max_num_key = 0
	local has_num_key = false
	for k,v in pairs(a) do
		local val = sparse_str_to_num_format(k)
		if val ~= nil then
			if has_num_key then
				max_num_key = math.max(val,max_num_key)
			else
				max_num_key = val
			end
			has_num_key = true
		end
	end

	if has_num_key == false then
		return a
	end

	for i=1,max_num_key do
		local itr_key = sparse_num_to_str_format(i)
		local val = a[itr_key]
		if val ~= nil then
			a[i] = val
			a[itr_key] = nil
		end
	end

	--[[
	local a1_nil = a["1"] == nil
	local a2_nil = a["2"] == nil
	local a3_nil = a["3"] == nil
	local a4_nil = a["4"] == nil
	local all_nil = a1_nil and a2_nil and a3_nil and a4_nil

	if (all_nil == false) and (a1_nil or a2_nil or a3_nil or a4_nil) then
		a[1] = a["1"]
		a[2] = a["2"]
		a[3] = a["3"]
		a[4] = a["4"]

		a["1"] = nil
		a["2"] = nil
		a["3"] = nil
		a["4"] = nil
	end
	]]--
	return a
end

local function _tmap(f, n, a, ...)
	if n > 0 then
		return f(a), _tmap(f, n-1, ...)
	end
end
local function tmap(f, ...)
	return _tmap(f, select('#', ...), ...)
end
function SPUtil:arg_convert(...)
	return tmap(sparse_array_convert, ...)
end
function SPUtil:arg_deconvert(...)
	return tmap(sparse_array_deconvert, ...)
end

function SPUtil:tpack(...)
	local rtv = {}
	for i,v in pairs{...} do
		rtv[i] = v
	end
	return rtv
end

function SPUtil:tunpack(pack)
	return unpack(pack)
end

function SPUtil:dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z;
end

function SPUtil:plane_intersect(ray_origin, ray_dir, plane_pt, plane_normal)
	local denom = SPUtil:dot(plane_normal,ray_dir)

	if math.abs(denom) > 0 then
		local ray_origin_to_plane_pt = plane_pt - ray_origin
		local t = SPUtil:dot(ray_origin_to_plane_pt, plane_normal) / denom

		if t >= 0 then
			return true, ray_origin + (ray_dir * t)
		else
			return false, Vector3.new()
		end
	end

	return false, Vector3.new()
end;

local function verify_sputil_screengui()
	if game.Players.LocalPlayer == nil then
		return false
	end
	if game.Players.LocalPlayer:FindFirstChild("PlayerGui") == nil then
		return false
	end
	local TESTGUI_NAME = "SPUtil_test"
	local sputil_screengui = nil
	if game.Players.LocalPlayer.PlayerGui:FindFirstChild(TESTGUI_NAME) == nil then
		sputil_screengui = Instance.new("ScreenGui",game.Players.LocalPlayer.PlayerGui)
		sputil_screengui.Name = TESTGUI_NAME
		sputil_screengui.ResetOnSpawn = false
	end
	return true
end

function SPUtil:screen_size()
	if verify_sputil_screengui() == false then
		return Vector2.new(0,0)
	end
	return game.Players.LocalPlayer.PlayerGui.SPUtil_test.AbsoluteSize + Vector2.new(0,36)
end

function SPUtil:comma_value(amount)
  local formatted = amount
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function SPUtil:format_ms_time(ms_time)
	ms_time = math.floor(ms_time)
	return string.format(
		"%d:%d%d",
		ms_time/60000,
		(ms_time/10000)%6,
		(ms_time/1000)%10
	)
end

function SPUtil:connect_once(sig,fn)
	local connection = nil
	connection = sig:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
end

local TOPBAR_SIZE = 36
function SPUtil:nxy_to_nontopbar_screen_pos(nx,ny)
	local screen_size = SPUtil:screen_size()
	local rtvx = screen_size.X * nx
	local rtvy = screen_size.Y * ny
	return rtvx,rtvy-TOPBAR_SIZE
end

function SPUtil:nontopbar_screen_pos_to_nxy(px,py)
	local screen_size = SPUtil:screen_size()
	return px / screen_size.X, (py + TOPBAR_SIZE) / screen_size.Y
end

function SPUtil:pos_to_nxy(pos)
	local spos,visible = game.Workspace.Camera:WorldToScreenPoint(pos)
	local rtvx,rtvy = SPUtil:nontopbar_screen_pos_to_nxy(spos.X,spos.Y)
	return Vector2.new(rtvx,rtvy)
end

local __r_set_alpha_type_map = {}
__r_set_alpha_type_map["TextLabel"] = function(itr, background_transparency, text_transparency, image_transparency)
	itr.TextTransparency = text_transparency
	if itr.TextStrokeColor3 ~= Color3.new() then
		itr.TextStrokeTransparency = text_transparency
	end
end
__r_set_alpha_type_map["TextBox"] = function(itr, background_transparency, text_transparency, image_transparency)
	itr.TextTransparency = text_transparency
	itr.TextStrokeTransparency = text_transparency
end
__r_set_alpha_type_map["ImageLabel"] = function(itr, background_transparency, text_transparency, image_transparency)
	itr.ImageTransparency = image_transparency
	if #itr.Image == 0 then
		itr.BackgroundTransparency = background_transparency
	end
end
__r_set_alpha_type_map["ScrollingFrame"] = function(itr, background_transparency, text_transparency, image_transparency)
	itr.BackgroundTransparency = background_transparency
end

local function _r_set_alpha_perform(itr,transparency)
	local name_str = itr.Name
	local background_transparency = transparency
	local text_transparency = transparency
	local image_transparency = transparency
	if string.sub(name_str,1,1) == "{" then
		--local name_str = "{BackgroundTransparency=0.5,TextTransparency=0.45,}Test"
		local str_data = string.sub(name_str,1,string.find(name_str,"}"))
		local i = 1
		while true do
			local i_p1 = i + 1
			local i_eq = string.find(str_data,"=",i_p1)
			local i_cm = string.find(str_data,",",i_p1)
			local i_rb = string.find(str_data,"}",i_p1)

			if i_eq == nil then break end
			if i_rb == nil then break end

			local key = string.sub(name_str,i_p1,i_eq-1)
			local value
			if i_cm ~= nil then
				value = string.sub(name_str,i_eq+1,i_cm-1)
				i = i_cm
			else
				value = string.sub(name_str,i_eq+1,i_rb-1)
				i = i_rb
			end

			if key == "BackgroundAlpha" then
				background_transparency = SPUtil:tra(tonumber(value) * SPUtil:tra(background_transparency))
			elseif key == "TextAlpha" then
				text_transparency = SPUtil:tra(tonumber(value) * SPUtil:tra(text_transparency))
			elseif key == "ImageAlpha" then
				image_transparency = SPUtil:tra(tonumber(value) * SPUtil:tra(image_transparency))
			end
		end
	end

	local handler = __r_set_alpha_type_map[itr.ClassName]
	if handler ~= nil then
		handler(itr, background_transparency, text_transparency, image_transparency)
		return true
	end
	return false
end

local function _r_set_alpha(itr,transparency,ignorelist,cachelist)
	if ignorelist ~= nil then
		for i=1,ignorelist:count() do
			if itr.Name == ignorelist:get(i) then
				return
			end
		end
	end

	local hit = _r_set_alpha_perform(itr,transparency)
	if cachelist ~= nil and hit == true then
		cachelist[#cachelist+1] = itr
	end

	for _,child in pairs(itr:GetChildren()) do
		_r_set_alpha(child,transparency,ignorelist,cachelist)
	end
end

function SPUtil:r_set_alpha_generate_name(params,base_name_or_obj)
	local name = "{"
	for k,v in pairs(params) do
		if k == "BackgroundAlpha" or k == "ImageAlpha" or k == "TextAlpha" then
			name = name .. k .. "=" .. tostring(v) .. ","
		else
			SPUtil:errf("r_set_alpha_generate_name unknown key(%s)",k)
		end
	end
	name = name .. "}"

	if typeof(base_name_or_obj) == "string" then
		name = name .. base_name_or_obj
	else
		local obj_name = base_name_or_obj.Name
		local i_rb = string.find(obj_name,"}")
		if i_rb == nil then
			name = name .. obj_name
		else
			name = name .. string.sub(obj_name,i_rb+1)
		end
	end

	return name
end

local __r_set_alpha_cache = {}
function SPUtil:r_set_alpha(root,alpha,ignorelist)
	SPUtil:profilebegin("r_set_alpha")

	local transparency = SPUtil:tra(alpha)
	local cachelist = __r_set_alpha_cache[root.Name]

	if cachelist ~= nil and cachelist.Root == root and (tick() - cachelist.Time) < 1.0 then
		cachelist = cachelist.CacheList
		for i=1,#cachelist do
			_r_set_alpha_perform(cachelist[i],transparency)
		end
	else
		cachelist = {}
		_r_set_alpha(root,transparency,ignorelist,cachelist)
		__r_set_alpha_cache[root.Name] = {Time=tick(),CacheList=cachelist,Root=root}
	end

	SPUtil:profileend()

	return root
end

function SPUtil:tra(val)
	return 1 - val
end

function SPUtil:profilebegin(label)
	debug.profilebegin(label)
end
function SPUtil:profileend()
	debug.profileend()
end

function SPUtil:cframe(pos,rotation)
	return CFrame.new(pos.X,pos.Y,pos.Z) *
		CFrame.Angles(rotation.X * math.pi / 180, rotation.Y * math.pi / 180, rotation.Z * math.pi / 180)
end

function SPUtil:flt_cmp_delta(a,b,delta)
	return math.abs(a-b) < delta
end

function SPUtil:set_size(part,x,y,z)
	local psize = part.Size
	if x < 0.2 then x = 0.2 end
	if y < 0.2 then y = 0.2 end
	if z < 0.2 then z = 0.2 end
	if SPUtil:flt_cmp_delta(x,psize.X,0.1) == true and
		SPUtil:flt_cmp_delta(y,psize.Y,0.1) == true and
		SPUtil:flt_cmp_delta(z,psize.Z,0.1) == true	then
		return
	end
	part.Size = Vector3.new(x,y,z)
end

function SPUtil:angles(x,y,z)
	return CFrame.Angles(SPUtil:deg_to_rad(x),SPUtil:deg_to_rad(y),SPUtil:deg_to_rad(z))
end

function SPUtil:angles_vec3(vec)
	return SPUtil:angles(vec.X,vec.Y,vec.Z)
end

function SPUtil:set_chat_visible(val)
	game.StarterGui:SetCore("ChatActive",val)
end

function SPUtil:color3(r,g,b)
	return Color3.new(r/255.0,g/255.0,b/255.0)
end

return SPUtil
