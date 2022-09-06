local SSort = {}

do
  local incs = { 1391376,
                 463792, 198768, 86961, 33936,
                 13776, 4592, 1968, 861, 336, 
                 112, 48, 21, 7, 3, 1 }

  local function ssup(t, n)
    for _, h in ipairs(incs) do
      for i = h + 1, n do
        local v = t[i]
        for j = i - h, 1, -h do
          local testval = t[j]
          if not (v < testval) then break end
          t[i] = testval; i = j
        end
        t[i] = v
      end 
    end
    return t
  end

  local function ssdown(t, n)
    for _, h in ipairs(incs) do
      for i = h + 1, n do
        local v = t[i]
        for j = i - h, 1, -h do
          local testval = t[j]
          if not (v > testval) then break end
          t[i] = testval; i = j
        end
        t[i] = v
      end 
    end
    return t
  end

  local function ssgeneral(t, n, before)
    for _, h in ipairs(incs) do
      for i = h + 1, n do
        local v = t[i]
        for j = i - h, 1, -h do
          local testval = t[j]
          if not before(v, testval) then break end
          t[i] = testval; i = j
        end
        t[i] = v
      end 
    end
    return t
  end

  function SSort:sort(t, before, n)
    n = n or #t
    if not before or before == "<" then return ssup(t, n)
    elseif before == ">" then return ssdown(t, n)
    else return ssgeneral(t, n, before)
    end
  end
end


return SSort
