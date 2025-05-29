require 'util.sorted_pairs'

function dump(table, depth, prevdump)
  if ( table == nil ) then return '' end
  if ( type(table) == 'string' ) then return table end
  if ( not depth ) then depth = 1 end
  if (depth > 200) then
    print("Error: Depth > 200 in dump()")
    return
  end
  thedump = prevdump or ""
  for k,v in sorted_pairs(table) do
    if (type(v) == "table") then
      thedump = thedump..string.rep("  ", depth)..k..":\n"
      dump(v, depth+1, thedump)
    else
      thedump = thedump..string.rep("  ", depth)..k..": "..tostring(v).."\n"
    end
  end
  return thedump
end
