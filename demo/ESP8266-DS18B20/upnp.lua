net.multicastJoin("","239.255.255.250")

local ssdp_notify = "NOTIFY * HTTP/1.1\r\n"..
"HOST: 239.255.255.250:1900\r\n"..
"CACHE-CONTROL: max-age=1800\r\n"..
"NT: upnp:rootdevice\r\n"..
"USN: uuid:c5baf4a1-0c8e-44da-9714-ef345678"..string.format("%x",node.chipid()).."\r\n"..
"NTS: ssdp:alive\r\n"..
"SERVER: Nodemcu/1.0 UPNP/1.1 lewei50/1\r\n"..
"Location: http://"..wifi.sta.getip().."/info.xml\r\n\r\n"

local ssdp_response = "HTTP/1.1 200 OK\r\n"..
"EXT:\r\n"..
"ST: upnp:rootdevice\r\n"..
"Cache-Control: max-age=1200\r\n"..
"SERVER: Nodemcu/1.0 UPNP/1.1 lewei50/1\r\n"..
"USN: uuid:c5baf4a1-0c8e-44da-9714-ef345678"..string.format("%x",node.chipid()).."\r\n"..
"Location: http://"..wifi.sta.getip().."/info.xml\r\n\r\n"

local function response(connection, payLoad, port, ip)
    if string.match(payLoad,"M-SEARCH") and (string.match(payLoad,"rootdevice") or string.match(payLoad,"lewei50.com")) then
        connection:send(port,ip,ssdp_response)
        --print("response")
        --print("send:")
        --print(ssdp_response)
    end
end

tmr.alarm(3, 10000, 1, function()
    UPnPd:send(1900,'239.255.255.250',ssdp_notify)
    --print("notify")
end)

UPnPd = net.createUDPSocket()
UPnPd:on("receive", response )
UPnPd:listen(1900,"0.0.0.0")
