local logto = "Z:/var/log/quik.log"

function log(msg)
    if ( not msg ) then msg = '' end

    file = io.open(logto, "ab")
    file:write( string.format( "[%s] %s\n", os.date("%Y-%m-%dT%H:%M:%S", os.time()), msg ) )
    file:close()
end
