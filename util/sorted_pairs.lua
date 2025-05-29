function sorted_pairs (t, f)
    local a = {}
    for n in pairs(t) do
        -- create a list with all keys
        a[#a + 1] = n
    end
    table.sort(a, f)
    -- sort the list
    local i = 0
    -- iterator variable
    return function ()
        -- iterator function
        i = i + 1
        return a[i], t[a[i]]
        -- return key, value
    end
end
