package.cpath = [[C:\BCS_Work\QUIK_BCS\lua\rocks\?.dll;]]..package.cpath
local socket = require 'rocks.socket'
local json = require 'rocks.dkjson'
require 'util.log'
require 'util.dump'

local stopped = false
function OnStop() stopped = true end
function OnClose() stopped = true end
local verbose = false
function vlog(msg)
    if verbose then log(msg) end
end

function main()
    log('exocket.lua started')
    local server = assert(socket.bind("*", 7777))
    local ip, port = server:getsockname()
    log("Please telnet to localhost on port " .. port)
    while 1 do
        local client = server:accept()
        local line, err = client:receive('*a')
        if line == nil then
            log('Got empty line')
        elseif line:match('^exec ') then
            what = line:gsub('^exec ', '')
            if verbose then log("EXEC "..what) end
            local syntaxok, f = pcall(
                assert, -- assert is called in protected mode
                load("return "..what)
            )
            if not syntaxok then
                log("ERROR Syntax is not ok: "..f)
                goto NEXT
            end
            local ok, res = pcall( f )
            if not ok then
                log("ERROR Execution failed, not ok: "..res)
                goto NEXT
            end
            local jsonok, thejson = pcall( json.encode, res )
            if jsonok then
                client:send(thejson)
            else
                log("ERROR forming json: "..thejson)
            end
        elseif line:match('^ask ') then
            what = line:gsub('^ask ', '')
            if what == 'futpos' then
                client:send(json.encode(futpos()).."\n")
            elseif what == 'futlimits' then
                client:send(json.encode(futlimits()).."\n")
            elseif what == 'current_orders' then
                client:send(json.encode(get_current_orders()).."\n")
            else
                client:send("Don't know what is "..what.."\n")
            end
        else
            client:send(line.."\n")
        end
        ::NEXT::
        client:shutdown('both')
        client:close()
    end
end

function session_status()
    local some_fut_status = getParamEx('SPBFUT', 'USDRUBF', 'TRADINGSTATUS')
    return some_fut_status.param_value
end

function futlimits()
    return getItem('futures_client_limits', 0)
end

function get_current_orders()
    if verbose then log("Initializing existing orders...") end
    local cur_orders = {}
    for i = 0, getNumberOf('orders') - 1 do
        local order = getItem('orders', i)
        vlog(
            'Got order_num '..tostring(order.order_num)..
            ' sec_code '..order.sec_code..
            ' flags '..order.flags..
            ' ext_flags '..order.ext_order_flags..
            ' qty '..order.qty..
            ' remaining '..order.balance
        )

        set_order_flags(order)

        cur_orders[order.order_num] = order_map(order)
    end
    return cur_orders
end

function set_order_flags(order)
    order.is_active = false
    if bit.test(order.flags, 0) then -- Заявка активна, иначе – не активна
        order.is_active = true
    end
    order.is_sell = false
    if bit.test(order.flags, 2) then -- Заявка на продажу, иначе – на покупку
        order.is_sell = true
    end
    order.is_executed = false
    if order.balance == 0 then
        order.is_executed = true
    end
    return order
end

function order_map( order )
    order = set_order_flags(order)
    return {
        class_code = order.class_code,
        sec_code   = order.sec_code,
        trans_id   = order.trans_id,
        order_num  = order.order_num,
        price      = order.price,
        qty        = order.qty,
        qty2       = order.qty2,
        is_active  = order.is_active,
        is_sell    = order.is_sell,
        is_executed = order.is_executed,
        datetime   = order.datetime.year..'-'..
                     order.datetime.month..'-'..
                     order.datetime.day..' '..
                     order.datetime.hour..':'..
                     order.datetime.min..':'..
                     order.datetime.sec..'.'..
                     order.datetime.mcs,
        withdraw_datetime = order.withdraw_datetime.year..'-'..
                            order.withdraw_datetime.month..'-'..
                            order.withdraw_datetime.day..' '..
                            order.withdraw_datetime.hour..':'..
                            order.withdraw_datetime.min..':'..
                            order.withdraw_datetime.sec..'.'..
                            order.withdraw_datetime.mcs,
    }
end
